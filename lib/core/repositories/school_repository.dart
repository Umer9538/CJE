import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';

/// Repository for school-related Firestore operations
class SchoolRepository {
  final FirebaseFirestore _firestore;

  SchoolRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _schoolsCollection =>
      _firestore.collection('schools');

  /// Get all active schools
  Future<List<SchoolModel>> getActiveSchools() async {
    try {
      final query = await _schoolsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      return query.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting schools: $e');
      return [];
    }
  }

  /// Get all schools (including inactive)
  Future<List<SchoolModel>> getAllSchools() async {
    try {
      final query = await _schoolsCollection.orderBy('name').get();
      return query.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all schools: $e');
      return [];
    }
  }

  /// Get school by ID
  Future<SchoolModel?> getSchoolById(String schoolId) async {
    try {
      final doc = await _schoolsCollection.doc(schoolId).get();
      if (doc.exists) {
        return SchoolModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting school: $e');
      return null;
    }
  }

  /// Get school stream by ID
  Stream<SchoolModel?> getSchoolStream(String schoolId) {
    return _schoolsCollection.doc(schoolId).snapshots().map((doc) {
      if (doc.exists) {
        return SchoolModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Create new school
  Future<String?> createSchool(SchoolModel school) async {
    try {
      final docRef = await _schoolsCollection.add(school.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating school: $e');
      return null;
    }
  }

  /// Update school
  Future<bool> updateSchool(SchoolModel school) async {
    try {
      await _schoolsCollection.doc(school.id).update(
        school.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating school: $e');
      return false;
    }
  }

  /// Update school representative
  Future<bool> updateSchoolRep(String schoolId, String? repId, String? repName) async {
    try {
      await _schoolsCollection.doc(schoolId).update({
        'schoolRepId': repId,
        'schoolRepName': repName,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating school rep: $e');
      return false;
    }
  }

  /// Increment student count
  Future<bool> incrementStudentCount(String schoolId) async {
    try {
      await _schoolsCollection.doc(schoolId).update({
        'studentCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error incrementing student count: $e');
      return false;
    }
  }

  /// Decrement student count
  Future<bool> decrementStudentCount(String schoolId) async {
    try {
      await _schoolsCollection.doc(schoolId).update({
        'studentCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error decrementing student count: $e');
      return false;
    }
  }

  /// Toggle school active status
  Future<bool> toggleSchoolActive(String schoolId, bool isActive) async {
    try {
      await _schoolsCollection.doc(schoolId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling school status: $e');
      return false;
    }
  }

  /// Delete school
  Future<bool> deleteSchool(String schoolId) async {
    try {
      await _schoolsCollection.doc(schoolId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting school: $e');
      return false;
    }
  }

  /// Search schools by name
  Future<List<SchoolModel>> searchSchools(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _schoolsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(20)
          .get();
      return snapshot.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error searching schools: $e');
      return [];
    }
  }

  /// Get schools by city
  Future<List<SchoolModel>> getSchoolsByCity(String city) async {
    try {
      final query = await _schoolsCollection
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      return query.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting schools by city: $e');
      return [];
    }
  }
}
