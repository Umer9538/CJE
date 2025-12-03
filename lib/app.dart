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

class _CJEAppState extends ConsumerState<CJEApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create router once and keep it stable
    _router = ref.read(appRouterProvider);
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
