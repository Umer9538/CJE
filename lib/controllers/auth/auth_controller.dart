import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../models/models.dart';
import '../schools/school_controller.dart';

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

  factory AuthStateData.authenticated(UserModel user, {bool isEmailVerified = true}) {
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

/// Auth controller
class AuthController extends StateNotifier<AuthStateData> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  AuthController(this._ref) : super(AuthStateData.initial()) {
    _init();
  }

  AuthService get _authService => _ref.read(authServiceProvider);
  UserRepository get _userRepository => _ref.read(userRepositoryProvider);
  SchoolRepository get _schoolRepository => _ref.read(schoolRepositoryProvider);

  /// Initialize auth state listener
  void _init() {
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
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
          .listen((snapshot) {
        if (snapshot.exists) {
          final user = UserModel.fromFirestore(snapshot);

          // Check user status
          switch (user.status) {
            case UserStatus.pending:
              state = AuthStateData.pendingApproval(user);
              break;
            case UserStatus.suspended:
              state = AuthStateData.suspended(user);
              break;
            case UserStatus.active:
              // Check email verification for email/password users
              // Skip email verification for superadmin and bex roles
              final isEmailUser = firebaseUser.providerData
                  .any((info) => info.providerId == 'password');
              final skipEmailVerification = user.role == UserRole.superadmin ||
                                            user.role == UserRole.bex;

              if (isEmailUser && !firebaseUser.emailVerified && !skipEmailVerification) {
                state = AuthStateData.emailNotVerified(user);
              } else {
                state = AuthStateData.authenticated(
                  user,
                  isEmailVerified: firebaseUser.emailVerified || skipEmailVerification,
                );
                // Update last login
                _userRepository.updateLastLogin(user.id);
              }
              break;
          }
        } else {
          // User exists in Firebase Auth but not in Firestore
          state = AuthStateData.needsProfile();
        }
      }, onError: (error) {
        state = AuthStateData.error('Eroare la încărcarea profilului');
      });
    } catch (e) {
      state = AuthStateData.error('Eroare la încărcarea profilului');
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
      state = AuthStateData.error(result.errorMessage ?? 'Eroare la autentificare');
    }
    // If success, _onAuthStateChanged will handle the state update

    return result;
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    state = AuthStateData.loading();
    final result = await _authService.signInWithGoogle();

    if (!result.success) {
      state = AuthStateData.error(result.errorMessage ?? 'Eroare la autentificare');
    }

    return result;
  }

  /// Create account with email
  Future<AuthResult> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String schoolId,
    required String phoneNumber,
    required String city,
    String? className,
  }) async {
    state = AuthStateData.loading();

    // Create Firebase Auth account
    final result = await _authService.createAccountWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (!result.success) {
      state = AuthStateData.error(result.errorMessage ?? 'Eroare la creare cont');
      return result;
    }

    // Create user profile in Firestore
    try {
      final user = result.user!;
      final school = await _schoolRepository.getSchoolById(schoolId);

      final userModel = UserModel(
        id: user.uid,
        email: email.toLowerCase(),
        fullName: fullName,
        photoUrl: user.photoURL,
        phoneNumber: phoneNumber,
        city: city,
        role: UserRole.student,
        status: UserStatus.active, // Auto-approve for now (change to pending when admin panel is ready)
        schoolId: schoolId,
        schoolName: school?.name,
        className: className,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _userRepository.createUser(userModel);
      if (!success) {
        // If Firestore fails, delete the Firebase Auth account
        await result.user?.delete();
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
      // If Firestore fails, delete the Firebase Auth account
      await result.user?.delete();
      state = AuthStateData.error('Eroare la salvarea profilului');
      return AuthResult.failure('Eroare la salvarea profilului');
    }
  }

  /// Create profile for Google sign-in user
  Future<bool> createGoogleUserProfile({
    required String fullName,
    required String schoolId,
    required String phoneNumber,
    required String city,
    String? className,
  }) async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return false;

    try {
      final school = await _schoolRepository.getSchoolById(schoolId);

      final userModel = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email?.toLowerCase() ?? '',
        fullName: fullName,
        photoUrl: firebaseUser.photoURL,
        phoneNumber: phoneNumber,
        city: city,
        role: UserRole.student,
        status: UserStatus.active, // Auto-approve for now
        schoolId: schoolId,
        schoolName: school?.name,
        className: className,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _userRepository.createUser(userModel);
      if (!success) return false;

      // Increment school student count
      if (schoolId.isNotEmpty) {
        await _schoolRepository.incrementStudentCount(schoolId);
      }

      // Reload user profile
      await _loadUserProfile(firebaseUser);
      return true;
    } catch (e) {
      return false;
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
    if (isVerified && state.user != null) {
      state = AuthStateData.authenticated(state.user!, isEmailVerified: true);
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

    final success = await _userRepository.updateUserFields(
      user.id,
      {'photoUrl': photoUrl},
    );

    if (success) {
      await _authService.updateProfile(photoUrl: photoUrl);
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

  /// Sign out
  Future<void> signOut() async {
    _userSubscription?.cancel();
    await _authService.signOut();
    state = AuthStateData.unauthenticated();
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    final user = state.user;
    if (user == null) {
      return AuthResult.failure('Nu există utilizator autentificat');
    }

    try {
      // Decrement school student count
      if (user.schoolId != null && user.schoolId!.isNotEmpty) {
        await _schoolRepository.decrementStudentCount(user.schoolId!);
      }

      // Delete Firestore document first
      await _userRepository.deleteUser(user.id);

      // Then delete Firebase Auth account
      final result = await _authService.deleteAccount();
      if (result.success) {
        state = AuthStateData.unauthenticated();
      }
      return result;
    } catch (e) {
      return AuthResult.failure('Eroare la ștergerea contului');
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
