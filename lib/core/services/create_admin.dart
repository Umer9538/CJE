import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script to create a default admin user
/// Run this once to set up the initial admin account
class CreateAdminScript {
  static const String adminEmail = 'superadmin@cje.ro';
  static const String adminPassword = 'SuperAdmin@2024';
  static const String adminName = 'Super Admin';
  static const String _prefKey = 'admin_created_v1';

  static Future<bool> createDefaultAdmin() async {
    try {
      // Check if admin was already created using SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefKey) == true) {
        debugPrint('ℹ️ Admin already created (cached), skipping');
        return true;
      }

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // If a user is already signed in, don't run the script
      if (auth.currentUser != null) {
        debugPrint('ℹ️ User already signed in, skipping admin creation');
        await prefs.setBool(_prefKey, true);
        return true;
      }

      debugPrint('🔄 Checking if admin user exists...');

      // Try to create auth user - this will fail if already exists
      try {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        debugPrint('✅ Auth user created');

        final userId = userCredential.user!.uid;
        debugPrint('🔄 Creating Firestore document for user: $userId');

        // Create user document in Firestore
        await firestore.collection('users').doc(userId).set({
          'email': adminEmail,
          'fullName': adminName,
          'firstName': 'Super',
          'lastName': 'Admin',
          'role': 'superadmin',
          'status': 'active',
          'emailVerified': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Sign out after creating (so user can log in fresh)
        await auth.signOut();

        // Mark as created
        await prefs.setBool(_prefKey, true);

        debugPrint('═══════════════════════════════════════');
        debugPrint('✅ ADMIN USER CREATED SUCCESSFULLY!');
        debugPrint('📧 Email: $adminEmail');
        debugPrint('🔑 Password: $adminPassword');
        debugPrint('═══════════════════════════════════════');

        return true;

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Admin already exists - just mark as done, don't sign in
          debugPrint('ℹ️ Admin account already exists, skipping');
          await prefs.setBool(_prefKey, true);

          debugPrint('═══════════════════════════════════════');
          debugPrint('✅ ADMIN READY!');
          debugPrint('📧 Email: $adminEmail');
          debugPrint('🔑 Password: $adminPassword');
          debugPrint('═══════════════════════════════════════');

          return true;
        } else {
          debugPrint('❌ Auth error: ${e.code} - ${e.message}');
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating admin: $e');
      return false;
    }
  }
}
