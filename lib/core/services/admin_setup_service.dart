import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to set up the initial super admin for the app
/// This should only be used once during initial app setup
class AdminSetupService {
  final FirebaseFirestore _firestore;

  AdminSetupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Set a user as super admin by their email
  /// Returns true if successful
  Future<bool> setUserAsSuperAdmin(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        debugPrint('User with email $email not found');
        return false;
      }

      final userId = query.docs.first.id;
      await _firestore.collection('users').doc(userId).update({
        'role': 'superadmin',
        'status': 'active',
        'updatedAt': Timestamp.now(),
      });

      debugPrint('Successfully set $email as super admin');
      return true;
    } catch (e) {
      debugPrint('Error setting super admin: $e');
      return false;
    }
  }

  /// Set a user as super admin by their user ID
  Future<bool> setUserAsSuperAdminById(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'superadmin',
        'status': 'active',
        'updatedAt': Timestamp.now(),
      });

      debugPrint('Successfully set user $userId as super admin');
      return true;
    } catch (e) {
      debugPrint('Error setting super admin: $e');
      return false;
    }
  }

  /// Check if any super admin exists in the app
  Future<bool> hasSuperAdmin() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'superadmin')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking for super admin: $e');
      return false;
    }
  }

  /// Get list of all super admins
  Future<List<Map<String, dynamic>>> getSuperAdmins() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'superadmin')
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting super admins: $e');
      return [];
    }
  }
}
