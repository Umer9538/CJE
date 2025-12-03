import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Script to create a default admin user
/// Run this once to set up the initial admin account
class CreateAdminScript {
  static const String adminEmail = 'superadmin@cje.ro';
  static const String adminPassword = 'SuperAdmin@2024';
  static const String adminName = 'Super Admin';

  static Future<bool> createDefaultAdmin() async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      debugPrint('🔄 Creating admin user...');

      // Step 1: Try to create auth user first
      UserCredential userCredential;
      try {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        debugPrint('✅ Auth user created');

        final userId = userCredential.user!.uid;
        debugPrint('🔄 Creating Firestore document for user: $userId');

        // Step 2: Create user document in Firestore (user is now authenticated)
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

        debugPrint('═══════════════════════════════════════');
        debugPrint('✅ ADMIN USER CREATED SUCCESSFULLY!');
        debugPrint('📧 Email: $adminEmail');
        debugPrint('🔑 Password: $adminPassword');
        debugPrint('═══════════════════════════════════════');

        return true;

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint('ℹ️ Admin auth account already exists');

          // Try to sign in to check/create Firestore doc
          try {
            userCredential = await auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );

            final userId = userCredential.user!.uid;

            // Check if Firestore doc exists
            final doc = await firestore.collection('users').doc(userId).get();

            if (!doc.exists) {
              // Create Firestore doc
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
              debugPrint('✅ Created Firestore document for existing auth user');
            } else {
              // Update to ensure superadmin role
              await firestore.collection('users').doc(userId).update({
                'role': 'superadmin',
                'status': 'active',
              });
              debugPrint('✅ Updated existing user to superadmin');
            }

            await auth.signOut();

            debugPrint('═══════════════════════════════════════');
            debugPrint('✅ ADMIN READY!');
            debugPrint('📧 Email: $adminEmail');
            debugPrint('🔑 Password: $adminPassword');
            debugPrint('═══════════════════════════════════════');

            return true;
          } on FirebaseAuthException catch (signInError) {
            debugPrint('⚠️ Cannot sign in: ${signInError.code}');
            debugPrint('💡 Admin exists but password may be different.');
            debugPrint('💡 Try: $adminEmail / $adminPassword');
            debugPrint('💡 Or delete user from Firebase Auth console');
            return false;
          }
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
