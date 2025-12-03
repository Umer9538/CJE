import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/app_localizations.dart';
import '../theme/theme_controller.dart';

/// Language storage key
const String _languageCodeKey = 'language_code';

/// Language state notifier
class LanguageNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs) : super(_loadLocale(_prefs));

  /// Load locale from SharedPreferences
  static Locale _loadLocale(SharedPreferences prefs) {
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode == null) {
      return AppLocales.defaultLocale;
    }
    return AppLocales.fromLanguageCode(languageCode);
  }

  /// Set locale and persist
  Future<void> setLocale(Locale locale) async {
    if (!AppLocales.supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    state = locale;
    await _prefs.setString(_languageCodeKey, locale.languageCode);
  }

  /// Set language by code
  Future<void> setLanguageByCode(String languageCode) async {
    final locale = AppLocales.fromLanguageCode(languageCode);
    await setLocale(locale);
  }

  /// Set to Romanian
  Future<void> setRomanian() async {
    await setLocale(AppLocales.romanian);
  }

  /// Set to English
  Future<void> setEnglish() async {
    await setLocale(AppLocales.english);
  }

  /// Toggle between Romanian and English
  Future<void> toggleLanguage() async {
    if (state.languageCode == 'ro') {
      await setEnglish();
    } else {
      await setRomanian();
    }
  }

  /// Check if current locale is Romanian
  bool get isRomanian => state.languageCode == 'ro';

  /// Check if current locale is English
  bool get isEnglish => state.languageCode == 'en';

  /// Get current language name
  String get currentLanguageName => AppLocales.getLanguageName(state);

  /// Get current language flag
  String get currentLanguageFlag => AppLocales.getFlagEmoji(state);
}

/// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});

/// Helper provider for current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider);
});

/// Helper provider for checking if Romanian
final isRomanianProvider = Provider<bool>((ref) {
  final locale = ref.watch(languageProvider);
  return locale.languageCode == 'ro';
});

/// Helper provider for checking if English
final isEnglishProvider = Provider<bool>((ref) {
  final locale = ref.watch(languageProvider);
  return locale.languageCode == 'en';
});

/// Supported locales provider
final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  return AppLocales.supportedLocales;
});
