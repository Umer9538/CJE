import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;
  final String? errorCode;

  const AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  factory AuthResult.success(User user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String message, [String? code]) {
    return AuthResult(success: false, errorMessage: message, errorCode: code);
  }
}

/// Firebase Authentication Service
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            serverClientId:
                '317912008960-3gp92dvqr869gmgo0tr9rdhlifdseta2.apps.googleusercontent.com',
          ) {
    // Set persistence to LOCAL to keep the user logged in
    // Note: setPersistence is only supported on web platforms
    // On mobile (Android/iOS), persistence is LOCAL by default
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Stream of auth state changes - uses idTokenChanges for better token refresh handling
  Stream<User?> get authStateChanges => _auth.idTokenChanges();

  /// Stream of user changes (includes token refresh)
  Stream<User?> get userChanges => _auth.userChanges();

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Sign in error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Create account with email and password
  Future<AuthResult> createAccountWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName);
      await credential.user?.reload();

      return AuthResult.success(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } on FirebaseException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Create account error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google sign-in flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Autentificare anulată');
      }

      // Get auth details
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return AuthResult.failure(
        'Autentificare cu Google a eșuat. Încearcă din nou.',
      );
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Apple only provides name on first sign-in; update display name if available
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      if (fullName.isNotEmpty && userCredential.user?.displayName == null) {
        await userCredential.user?.updateDisplayName(fullName);
      }

      return AuthResult.success(userCredential.user!);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure('Autentificare anulată');
      }
      return AuthResult.failure(
        'Autentificare cu Apple a eșuat. Încearcă din nou.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return AuthResult.failure(
        'Autentificare cu Apple a eșuat. Încearcă din nou.',
      );
    }
  }

  /// Reauthenticate the same Apple account and revoke its Apple authorization
  /// before the backend erases Firebase Auth and application data.
  Future<AuthResult> prepareAppleAccountDeletion() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.failure('Nu există utilizator autentificat.');
    }
    if (!user.providerData.any(
      (provider) => provider.providerId == 'apple.com',
    )) {
      return const AuthResult(success: true);
    }
    try {
      final rawNonce = _generateNonce();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [],
        nonce: _sha256ofString(rawNonce),
      );
      final credential = OAuthProvider(
        'apple.com',
      ).credential(idToken: apple.identityToken, rawNonce: rawNonce);
      await user.reauthenticateWithCredential(credential);
      await user.getIdToken(true);
      await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
      return const AuthResult(success: true);
    } on SignInWithAppleAuthorizationException catch (error) {
      return AuthResult.failure(
        error.code == AuthorizationErrorCode.canceled
            ? 'Ștergerea a fost anulată.'
            : 'Autorizarea Apple nu a putut fi revocată.',
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_getErrorMessage(error.code), error.code);
    } catch (_) {
      return AuthResult.failure(
        'Autorizarea Apple nu a putut fi revocată. Încearcă din nou.',
      );
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Password reset error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Email verification error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      if (displayName != null) {
        await currentUser?.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await currentUser?.updatePhotoURL(photoUrl);
      }
      await currentUser?.reload();
      return AuthResult.success(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Update profile error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Update password
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Update password error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Re-authenticate user (required before sensitive operations)
  Future<AuthResult> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser?.reauthenticateWithCredential(credential);
      return AuthResult.success(currentUser!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Reauthentication error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable(
            'deleteAccount',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
          )
          .call();
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code), e.code);
    } catch (e) {
      debugPrint('Delete account error: $e');
      return AuthResult.failure('A apărut o eroare. Încearcă din nou.');
    }
  }

  /// Get user-friendly error message in Romanian
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nu există un cont cu această adresă de email.';
      case 'wrong-password':
        return 'Parola este incorectă.';
      case 'invalid-email':
        return 'Adresa de email nu este validă.';
      case 'user-disabled':
        return 'Acest cont a fost dezactivat.';
      case 'email-already-in-use':
        return 'Există deja un cont cu această adresă de email.';
      case 'weak-password':
        return 'Parola este prea slabă. Folosește cel puțin 6 caractere.';
      case 'operation-not-allowed':
        return 'Această operațiune nu este permisă.';
      case 'too-many-requests':
        return 'Prea multe încercări. Încearcă din nou mai târziu.';
      case 'network-request-failed':
        return 'Eroare de conexiune. Verifică internetul.';
      case 'invalid-credential':
        return 'Email sau parolă incorectă.';
      case 'requires-recent-login':
        return 'Te rugăm să te autentifici din nou pentru această operațiune.';
      default:
        return 'A apărut o eroare. Încearcă din nou.';
    }
  }
}
