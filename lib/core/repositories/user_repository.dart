import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for user-related Firestore operations
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final collection = uid == userId
          ? _usersCollection
          : await _readCollection();
      final doc = await collection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Get user stream by ID
  Stream<UserModel?> getUserStream(String userId) async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final collection = uid == userId
        ? _usersCollection
        : await _readCollection();
    yield* collection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Create new user
  Future<bool> createUser(UserModel user) async {
    debugPrint('UserRepository.createUser: Starting for user id=${user.id}');
    try {
      final data = user.toFirestore();
      debugPrint('UserRepository.createUser: Writing to Firestore...');

      // Add timeout to prevent hanging
      await _usersCollection
          .doc(user.id)
          .set(data)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('UserRepository.createUser: TIMEOUT after 15 seconds');
              throw Exception('Firestore write timeout');
            },
          );

      debugPrint(
        'UserRepository.createUser: SUCCESS - User saved to Firestore',
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('UserRepository.createUser: ERROR - $e');
      debugPrint('UserRepository.createUser: Error type: ${e.runtimeType}');
      debugPrint('UserRepository.createUser: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update user
  Future<bool> updateUser(UserModel user) async {
    try {
      await _usersCollection
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Update specific user fields
  Future<bool> updateUserFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      fields['updatedAt'] = Timestamp.now();
      await _usersCollection.doc(userId).update(fields);
      return true;
    } catch (e) {
      debugPrint('Error updating user fields: $e');
      return false;
    }
  }

  /// Update FCM token
  Future<bool> updateFcmToken(String userId, String token) async {
    return updateUserFields(userId, {'fcmToken': token});
  }

  /// Update last login
  Future<bool> updateLastLogin(String userId) async {
    return updateUserFields(userId, {'lastLoginAt': Timestamp.now()});
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user exists: $e');
      return false;
    }
  }

  /// Check if email is already registered
  /// NEFOLOSIT in aplicatie. Interogarea nu e limitata la judet, deci ar fi
  /// respinsa de regula de citire pentru orice rol in afara de superadmin.
  Future<bool> isEmailRegistered(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  /// Get user by email
  /// Nota: limitat la judet, ca interogarea sa treaca de regula de citire.
  /// Pentru bex asta inseamna ca un email existent in ALT judet nu e detectat.
  Future<UserModel?> getUserByEmail(String email, {String? countyId}) async {
    try {
      final query = await (await _scopedToCounty(
        countyId,
      )).where('email', isEqualTo: email.toLowerCase()).limit(1).get();
      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  /// Create new user with auto-generated ID (returns the new user ID)
  Future<String?> createUserWithAutoId(UserModel user) async {
    try {
      final docRef = await _usersCollection.add(user.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating user with auto ID: $e');
      return null;
    }
  }

  /// Scope a users query to one county.
  ///
  /// The `users` read rule only allows admins to read profiles from their own
  /// county, and Firestore rejects a query it cannot prove is county-scoped.
  /// Every collection-wide read below must therefore carry this filter.
  /// `countyId` is null only for a Superadmin viewing "all counties" -- the
  /// rules let Superadmin read across counties, so an unfiltered query is
  /// allowed there and only there.
  Future<CollectionReference<Map<String, dynamic>>> _readCollection() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required');
    final me = (await _usersCollection.doc(uid).get()).data();
    final role = me?['role'];
    return role == 'bex' || role == 'superadmin'
        ? _usersCollection
        : _firestore.collection('user_directory');
  }

  Future<Query<Map<String, dynamic>>> _scopedToCounty(String? countyId) async {
    final collection = await _readCollection();
    if (countyId == null || countyId.isEmpty) return collection;
    return collection.where('city', isEqualTo: countyId);
  }

  /// Get users by school (all users, not just active)
  Future<List<UserModel>> getUsersBySchool(
    String schoolId, {
    String? countyId,
  }) async {
    try {
      // Get users in scope and filter in memory to avoid composite index requirement
      final snapshot = await (await _scopedToCounty(countyId)).get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.schoolId == schoolId)
          .toList();
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    } catch (e) {
      debugPrint('Error getting users by school: $e');
      return [];
    }
  }

  /// Get users by school as real-time stream
  Stream<List<UserModel>> getUsersBySchoolStream(
    String schoolId, {
    String? countyId,
  }) async* {
    yield* (await _scopedToCounty(
      countyId,
    )).where('schoolId', isEqualTo: schoolId).snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    });
  }

  /// Get school representative for a specific school
  /// Returns the user with role=schoolRep who belongs to this school
  Future<UserModel?> getSchoolRepresentative(
    String schoolId, {
    String? countyId,
  }) async {
    try {
      final snapshot = await (await _scopedToCounty(countyId))
          .where('schoolId', isEqualTo: schoolId)
          .where('role', isEqualTo: UserRole.schoolRep.toFirestore())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting school representative: $e');
      return null;
    }
  }

  /// Get school representative stream for a specific school
  Stream<UserModel?> getSchoolRepresentativeStream(
    String schoolId, {
    String? countyId,
  }) async* {
    yield* (await _scopedToCounty(countyId))
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: UserRole.schoolRep.toFirestore())
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return UserModel.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(
    UserRole role, {
    String? countyId,
  }) async {
    try {
      // Get users in scope and filter in memory to avoid composite index requirement
      final snapshot = await (await _scopedToCounty(countyId)).get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where(
            (user) => user.role == role && user.status == UserStatus.active,
          )
          .toList();
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    } catch (e) {
      debugPrint('Error getting users by role: $e');
      return [];
    }
  }

  /// Get all users (for admin)
  Future<List<UserModel>> getAllUsers({String? countyId}) async {
    try {
      final snapshot = await (await _scopedToCounty(countyId)).get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      // Sort locally by fullName
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  /// Get total user count in the caller's effective county.
  ///
  /// A null county is reserved for superadmin's national view. Other admin
  /// roles must include the county constraint so Firestore can prove that the
  /// aggregate query cannot read profiles from another county.
  Future<int> getUserCount({String? countyId}) async {
    try {
      final countQuery = await (await _scopedToCounty(countyId)).count().get();
      return countQuery.count ?? 0;
    } catch (e) {
      debugPrint('Error getting user count: $e');
      return 0;
    }
  }

  /// Get pending users (for admin approval)
  /// - SchoolRep: sees only pending users from their school
  /// - BEX: sees only pending users from their county
  /// - Superadmin: sees all pending users
  Future<List<UserModel>> getPendingUsers({
    String? schoolId,
    String? countyId,
  }) async {
    try {
      // Get users in scope and filter in memory to avoid composite index requirement
      final snapshot = await (await _scopedToCounty(countyId)).get();
      var users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.status == UserStatus.pending)
          .toList();

      // Filter by county first (for BEX users)
      if (countyId != null && countyId.isNotEmpty) {
        users = users.where((user) => user.city == countyId).toList();
      }

      // Then filter by school (for SchoolRep users)
      if (schoolId != null) {
        users = users.where((user) => user.schoolId == schoolId).toList();
      }

      // Sort by createdAt descending
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    } catch (e) {
      debugPrint('Error getting pending users: $e');
      return [];
    }
  }

  /// Approve user
  Future<bool> approveUser(
    String userId, {
    String? parentalAuthorizationVerifiedBy,
  }) async {
    final fields = <String, dynamic>{'status': 'active'};
    if (parentalAuthorizationVerifiedBy != null) {
      fields['parentalAuthorizationVerifiedAt'] = Timestamp.now();
      fields['parentalAuthorizationVerifiedBy'] =
          parentalAuthorizationVerifiedBy;
    }
    return updateUserFields(userId, fields);
  }

  /// Suspend user
  Future<bool> suspendUser(String userId) async {
    return updateUserFields(userId, {'status': 'suspended'});
  }

  /// Change user role (with optional department for department role)
  Future<bool> changeUserRole(
    String userId,
    UserRole newRole, {
    DepartmentType? department,
  }) async {
    try {
      debugPrint(
        'changeUserRole: userId=$userId, newRole=${newRole.toFirestore()}, department=$department',
      );

      final Map<String, dynamic> fields = {'role': newRole.toFirestore()};

      // If changing to department role, also set the department type
      if (newRole == UserRole.department && department != null) {
        fields['department'] = department.toFirestore();
      } else if (newRole != UserRole.department) {
        // Clear department if changing away from department role
        fields['department'] = null;
      }

      final result = await updateUserFields(userId, fields);
      debugPrint('changeUserRole: result=$result');
      return result;
    } catch (e) {
      debugPrint('changeUserRole: error=$e');
      return false;
    }
  }

  /// Search users by name (optionally filtered by county)
  Future<List<UserModel>> searchUsers(String query, {String? countyId}) async {
    try {
      // Get all users and search in memory to avoid composite index requirement
      final queryLower = query.toLowerCase();
      final snapshot = await (await _scopedToCounty(countyId)).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Timeout searching users');
          throw Exception('Request timed out');
        },
      );
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.status == UserStatus.active)
          .where((user) {
            // Filter by county if specified
            if (countyId != null && countyId.isNotEmpty) {
              if (user.city != countyId) return false;
            }
            return user.fullName.toLowerCase().contains(queryLower) ||
                user.email.toLowerCase().contains(queryLower);
          })
          .take(20)
          .toList();
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get active users from a specific county (for adding meeting participants)
  Future<List<UserModel>> getUsersByCounty(
    String countyId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await (await _scopedToCounty(countyId)).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Timeout getting users by county');
          throw Exception('Request timed out');
        },
      );
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.status == UserStatus.active)
          .where((user) => user.city == countyId)
          .take(limit)
          .toList();
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    } catch (e) {
      debugPrint('Error getting users by county: $e');
      return [];
    }
  }

  /// Get users by a list of IDs
  /// Citeste utilizatorii unul cate unul, nu prin `whereIn`.
  ///
  /// Regula de citire pe users limiteaza adminii la propriul judet. O interogare
  /// `whereIn` pe documentId nu poate fi dovedita ca limitata la judet, deci ar fi
  /// respinsa in bloc. Un `get` pe document e evaluat individual: documentele din
  /// afara judetului sunt sarite in liniste, restul se citesc normal.
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final List<UserModel> users = [];
    for (final userId in userIds) {
      try {
        final doc = await (await _readCollection())
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists) {
          users.add(UserModel.fromFirestore(doc));
        }
      } catch (e) {
        debugPrint('Skipping user $userId: $e');
      }
    }
    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return users;
  }

  /// Get all school representatives
  Future<List<UserModel>> getSchoolReps() async {
    return getUsersByRole(UserRole.schoolRep);
  }

  /// Get all BEX members
  Future<List<UserModel>> getBexMembers({String? countyId}) async {
    return getUsersByRole(UserRole.bex, countyId: countyId);
  }

  /// Get department members
  Future<List<UserModel>> getDepartmentMembers(
    DepartmentType department, {
    String? countyId,
  }) async {
    try {
      // Get users in scope and filter in memory to avoid composite index requirement
      final snapshot = await (await _scopedToCounty(countyId)).get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where(
            (user) =>
                user.role == UserRole.department &&
                user.department == department &&
                user.status == UserStatus.active,
          )
          .toList();
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    } catch (e) {
      debugPrint('Error getting department members: $e');
      return [];
    }
  }

  // ==================== WARNING MANAGEMENT ====================

  /// Add a warning to a user
  Future<bool> addWarning(String userId, UserWarning warning) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedWarnings = [...user.warnings, warning];
      await _usersCollection.doc(userId).update({
        'warnings': updatedWarnings.map((w) => w.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding warning: $e');
      return false;
    }
  }

  /// Remove a warning from a user
  Future<bool> removeWarning(String userId, String warningId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedWarnings = user.warnings
          .where((w) => w.id != warningId)
          .toList();
      await _usersCollection.doc(userId).update({
        'warnings': updatedWarnings.map((w) => w.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing warning: $e');
      return false;
    }
  }

  /// Resolve a warning (mark as resolved instead of deleting)
  Future<bool> resolveWarning(
    String userId,
    String warningId,
    String resolvedByName,
    String? resolutionNote,
  ) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedWarnings = user.warnings.map((w) {
        if (w.id == warningId) {
          return w.copyWith(
            resolvedAt: DateTime.now(),
            resolvedByName: resolvedByName,
            resolutionNote: resolutionNote,
          );
        }
        return w;
      }).toList();

      await _usersCollection.doc(userId).update({
        'warnings': updatedWarnings.map((w) => w.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error resolving warning: $e');
      return false;
    }
  }

  // ==================== ABSENCE MANAGEMENT ====================

  /// Add an absence to a user
  Future<bool> addAbsence(String userId, UserAbsence absence) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedAbsences = [...user.absences, absence];
      await _usersCollection.doc(userId).update({
        'absences': updatedAbsences.map((a) => a.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding absence: $e');
      return false;
    }
  }

  /// Remove an absence from a user
  Future<bool> removeAbsence(String userId, String absenceId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedAbsences = user.absences
          .where((a) => a.id != absenceId)
          .toList();
      await _usersCollection.doc(userId).update({
        'absences': updatedAbsences.map((a) => a.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing absence: $e');
      return false;
    }
  }

  /// Mark an absence as excused
  Future<bool> excuseAbsence(
    String userId,
    String absenceId,
    String reason,
  ) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedAbsences = user.absences.map((a) {
        if (a.id == absenceId) {
          return a.copyWith(isExcused: true, reason: reason);
        }
        return a;
      }).toList();

      await _usersCollection.doc(userId).update({
        'absences': updatedAbsences.map((a) => a.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error excusing absence: $e');
      return false;
    }
  }

  /// Get users with active warnings
  Future<List<UserModel>> getUsersWithActiveWarnings() async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((u) => u.hasActiveWarnings).toList();
    } catch (e) {
      debugPrint('Error getting users with warnings: $e');
      return [];
    }
  }

  /// Get users with unexcused absences
  Future<List<UserModel>> getUsersWithUnexcusedAbsences() async {
    try {
      final allUsers = await getAllUsers();
      return allUsers
          .where((u) => u.absences.any((a) => !a.isExcused))
          .toList();
    } catch (e) {
      debugPrint('Error getting users with unexcused absences: $e');
      return [];
    }
  }
}
