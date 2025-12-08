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
      return snapshot.docs.map((doc) => WarningModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting warnings: $e');
      return [];
    }
  }

  /// Get warnings for a specific user
  Future<List<WarningModel>> getUserWarnings(String userId) async {
    try {
      final snapshot = await _warningsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('issuedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => WarningModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user warnings: $e');
      return [];
    }
  }

  /// Create a new warning
  Future<String?> createWarning(WarningModel warning) async {
    try {
      final docRef = await _warningsCollection.add(warning.toFirestore());
      return docRef.id;
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

  /// Get warning count for user
  Future<int> getWarningCount(String userId, {bool activeOnly = true}) async {
    try {
      Query<Map<String, dynamic>> query = _warningsCollection
          .where('userId', isEqualTo: userId);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
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
      return snapshot.docs.map((doc) => AbsenceModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting absences: $e');
      return [];
    }
  }

  /// Get absences for a specific user
  Future<List<AbsenceModel>> getUserAbsences(String userId) async {
    try {
      final snapshot = await _absencesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => AbsenceModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user absences: $e');
      return [];
    }
  }

  /// Get absences for a meeting
  Future<List<AbsenceModel>> getMeetingAbsences(String meetingId) async {
    try {
      final snapshot = await _absencesCollection
          .where('meetingId', isEqualTo: meetingId)
          .get();

      return snapshot.docs.map((doc) => AbsenceModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting meeting absences: $e');
      return [];
    }
  }

  /// Create a new absence record
  Future<String?> createAbsence(AbsenceModel absence) async {
    try {
      final docRef = await _absencesCollection.add(absence.toFirestore());
      return docRef.id;
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

  /// Get absence count for user
  Future<Map<String, int>> getAbsenceCount(String userId) async {
    try {
      final snapshot = await _absencesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final absences = snapshot.docs.map((doc) => AbsenceModel.fromFirestore(doc)).toList();

      return {
        'total': absences.length,
        'excused': absences.where((a) => a.type == AbsenceType.excused).length,
        'unexcused': absences.where((a) => a.type == AbsenceType.unexcused).length,
      };
    } catch (e) {
      debugPrint('Error getting absence count: $e');
      return {'total': 0, 'excused': 0, 'unexcused': 0};
    }
  }
}
