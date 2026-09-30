import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script to create a default admin user
/// Run this once to set up the initial admin account
///
/// Set environment variables before running:
///   ADMIN_EMAIL and ADMIN_PASSWORD
/// Or modify the defaults below for local development only.
class CreateAdminScript {
  static const String _prefKey = 'admin_created_v1';

  static Future<bool> createDefaultAdmin({
    required String email,
    required String password,
    String fullName = 'Super Admin',
  }) async {
    try {
      // Check if admin was already created using SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefKey) == true) {
        debugPrint('Admin already created (cached), skipping');
        return true;
      }

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // If a user is already signed in, don't run the script
      if (auth.currentUser != null) {
        debugPrint('User already signed in, skipping admin creation');
        await prefs.setBool(_prefKey, true);
        return true;
      }

      debugPrint('Checking if admin user exists...');

      // Try to create auth user - this will fail if already exists
      try {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('Auth user created');

        final userId = userCredential.user!.uid;

        // Create user document in Firestore
        await firestore.collection('users').doc(userId).set({
          'email': email,
          'fullName': fullName,
          'firstName': fullName.split(' ').first,
          'lastName': fullName.split(' ').length > 1
              ? fullName.split(' ').sublist(1).join(' ')
              : '',
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

        debugPrint('Admin user created successfully');
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint('Admin account already exists, skipping');
          await prefs.setBool(_prefKey, true);
          return true;
        } else {
          debugPrint('Auth error: ${e.code}');
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error creating admin: $e');
      return false;
    }
  }
}
