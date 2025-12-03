import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
      final doc = await _usersCollection.doc(userId).get();
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
  Stream<UserModel?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Create new user
  Future<bool> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  /// Update user
  Future<bool> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(
        user.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Update specific user fields
  Future<bool> updateUserFields(String userId, Map<String, dynamic> fields) async {
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
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
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

  /// Get users by school
  Future<List<UserModel>> getUsersBySchool(String schoolId) async {
    try {
      final query = await _usersCollection
          .where('schoolId', isEqualTo: schoolId)
          .where('status', isEqualTo: 'active')
          .orderBy('fullName')
          .get();
      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting users by school: $e');
      return [];
    }
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final query = await _usersCollection
          .where('role', isEqualTo: role.toFirestore())
          .where('status', isEqualTo: 'active')
          .orderBy('fullName')
          .get();
      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting users by role: $e');
      return [];
    }
  }

  /// Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      final users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      // Sort locally by fullName
      users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  /// Get pending users (for admin approval)
  Future<List<UserModel>> getPendingUsers({String? schoolId}) async {
    try {
      Query<Map<String, dynamic>> query = _usersCollection
          .where('status', isEqualTo: 'pending');

      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }

      final result = await query.orderBy('createdAt', descending: true).get();
      return result.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting pending users: $e');
      return [];
    }
  }

  /// Approve user
  Future<bool> approveUser(String userId) async {
    return updateUserFields(userId, {'status': 'active'});
  }

  /// Suspend user
  Future<bool> suspendUser(String userId) async {
    return updateUserFields(userId, {'status': 'suspended'});
  }

  /// Change user role
  Future<bool> changeUserRole(String userId, UserRole newRole) async {
    return updateUserFields(userId, {'role': newRole.toFirestore()});
  }

  /// Search users by name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Firestore doesn't support full-text search, so we do a prefix search
      final queryLower = query.toLowerCase();
      final snapshot = await _usersCollection
          .where('status', isEqualTo: 'active')
          .orderBy('fullName')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(20)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get all school representatives
  Future<List<UserModel>> getSchoolReps() async {
    return getUsersByRole(UserRole.schoolRep);
  }

  /// Get all BEX members
  Future<List<UserModel>> getBexMembers() async {
    return getUsersByRole(UserRole.bex);
  }

  /// Get department members
  Future<List<UserModel>> getDepartmentMembers(DepartmentType department) async {
    try {
      final query = await _usersCollection
          .where('role', isEqualTo: UserRole.department.toFirestore())
          .where('department', isEqualTo: department.toFirestore())
          .where('status', isEqualTo: 'active')
          .orderBy('fullName')
          .get();
      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
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

      final updatedWarnings = user.warnings.where((w) => w.id != warningId).toList();
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

      final updatedAbsences = user.absences.where((a) => a.id != absenceId).toList();
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
  Future<bool> excuseAbsence(String userId, String absenceId, String reason) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedAbsences = user.absences.map((a) {
        if (a.id == absenceId) {
          return a.copyWith(
            isExcused: true,
            reason: reason,
          );
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
      return allUsers.where((u) => u.absences.any((a) => !a.isExcused)).toList();
    } catch (e) {
      debugPrint('Error getting users with unexcused absences: $e');
      return [];
    }
  }
}
