import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Extension on BuildContext to easily access theme-aware colors
extension ThemeAwareColors on BuildContext {
  // Private helpers
  ThemeData get _theme => Theme.of(this);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;

  // ============================================
  // SEMANTIC COLORS
  // ============================================

  /// Primary color (Navy in light, Gold in dark)
  Color get primaryColor => _colorScheme.primary;

  /// Secondary/Accent color (Gold)
  Color get accentColor => _colorScheme.secondary;

  /// Background color
  Color get backgroundColor => _colorScheme.surface;

  /// Scaffold background color
  Color get scaffoldBackgroundColor => _theme.scaffoldBackgroundColor;

  /// Card color
  Color get cardColor => _isDark ? AppColors.cardDark : AppColors.cardLight;

  /// Surface color
  Color get surfaceColor => _colorScheme.surface;

  /// Border color
  Color get borderColor => _isDark ? AppColors.borderDark : AppColors.borderLight;

  /// Primary text color
  Color get textPrimary => _colorScheme.onSurface;

  /// Secondary/hint text color
  Color get textSecondary => _isDark ? AppColors.tertiaryDark : AppColors.tertiaryLight;

  /// Text on primary buttons
  Color get textOnPrimary => _colorScheme.onPrimary;

  /// Error color
  Color get errorColor => _colorScheme.error;

  /// Success color
  Color get successColor => _isDark ? AppColors.successDark : AppColors.successLight;

  /// Warning color
  Color get warningColor => _isDark ? AppColors.warningDark : AppColors.warningLight;

  /// Info color
  Color get infoColor => _isDark ? AppColors.infoDark : AppColors.infoLight;

  // ============================================
  // BRAND COLORS (Theme-aware)
  // ============================================

  /// Navy color - uses primary in light, stays navy in dark for specific UI
  Color get navyColor => AppColors.navy;

  /// Gold color - brand accent
  Color get goldColor => AppColors.gold;

  // ============================================
  // COMPONENT COLORS
  // ============================================

  /// App bar background
  Color get appBarColor => _isDark ? AppColors.cardDark : AppColors.primaryLight;

  /// Bottom navigation background
  Color get bottomNavColor => cardColor;

  /// Icon color
  Color get iconColor => textPrimary;

  /// Disabled color
  Color get disabledColor => textSecondary.withValues(alpha: 0.5);

  /// Divider color
  Color get dividerColor => borderColor;

  /// Shadow color
  Color get shadowColor => _isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.08);

  /// Overlay color (for modals, etc)
  Color get overlayColor => _isDark
      ? Colors.black.withValues(alpha: 0.7)
      : Colors.black.withValues(alpha: 0.5);
}

/// Extension for Color to create theme-aware variants
extension ThemeAwareColorVariants on Color {
  /// Create a color with adjusted opacity for backgrounds
  Color withBackgroundOpacity(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return withValues(alpha: isDark ? 0.2 : 0.1);
  }

  /// Create a color with adjusted opacity for borders
  Color withBorderOpacity(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return withValues(alpha: isDark ? 0.4 : 0.2);
  }
}
