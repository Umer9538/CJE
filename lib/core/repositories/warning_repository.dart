import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/warning_model.dart';

/// Repository for managing warnings and absences
class WarningRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _warningsCollection =>
      _firestore.collection('warnings');

  CollectionReference<Map<String, dynamic>> get _absencesCollection =>
      _firestore.collection('absences');

  // ==================== WARNINGS ====================

  /// Get all warnings for a county
  Future<List<WarningModel>> getWarnings({
    String? countyId,
    String? userId,
    bool? isActive,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _warningsCollection;

      if (countyId != null) {
        query = query.where('countyId', isEqualTo: countyId);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      query = query.orderBy('issuedAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WarningModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting warnings: $e');
      return [];
    }
  }

  /// Get warnings for a specific user
  Future<List<WarningModel>> getUserWarnings(String userId) async {
    try {
      // Note: Firestore requires composite index for where + orderBy on different fields
      // So we fetch without orderBy and sort in memory
      final snapshot = await _warningsCollection
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout getting user warnings');
              throw Exception('Request timed out');
            },
          );

      final warnings = snapshot.docs
          .map((doc) => WarningModel.fromFirestore(doc))
          .toList();
      // Sort by issuedAt descending (most recent first)
      warnings.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      return warnings;
    } catch (e) {
      debugPrint('Error getting user warnings: $e');
      return [];
    }
  }

  /// Create a new warning
  /// If warning.id is provided (non-empty), use it as the document ID
  Future<String?> createWarning(WarningModel warning) async {
    try {
      if (warning.id.isNotEmpty) {
        // Use specific document ID for syncing with user's embedded warning
        await _warningsCollection.doc(warning.id).set(warning.toFirestore());
        return warning.id;
      } else {
        final docRef = await _warningsCollection.add(warning.toFirestore());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error creating warning: $e');
      return null;
    }
  }

  /// Update warning (e.g., deactivate)
  Future<bool> updateWarning(String id, Map<String, dynamic> data) async {
    try {
      await _warningsCollection.doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating warning: $e');
      return false;
    }
  }

  /// Delete warning
  Future<bool> deleteWarning(String id) async {
    try {
      await _warningsCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting warning: $e');
      return false;
    }
  }

  /// Deactivate warning
  Future<bool> deactivateWarning(String id) async {
    return updateWarning(id, {'isActive': false});
  }

  /// Stream of user warnings (real-time updates)
  Stream<List<WarningModel>> getUserWarningsStream(String userId) {
    debugPrint('getUserWarningsStream: Starting stream for userId=$userId');
    return _warningsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'getUserWarningsStream: Got ${snapshot.docs.length} warnings',
          );
          final warnings = snapshot.docs
              .map((doc) => WarningModel.fromFirestore(doc))
              .toList();
          warnings.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
          return warnings;
        })
        .handleError((error, stackTrace) {
          debugPrint('getUserWarningsStream ERROR: $error');
          // Return empty list on error instead of propagating
          return <WarningModel>[];
        });
  }

  /// Stream of warning count (real-time updates)
  Stream<int> getWarningCountStream(String userId, {bool activeOnly = true}) {
    debugPrint('getWarningCountStream: Starting stream for userId=$userId');
    return _warningsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          debugPrint('getWarningCountStream: Got ${snapshot.docs.length} docs');
          if (activeOnly) {
            final warnings = snapshot.docs
                .map((doc) => WarningModel.fromFirestore(doc))
                .toList();
            return warnings.where((w) => w.isActive).length;
          }
          return snapshot.docs.length;
        })
        .handleError((error, stackTrace) {
          debugPrint('getWarningCountStream ERROR: $error');
          // Return 0 on error instead of propagating to avoid UI error state
          return 0;
        });
  }

  /// Get warning count for user
  Future<int> getWarningCount(String userId, {bool activeOnly = true}) async {
    try {
      // Fetch all user warnings and count in memory to avoid composite index issues
      final snapshot = await _warningsCollection
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout getting warning count');
              throw Exception('Request timed out');
            },
          );

      if (activeOnly) {
        final warnings = snapshot.docs
            .map((doc) => WarningModel.fromFirestore(doc))
            .toList();
        return warnings.where((w) => w.isActive).length;
      }

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting warning count: $e');
      return 0;
    }
  }

  // ==================== ABSENCES ====================

  /// Get all absences
  Future<List<AbsenceModel>> getAbsences({
    String? countyId,
    String? userId,
    String? meetingId,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _absencesCollection;

      if (countyId != null) {
        query = query.where('countyId', isEqualTo: countyId);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (meetingId != null) {
        query = query.where('meetingId', isEqualTo: meetingId);
      }

      query = query.orderBy('recordedAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AbsenceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting absences: $e');
      return [];
    }
  }

  /// Get absences for a specific user
  Future<List<AbsenceModel>> getUserAbsences(String userId) async {
    try {
      // Note: Firestore requires composite index for where + orderBy on different fields
      // So we fetch without orderBy and sort in memory
      final snapshot = await _absencesCollection
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout getting user absences');
              throw Exception('Request timed out');
            },
          );

      final absences = snapshot.docs
          .map((doc) => AbsenceModel.fromFirestore(doc))
          .toList();
      // Sort by recordedAt descending (most recent first)
      absences.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return absences;
    } catch (e) {
      debugPrint('Error getting user absences: $e');
      return [];
    }
  }

  /// Get absences for a meeting
  Future<List<AbsenceModel>> getMeetingAbsences(
    String meetingId, {
    String? countyId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _absencesCollection.where(
        'meetingId',
        isEqualTo: meetingId,
      );
      if (countyId != null && countyId.isNotEmpty) {
        query = query.where('countyId', isEqualTo: countyId);
      }
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => AbsenceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting meeting absences: $e');
      return [];
    }
  }

  /// Create a new absence record
  /// If absence.id is provided (non-empty), use it as the document ID
  Future<String?> createAbsence(AbsenceModel absence) async {
    try {
      if (absence.id.isNotEmpty) {
        // Use specific document ID for syncing with user's embedded absence
        await _absencesCollection.doc(absence.id).set(absence.toFirestore());
        return absence.id;
      } else {
        final docRef = await _absencesCollection.add(absence.toFirestore());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error creating absence: $e');
      return null;
    }
  }

  /// Update absence (e.g., change type from unexcused to excused)
  Future<bool> updateAbsence(String id, Map<String, dynamic> data) async {
    try {
      await _absencesCollection.doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating absence: $e');
      return false;
    }
  }

  /// Delete absence
  Future<bool> deleteAbsence(String id) async {
    try {
      await _absencesCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting absence: $e');
      return false;
    }
  }

  /// Stream of user absences (real-time updates)
  Stream<List<AbsenceModel>> getUserAbsencesStream(String userId) {
    debugPrint('getUserAbsencesStream: Starting stream for userId=$userId');
    return _absencesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'getUserAbsencesStream: Got ${snapshot.docs.length} absences',
          );
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromFirestore(doc))
              .toList();
          absences.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
          return absences;
        })
        .handleError((error, stackTrace) {
          debugPrint('getUserAbsencesStream ERROR: $error');
          // Return empty list on error instead of propagating
          return <AbsenceModel>[];
        });
  }

  /// Stream of absence count (real-time updates)
  Stream<Map<String, int>> getAbsenceCountStream(String userId) {
    debugPrint('getAbsenceCountStream: Starting stream for userId=$userId');
    return _absencesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          debugPrint('getAbsenceCountStream: Got ${snapshot.docs.length} docs');
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromFirestore(doc))
              .toList();
          return {
            'total': absences.length,
            'excused': absences
                .where((a) => a.type == AbsenceType.excused)
                .length,
            'unexcused': absences
                .where((a) => a.type == AbsenceType.unexcused)
                .length,
          };
        })
        .handleError((error, stackTrace) {
          debugPrint('getAbsenceCountStream ERROR: $error');
          // Return empty counts on error instead of propagating to avoid UI error state
          return {'total': 0, 'excused': 0, 'unexcused': 0};
        });
  }

  /// Get absence count for user
  Future<Map<String, int>> getAbsenceCount(String userId) async {
    try {
      final snapshot = await _absencesCollection
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout getting absence count');
              throw Exception('Request timed out');
            },
          );

      final absences = snapshot.docs
          .map((doc) => AbsenceModel.fromFirestore(doc))
          .toList();

      return {
        'total': absences.length,
        'excused': absences.where((a) => a.type == AbsenceType.excused).length,
        'unexcused': absences
            .where((a) => a.type == AbsenceType.unexcused)
            .length,
      };
    } catch (e) {
      debugPrint('Error getting absence count: $e');
      return {'total': 0, 'excused': 0, 'unexcused': 0};
    }
  }
}
