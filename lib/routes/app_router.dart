import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/controllers.dart';
import '../views/screens/auth/email_verification_screen.dart';
import '../views/screens/auth/forgot_password_screen.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/pending_approval_screen.dart';
import '../views/screens/auth/profile_setup_screen.dart';
import '../views/screens/auth/register_screen.dart';
import '../views/screens/auth/suspended_account_screen.dart';
import '../views/screens/home/home_screen.dart';
import '../views/screens/main/main_shell.dart';
import '../views/screens/onboarding/onboarding_screen.dart';
import '../views/screens/announcements/announcements_screen.dart';
import '../views/screens/meetings/meetings_screen.dart';
import '../views/screens/initiatives/initiatives_screen.dart';
import '../views/screens/profile/profile_screen.dart';
import '../views/screens/documents/documents_screen.dart';
import '../views/screens/polls/polls_screen.dart';
import '../views/screens/splash/splash_screen.dart';
import '../views/screens/admin/admin_users_screen.dart';
import '../views/screens/admin/admin_setup_screen.dart';
import '../views/screens/admin/admin_shell.dart';
import '../views/screens/admin/user_detail_screen.dart';
import '../core/constants/enums.dart';
import 'route_names.dart';

/// Auth state notifier for router refresh
final _authNotifierProvider = Provider<_AuthStateNotifier>((ref) {
  return _AuthStateNotifier(ref);
});

/// App Router Provider - Creates router ONCE and uses refreshListenable for updates
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(_authNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false, // Disable verbose logging to reduce noise
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Get current auth state directly from container
      final authState = ref.read(authControllerProvider);
      final currentPath = state.matchedLocation;

      // Auth-related paths
      final isAuthPath = currentPath == RouteNames.login ||
          currentPath == RouteNames.register ||
          currentPath == RouteNames.forgotPassword ||
          currentPath == RouteNames.onboarding;
      final isSplash = currentPath == RouteNames.splash;
      final isSpecialAuthPath = currentPath == RouteNames.verifyEmail ||
          currentPath == RouteNames.profileSetup ||
          currentPath == RouteNames.pendingApproval ||
          currentPath == RouteNames.suspended;
      final isMainAppPath = currentPath == RouteNames.home ||
          currentPath == RouteNames.announcements ||
          currentPath == RouteNames.meetings ||
          currentPath == RouteNames.initiatives ||
          currentPath == RouteNames.documents ||
          currentPath == RouteNames.polls ||
          currentPath == RouteNames.profile;

      // If auth state is initial, stay on splash (only on app launch)
      if (authState.state == AuthState.initial) {
        if (!isSplash) return RouteNames.splash;
        return null;
      }

      // If loading, don't redirect - stay where we are
      if (authState.state == AuthState.loading) {
        return null;
      }

      // If not authenticated, redirect to onboarding (unless already on auth pages)
      if (authState.state == AuthState.unauthenticated ||
          authState.state == AuthState.error) {
        if (isAuthPath) return null;
        return RouteNames.onboarding;
      }

      // If email not verified, redirect to email verification screen
      if (authState.state == AuthState.emailNotVerified) {
        if (currentPath == RouteNames.verifyEmail) return null;
        return RouteNames.verifyEmail;
      }

      // If authenticated but needs profile (Google sign-in first time)
      if (authState.state == AuthState.needsProfile) {
        if (currentPath == RouteNames.profileSetup) return null;
        return RouteNames.profileSetup;
      }

      // If account is pending approval
      if (authState.state == AuthState.pendingApproval) {
        if (currentPath == RouteNames.pendingApproval) return null;
        return RouteNames.pendingApproval;
      }

      // If account is suspended
      if (authState.state == AuthState.suspended) {
        if (currentPath == RouteNames.suspended) return null;
        return RouteNames.suspended;
      }

      // Check if user is superadmin
      final isSuperAdmin = authState.user?.role == UserRole.superadmin;
      final isAdminPath = currentPath == RouteNames.adminDashboard ||
          currentPath.startsWith('/admin');

      // If authenticated and on auth/splash pages, redirect based on role
      if (authState.isAuthenticated && (isAuthPath || isSplash || isSpecialAuthPath)) {
        // Superadmin goes to admin dashboard
        if (isSuperAdmin) {
          return RouteNames.adminDashboard;
        }
        return RouteNames.home;
      }

      // If superadmin trying to access regular user home, redirect to admin
      if (authState.isAuthenticated && isSuperAdmin && isMainAppPath && !isAdminPath) {
        return RouteNames.adminDashboard;
      }

      // If authenticated and already on main app path or admin path, don't redirect
      if (authState.isAuthenticated && (isMainAppPath || isAdminPath)) {
        return null;
      }

      return null;
    },
    routes: [
      // ============================================
      // SPLASH SCREEN
      // ============================================
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ============================================
      // ONBOARDING
      // ============================================
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ============================================
      // AUTH ROUTES
      // ============================================
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.pendingApproval,
        name: 'pendingApproval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: RouteNames.suspended,
        name: 'suspended',
        builder: (context, state) => const SuspendedAccountScreen(),
      ),

      // ============================================
      // MAIN APP ROUTES (with Shell for bottom navigation)
      // ============================================
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.announcements,
            name: 'announcements',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnnouncementsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.meetings,
            name: 'meetings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MeetingsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.initiatives,
            name: 'initiatives',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InitiativesScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.documents,
            name: 'documents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DocumentsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.polls,
            name: 'polls',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PollsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.profile,
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ============================================
      // ADMIN ROUTES
      // ============================================
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: RouteNames.adminSetup,
        name: 'adminSetup',
        builder: (context, state) => const AdminSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        name: 'adminUsers',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUserDetail,
        name: 'adminUserDetail',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserDetailScreen(userId: userId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Pagina nu a fost găsită',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text('Înapoi acasă'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Notifier to refresh router when auth state changes meaningfully
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen<AuthStateData>(authControllerProvider, (previous, next) {
      // Only notify if the auth state type actually changed
      // This prevents multiple rebuilds during loading transitions
      if (previous?.state != next.state) {
        // Don't trigger refresh for loading state to prevent jitter
        if (next.state != AuthState.loading) {
          notifyListeners();
        }
      }
    });
  }

  final Ref _ref;
}
