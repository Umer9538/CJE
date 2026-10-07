import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../models/models.dart';
import '../schools/school_controller.dart';
import '../theme/theme_controller.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Firebase Auth stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current Firebase user provider
final firebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Auth state for the app
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsProfile, // User exists in Firebase Auth but not in Firestore
  needsPrivacyOnboarding, // Imported/legacy profile lacks privacy acknowledgement
  pendingApproval, // User registered but waiting for admin approval
  suspended, // User account is suspended
  emailNotVerified, // Email not verified
  error,
}

/// Auth state data
class AuthStateData {
  final AuthState state;
  final UserModel? user;
  final String? errorMessage;
  final bool isEmailVerified;

  const AuthStateData({
    required this.state,
    this.user,
    this.errorMessage,
    this.isEmailVerified = true,
  });

  factory AuthStateData.initial() {
    return const AuthStateData(state: AuthState.initial);
  }

  factory AuthStateData.loading() {
    return const AuthStateData(state: AuthState.loading);
  }

  factory AuthStateData.authenticated(
    UserModel user, {
    bool isEmailVerified = true,
  }) {
    return AuthStateData(
      state: AuthState.authenticated,
      user: user,
      isEmailVerified: isEmailVerified,
    );
  }

  factory AuthStateData.unauthenticated() {
    return const AuthStateData(state: AuthState.unauthenticated);
  }

  factory AuthStateData.needsProfile() {
    return const AuthStateData(state: AuthState.needsProfile);
  }

  factory AuthStateData.needsPrivacyOnboarding(UserModel user) {
    return AuthStateData(state: AuthState.needsPrivacyOnboarding, user: user);
  }

  factory AuthStateData.pendingApproval(UserModel user) {
    return AuthStateData(state: AuthState.pendingApproval, user: user);
  }

  factory AuthStateData.suspended(UserModel user) {
    return AuthStateData(state: AuthState.suspended, user: user);
  }

  factory AuthStateData.emailNotVerified(UserModel user) {
    return AuthStateData(
      state: AuthState.emailNotVerified,
      user: user,
      isEmailVerified: false,
    );
  }

  factory AuthStateData.error(String message) {
    return AuthStateData(state: AuthState.error, errorMessage: message);
  }

  bool get isLoading => state == AuthState.loading;
  bool get isAuthenticated => state == AuthState.authenticated;
  bool get isUnauthenticated => state == AuthState.unauthenticated;
  bool get needsPrivacyNotice => state == AuthState.needsPrivacyOnboarding;
  bool get isPendingApproval => state == AuthState.pendingApproval;
  bool get isSuspended => state == AuthState.suspended;
  bool get needsEmailVerification => state == AuthState.emailNotVerified;

  AuthStateData copyWith({
    AuthState? state,
    UserModel? user,
    String? errorMessage,
    bool? isEmailVerified,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateData>((ref) {
      return AuthController(ref);
    });

/// Current user provider (convenience)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});

/// User statistics model
class UserStats {
  final int totalVotes;
  final int initiativesCount;
  final int meetingsAttended;

  const UserStats({
    this.totalVotes = 0,
    this.initiativesCount = 0,
    this.meetingsAttended = 0,
  });
}

/// User statistics provider - fetches real counts for the current user
/// Uses efficient queries to avoid loading all documents
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final user = ref.read(currentUserProvider); // Use read to avoid rebuilds
  if (user == null) return const UserStats();

  final firestore = FirebaseFirestore.instance;

  try {
    // Use parallel futures for efficiency
    final results = await Future.wait([
      // Count votes - use array-contains query instead of scanning all polls
      firestore
          .collection('polls')
          .where('voterIds', arrayContains: user.id)
          .count()
          .get()
          .then((q) => q.count ?? 0)
          .timeout(const Duration(seconds: 5), onTimeout: () => 0),

      // Count initiatives created by user
      firestore
          .collection('initiatives')
          .where('authorId', isEqualTo: user.id)
          .count()
          .get()
          .then((q) => q.count ?? 0)
          .timeout(const Duration(seconds: 5), onTimeout: () => 0),

      // Count meetings attended by user
      firestore
          .collection('meetings')
          .where('attendeeIds', arrayContains: user.id)
          .count()
          .get()
          .then((q) => q.count ?? 0)
          .timeout(const Duration(seconds: 5), onTimeout: () => 0),
    ]);

    return UserStats(
      totalVotes: results[0],
      initiativesCount: results[1],
      meetingsAttended: results[2],
    );
  } catch (e) {
    debugPrint('userStatsProvider error: $e');
    return const UserStats();
  }
});

/// Auth controller
class AuthController extends StateNotifier<AuthStateData> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  AuthState?
  _lastEmittedState; // Track last emitted state to prevent duplicates
  bool _hasUpdatedLastLogin =
      false; // Prevent multiple lastLogin updates per session

