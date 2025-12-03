import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode storage key
const String _themeModeKey = 'theme_mode';

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

/// Theme mode state notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  /// Load theme mode from SharedPreferences
  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex == null) {
      return ThemeMode.system;
    }
    return ThemeMode.values[themeIndex];
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt(_themeModeKey, mode.index);
  }

  /// Toggle between light and dark mode
  /// If system, switch to light first
  Future<void> toggle() async {
    switch (state) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  /// Set to system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Set to light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set to dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Check if current mode is dark
  bool get isDarkMode => state == ThemeMode.dark;

  /// Check if current mode is light
  bool get isLightMode => state == ThemeMode.light;

  /// Check if current mode is system
  bool get isSystemMode => state == ThemeMode.system;
}

/// Theme mode provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Helper provider to check if dark mode is active (considering system theme)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  switch (themeMode) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
    case ThemeMode.system:
      // This will be resolved at build time using MediaQuery
      // For provider purposes, return false as default
      return false;
  }
});
