import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/core.dart';
import 'controllers/controllers.dart';
import 'routes/app_router.dart';

/// CJE Platform Main Application Widget
class CJEApp extends ConsumerStatefulWidget {
  const CJEApp({super.key});

  @override
  ConsumerState<CJEApp> createState() => _CJEAppState();
}

class _CJEAppState extends ConsumerState<CJEApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create router once and keep it stable
    _router = ref.read(appRouterProvider);
    // Add lifecycle observer to handle app resume
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes from background, reload user to ensure session is still valid
    if (state == AppLifecycleState.resumed) {
      _refreshAuthState();
    }
  }

  /// Refresh auth state when app resumes
  Future<void> _refreshAuthState() async {
    try {
      // Reload user to refresh token and check if still authenticated
      await ref.read(authControllerProvider.notifier).reloadUser();
    } catch (e) {
      // If token refresh fails, the auth listener will handle logout
      debugPrint('Error refreshing auth state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization configuration
      locale: locale,
      supportedLocales: AppLocales.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Check if the current device locale is supported
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        // If not supported, return the default locale (Romanian)
        return AppLocales.defaultLocale;
      },

      // Router configuration - use stable instance
      routerConfig: _router,
    );
  }
}