  AuthController(this._ref) : super(AuthStateData.initial()) {
    _init();
  }

  AuthService get _authService => _ref.read(authServiceProvider);
  UserRepository get _userRepository => _ref.read(userRepositoryProvider);
  SchoolRepository get _schoolRepository => _ref.read(schoolRepositoryProvider);

  /// Initialize auth state listener
  void _init() {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  /// Handle auth state changes
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _userSubscription?.cancel();
      state = AuthStateData.unauthenticated();
      return;
    }

    // User is signed in, fetch their profile from Firestore
    await _loadUserProfile(firebaseUser);
  }

  /// Helper to set state only if it's different from last emitted state
  void _setStateIfChanged(AuthStateData newState) {
    if (_lastEmittedState != newState.state) {
      _lastEmittedState = newState.state;
      state = newState;
    } else if (state.user?.id != newState.user?.id) {
      // Only update if user ID changed (different user), not for minor field updates
      state = newState;
    }
    // Don't update state for minor user data changes like lastLogin
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(User firebaseUser) async {
    state = AuthStateData.loading();

    try {
      // Cancel previous subscription
      _userSubscription?.cancel();

      // Listen to user document changes
      _userSubscription = _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                final user = UserModel.fromFirestore(snapshot);

                // An importer cannot acknowledge the notice or declare age on
                // the user's behalf. Force imported and older profiles through
                // the dedicated first-login step before application access.
                // Suspended accounts remain on the suspension screen.
                if (user.status != UserStatus.suspended &&
                    user.needsPrivacyOnboarding) {
                  _setStateIfChanged(
                    AuthStateData.needsPrivacyOnboarding(user),
                  );
                  return;
                }

                // Check user status
                switch (user.status) {
                  case UserStatus.pending:
                    _setStateIfChanged(AuthStateData.pendingApproval(user));
                    break;
                  case UserStatus.suspended:
                    _setStateIfChanged(AuthStateData.suspended(user));
                    break;
                  case UserStatus.active:
                    // Check email verification for email/password users
                    // Skip email verification for superadmin and bex roles
                    // Verificarea de email se aplica uniform, indiferent de rol.
                    // Anterior bex si superadmin erau exceptati, ceea ce lasa exact
                    // conturile cele mai privilegiate fara aceasta verificare.
                    final isEmailUser = firebaseUser.providerData.any(
                      (info) => info.providerId == 'password',
                    );

                    if (isEmailUser && !firebaseUser.emailVerified) {
                      _setStateIfChanged(AuthStateData.emailNotVerified(user));
                    } else {
                      _setStateIfChanged(
                        AuthStateData.authenticated(
                          user,
                          isEmailVerified: firebaseUser.emailVerified,
                        ),
                      );
                      // Update last login only once per session to prevent infinite loop
                      if (!_hasUpdatedLastLogin) {
                        _hasUpdatedLastLogin = true;
                        _userRepository.updateLastLogin(user.id);
                        // Register FCM token for push notifications
                        _registerFcmToken(user.id);
                        // Sync preferred language to Firestore for notification localization
                        _syncPreferredLanguage(user.id);
                      }
                    }
                    break;
                }
              } else {
                // User exists in Firebase Auth but not in Firestore
                _setStateIfChanged(AuthStateData.needsProfile());
              }
            },
            onError: (error) {
              _setStateIfChanged(
                AuthStateData.error('Eroare la încărcarea profilului'),
              );
            },
          );
    } catch (e) {
      _setStateIfChanged(
        AuthStateData.error('Eroare la încărcarea profilului'),
      );
    }
  }

  /// Sign in with email
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthStateData.loading();
    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (!result.success) {
      state = AuthStateData.error(
        result.errorMessage ?? 'Eroare la autentificare',
      );
    }
    // If success, _onAuthStateChanged will handle the state update

    return result;
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    state = AuthStateData.loading();
    final result = await _authService.signInWithGoogle();

    if (!result.success) {
      state = AuthStateData.error(
        result.errorMessage ?? 'Eroare la autentificare',
      );
    }

    return result;
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    state = AuthStateData.loading();
    final result = await _authService.signInWithApple();

    if (!result.success) {
      state = AuthStateData.error(
        result.errorMessage ?? 'Eroare la autentificare',
      );
    }

    return result;
  }

  /// Complete the mandatory first-login privacy step for imported/legacy
  /// profiles. An active account declaring that it is under 16 is moved back
  /// to pending unless a parent/guardian authorisation was already verified.
  Future<(bool, String?)> completePrivacyOnboarding({
    required bool isUnder16,
    required bool privacyNoticeAcknowledged,
    required bool termsAccepted,
  }) async {
    if (!termsAccepted) {
      return (false, 'Trebuie să accepți Termenii de utilizare.');
    }
    if (!privacyNoticeAcknowledged) {
      return (false, 'Politica de confidențialitate trebuie confirmată.');
    }

    final user = state.user;
    if (user == null || user.id.isEmpty) {
      return (false, 'Profilul utilizatorului nu este disponibil.');
    }

    final now = Timestamp.now();
    final fields = <String, dynamic>{
      'privacyNoticeVersion': AppStrings.privacyNoticeVersion,
      'privacyNoticeAcknowledgedAt': now,
      'termsVersion': AppStrings.termsVersion,
      'termsAcceptedAt': now,
      'isUnder16': isUnder16,
      'parentalAuthorizationDeclaredAt': isUnder16 ? now : null,
    };

    if (user.status == UserStatus.active &&
        isUnder16 &&
        user.parentalAuthorizationVerifiedAt == null) {
      fields['status'] = UserStatus.pending.toFirestore();
    }

    final success = await _userRepository.updateUserFields(user.id, fields);
    if (!success) {
      return (false, 'Confirmarea nu a putut fi salvată. Încearcă din nou.');
    }
    return (true, null);
  }

  /// Create account with email
  Future<AuthResult> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String schoolId,
    String? phoneNumber,
    required String city,
    required bool isUnder16,
    required bool privacyNoticeAcknowledged,
    required bool termsAccepted,
    String? className,
  }) async {
    if (!termsAccepted) {
      return AuthResult.failure('Trebuie să accepți Termenii de utilizare.');
    }
    if (!privacyNoticeAcknowledged) {
      return AuthResult.failure(
        'Politica de confidențialitate trebuie confirmată.',
      );
    }

    state = AuthStateData.loading();

    // Create Firebase Auth account
    final result = await _authService.createAccountWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (!result.success) {
      state = AuthStateData.error(
        result.errorMessage ?? 'Eroare la creare cont',
      );
      return result;
    }

    // Create user profile in Firestore
    try {
      final user = result.user!;
      final school = await _schoolRepository.getSchoolById(schoolId);

      final registrationTime = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        email: email.toLowerCase(),
        fullName: fullName,
        photoUrl: user.photoURL,
        phoneNumber: phoneNumber,
        city: city,
        role: UserRole.student,
        status: UserStatus.pending, // Requires admin/BEX approval
        schoolId: schoolId,
        schoolName: school?.name,
        className: className,
        createdAt: registrationTime,
        updatedAt: registrationTime,
        privacyNoticeVersion: AppStrings.privacyNoticeVersion,
        privacyNoticeAcknowledgedAt: registrationTime,
        termsVersion: AppStrings.termsVersion,
        termsAcceptedAt: registrationTime,
        isUnder16: isUnder16,
        parentalAuthorizationDeclaredAt: isUnder16 ? registrationTime : null,
      );

      // Create user in Firestore with retry
      bool success = await _userRepository.createUser(userModel);

      // Retry once if failed
      if (!success) {
        await Future.delayed(const Duration(milliseconds: 500));
        success = await _userRepository.createUser(userModel);
      }

      if (!success) {
        // If Firestore fails, delete the Firebase Auth account
        debugPrint(
          'Failed to create user in Firestore, deleting Firebase Auth account',
        );
        try {
          await result.user?.delete();
        } catch (deleteError) {
          debugPrint('Error deleting Firebase Auth account: $deleteError');
        }
        state = AuthStateData.error('Eroare la salvarea profilului');
        return AuthResult.failure('Eroare la salvarea profilului');
      }

      // Increment school student count
      if (schoolId.isNotEmpty) {
        await _schoolRepository.incrementStudentCount(schoolId);
      }

      // Send email verification
      await _authService.sendEmailVerification();

      return result;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // If Firestore fails, delete the Firebase Auth account
      try {
        await result.user?.delete();
      } catch (deleteError) {
        debugPrint('Error deleting Firebase Auth account: $deleteError');
      }
      state = AuthStateData.error('Eroare la salvarea profilului');
      return AuthResult.failure('Eroare la salvarea profilului');
    }
  }

  /// Create profile for Google sign-in user (also works for email users without Firestore profile)
  /// Returns a tuple of (success, errorMessage)
  Future<(bool, String?)> createGoogleUserProfile({
    required String fullName,
    required String schoolId,
    String? schoolName,
    String? phoneNumber,
    required String city,
    required bool isUnder16,
    required bool privacyNoticeAcknowledged,
    required bool termsAccepted,
    String? className,
  }) async {
    if (!termsAccepted) {
      return (false, 'Trebuie să accepți Termenii de utilizare.');
    }
    debugPrint('=== createGoogleUserProfile START ===');

    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      debugPrint('createGoogleUserProfile: ERROR - No Firebase user');
      return (false, 'No authenticated user found');
    }

    if (!privacyNoticeAcknowledged) {
      return (false, 'Politica de confidențialitate trebuie confirmată.');
    }

    try {
      // Try to get school from Firestore, fall back to provided name for sample schools
      debugPrint('Fetching school by ID: $schoolId');
      final school = await _schoolRepository.getSchoolById(schoolId);
      debugPrint('School from Firestore: ${school?.name ?? "null"}');

      final effectiveSchoolName =
          school?.name ?? schoolName ?? 'Unknown School';

      if (school == null && schoolName == null) {
        debugPrint(
          'createGoogleUserProfile: ERROR - School not found and no name provided: $schoolId',
        );
        return (false, 'School not found');
      }

      debugPrint(
        'createGoogleUserProfile: Using school name: $effectiveSchoolName',
      );

      final registrationTime = DateTime.now();
      final userModel = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email?.toLowerCase() ?? '',
        fullName: fullName,
        photoUrl: firebaseUser.photoURL,
        phoneNumber: phoneNumber,
        city: city,
        role: UserRole.student,
        status: UserStatus.pending, // Requires admin/BEX approval
        schoolId: schoolId,
        schoolName: effectiveSchoolName,
        className: className,
        createdAt: registrationTime,
        updatedAt: registrationTime,
        privacyNoticeVersion: AppStrings.privacyNoticeVersion,
        privacyNoticeAcknowledgedAt: registrationTime,
        termsVersion: AppStrings.termsVersion,
        termsAcceptedAt: registrationTime,
        isUnder16: isUnder16,
        parentalAuthorizationDeclaredAt: isUnder16 ? registrationTime : null,
      );

      // Create user in Firestore with retry and exponential backoff
      bool success = false;
      const maxAttempts = 3;
      final delays = [
        Duration.zero,
        const Duration(milliseconds: 500),
        const Duration(seconds: 2),
      ];

      for (int attempt = 1; attempt <= maxAttempts && !success; attempt++) {
        if (attempt > 1) {
          final delay = delays[attempt - 1];
          debugPrint(
            'createGoogleUserProfile: Attempt $attempt failed, waiting ${delay.inMilliseconds}ms before retry...',
          );
          await Future.delayed(delay);
        }
        debugPrint(
          'Attempting to save user to Firestore (attempt $attempt of $maxAttempts)...',
        );
        success = await _userRepository.createUser(userModel);
        debugPrint('Attempt $attempt result: $success');
      }

      if (!success) {
        debugPrint(
          'createGoogleUserProfile: ERROR - Failed to create user in Firestore after $maxAttempts attempts',
        );
        return (false, 'Failed to save profile to database');
      }

      debugPrint(
        'createGoogleUserProfile: SUCCESS - User created in Firestore',
      );

      // Increment school student count
      if (schoolId.isNotEmpty) {
        debugPrint('Incrementing student count for school: $schoolId');
        await _schoolRepository.incrementStudentCount(schoolId);
      }

      // Reload user profile
      debugPrint('Reloading user profile...');
      await _loadUserProfile(firebaseUser);
      debugPrint('=== createGoogleUserProfile END (success) ===');
      return (true, null);
    } catch (e, stackTrace) {
      debugPrint('createGoogleUserProfile EXCEPTION: $e');
      debugPrint('Stack trace: $stackTrace');
      return (false, e.toString());
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    return await _authService.sendPasswordResetEmail(email);
  }

  /// Send email verification
  Future<AuthResult> sendEmailVerification() async {
    return await _authService.sendEmailVerification();
  }

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    final isVerified = await _authService.isEmailVerified();
    final firebaseUser = _authService.currentUser;
    if (isVerified && firebaseUser != null) {
      // Keep Abdul's no-loading redirect fix, but resolve the fresh profile:
      // verifying email must not bypass suspension, approval or privacy gates.
      await _loadUserProfile(firebaseUser);
    }
    return isVerified;
  }

  /// Reload user (to check email verification)
  Future<void> reloadUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.reload();
      await _loadUserProfile(firebaseUser);
    }
  }

  /// Update user profile in Firestore
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    return await _userRepository.updateUser(updatedUser);
  }

  /// Update user photo
  Future<bool> updateUserPhoto(String photoUrl) async {
    final user = state.user;
    if (user == null) return false;

    final success = await _userRepository.updateUserFields(user.id, {
      'photoUrl': photoUrl,
    });

    if (success) {
      await _authService.updateProfile(photoUrl: photoUrl);
      // Update local state with new photo URL
      final updatedUser = user.copyWith(photoUrl: photoUrl);
      state = state.copyWith(user: updatedUser);
    }

    return success;
  }

  /// Update user profile (fullName, phoneNumber)
  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    final user = state.user;
    if (user == null) return false;

    final updates = <String, dynamic>{
      'fullName': fullName,
      'updatedAt': DateTime.now(),
    };

    if (phoneNumber != null) {
      updates['phoneNumber'] = phoneNumber;
    }

    final success = await _userRepository.updateUserFields(user.id, updates);

    if (success) {
      // Update display name in Firebase Auth
      await _authService.updateProfile(displayName: fullName);

      // Update local state
      state = state.copyWith(
        user: user.copyWith(
          fullName: fullName,
          phoneNumber: phoneNumber ?? user.phoneNumber,
        ),
      );
    }

    return success;
  }

  /// Update FCM token
  Future<void> updateFcmToken(String token) async {
    final user = state.user;
    if (user == null) return;

    await _userRepository.updateFcmToken(user.id, token);
  }

  /// Register FCM token for push notifications
  Future<void> _registerFcmToken(String userId) async {
    try {
      final fcmService = FCMService();
      final token = await fcmService.getToken();
      if (token != null) {
        await _userRepository.updateFcmToken(userId, token);
        debugPrint('FCM token registered for user: $userId');

        // Listen for token refresh
        fcmService.onTokenRefresh((newToken) async {
          await _userRepository.updateFcmToken(userId, newToken);
          debugPrint('FCM token refreshed for user: $userId');
        });
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Sync the user's preferred language from local settings to Firestore
  /// so notifications are sent in the correct language
  Future<void> _syncPreferredLanguage(String userId) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final languageCode = prefs.getString('language_code') ?? 'en';
      await _firestore.collection('users').doc(userId).update({
        'preferredLanguage': languageCode,
      });
      debugPrint('Preferred language synced to Firestore: $languageCode');
    } catch (e) {
      debugPrint('Error syncing preferred language: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _userSubscription?.cancel();
    _lastEmittedState = null; // Reset state tracking
    _hasUpdatedLastLogin = false; // Reset last login flag for next session

    // Delete FCM token on sign out
    try {
      await FCMService().deleteToken();
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }

    await _authService.signOut();
    state = AuthStateData.unauthenticated();
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    final user = _authService.currentUser;
    if (user == null) {
      return AuthResult.failure('Nu există utilizator autentificat');
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteAccount',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      final applePreparation = await _authService.prepareAppleAccountDeletion();
      if (!applePreparation.success) return applePreparation;
      await callable.call<void>();

      await _userSubscription?.cancel();
      _lastEmittedState = null;
      _hasUpdatedLastLogin = false;
      await _authService.signOut();
      state = AuthStateData.unauthenticated();
      return const AuthResult(success: true);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message == 'requires-recent-login') {
        return AuthResult.failure(
          'Din motive de securitate, autentifică-te din nou înainte de '
              'ștergerea contului.',
          'requires-recent-login',
        );
      }
      return AuthResult.failure(
        e.message ?? 'Eroare la ștergerea contului și a datelor asociate.',
        e.code,
      );
    } catch (e) {
      debugPrint('Delete account failed: $e');
      return AuthResult.failure(
        'Eroare la ștergerea contului și a datelor asociate.',
      );
    }
  }

  /// Re-authenticate (required before sensitive operations)
  Future<AuthResult> reauthenticate({
    required String email,
    required String password,
  }) async {
    return await _authService.reauthenticate(email: email, password: password);
  }

  /// Update password
  Future<AuthResult> updatePassword(String newPassword) async {
    return await _authService.updatePassword(newPassword);
  }

  /// Change password (reauthenticate + update)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = state.user;
    if (user == null || user.email.isEmpty) {
      throw Exception('Nu există utilizator autentificat');
    }

    // First reauthenticate
    final reauthResult = await _authService.reauthenticate(
      email: user.email,
      password: currentPassword,
    );

    if (!reauthResult.success) {
      throw Exception('Parola curentă este incorectă');
    }

    // Then update password
    final updateResult = await _authService.updatePassword(newPassword);
    if (!updateResult.success) {
      throw Exception(
        updateResult.errorMessage ?? 'Eroare la schimbarea parolei',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
