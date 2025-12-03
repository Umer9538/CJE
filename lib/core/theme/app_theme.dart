import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// CJE Platform Theme Configuration
/// Light and Dark themes based on the official color guide
class AppTheme {
  AppTheme._();

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _textTheme(AppColors.textPrimaryLight),
      appBarTheme: _appBarTheme(isLight: true),
      cardTheme: _cardTheme(isLight: true),
      elevatedButtonTheme: _elevatedButtonTheme(isLight: true),
      outlinedButtonTheme: _outlinedButtonTheme(isLight: true),
      textButtonTheme: _textButtonTheme(isLight: true),
      inputDecorationTheme: _inputDecorationTheme(isLight: true),
      floatingActionButtonTheme: _fabTheme(isLight: true),
      bottomNavigationBarTheme: _bottomNavTheme(isLight: true),
      navigationBarTheme: _navigationBarTheme(isLight: true),
      dividerTheme: _dividerTheme(isLight: true),
      chipTheme: _chipTheme(isLight: true),
      dialogTheme: _dialogTheme(isLight: true),
      bottomSheetTheme: _bottomSheetTheme(isLight: true),
      snackBarTheme: _snackBarTheme(isLight: true),
      tabBarTheme: _tabBarTheme(isLight: true),
      checkboxTheme: _checkboxTheme(isLight: true),
      radioTheme: _radioTheme(isLight: true),
      switchTheme: _switchTheme(isLight: true),
      progressIndicatorTheme: _progressIndicatorTheme(isLight: true),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: AppSizes.iconLG,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimaryLight,
        size: AppSizes.iconLG,
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _textTheme(AppColors.textPrimaryDark),
      appBarTheme: _appBarTheme(isLight: false),
      cardTheme: _cardTheme(isLight: false),
      elevatedButtonTheme: _elevatedButtonTheme(isLight: false),
      outlinedButtonTheme: _outlinedButtonTheme(isLight: false),
      textButtonTheme: _textButtonTheme(isLight: false),
      inputDecorationTheme: _inputDecorationTheme(isLight: false),
      floatingActionButtonTheme: _fabTheme(isLight: false),
      bottomNavigationBarTheme: _bottomNavTheme(isLight: false),
      navigationBarTheme: _navigationBarTheme(isLight: false),
      dividerTheme: _dividerTheme(isLight: false),
      chipTheme: _chipTheme(isLight: false),
      dialogTheme: _dialogTheme(isLight: false),
      bottomSheetTheme: _bottomSheetTheme(isLight: false),
      snackBarTheme: _snackBarTheme(isLight: false),
      tabBarTheme: _tabBarTheme(isLight: false),
      checkboxTheme: _checkboxTheme(isLight: false),
      radioTheme: _radioTheme(isLight: false),
      switchTheme: _switchTheme(isLight: false),
      progressIndicatorTheme: _progressIndicatorTheme(isLight: false),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
        size: AppSizes.iconLG,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimaryDark,
        size: AppSizes.iconLG,
      ),
    );
  }

  // ============================================
  // COLOR SCHEMES
  // ============================================

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.textOnPrimaryLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.primaryLight,
    tertiary: AppColors.tertiaryLight,
    onTertiary: AppColors.white,
    error: AppColors.errorLight,
    onError: AppColors.white,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.cardLight,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.borderLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.textOnPrimaryDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.textOnPrimaryDark,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.backgroundDark,
    error: AppColors.errorDark,
    onError: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerHighest: AppColors.cardDark,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.borderDark,
  );

  // ============================================
  // TEXT THEME (Inter font)
  // ============================================

  static TextTheme _textTheme(Color textColor) {
    return GoogleFonts.interTextTheme().copyWith(
      // Display styles
      displayLarge: GoogleFonts.inter(
        fontSize: AppSizes.fontDisplayLG,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: AppSizes.lineHeightTight,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: AppSizes.fontDisplay,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: AppSizes.lineHeightTight,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: AppSizes.fontHuge,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: AppSizes.lineHeightTight,
      ),
      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: AppSizes.fontXXL,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: AppSizes.lineHeightTight,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: AppSizes.lineHeightTight,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: AppSizes.fontLG,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: AppSizes.fontXXS,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: AppSizes.lineHeightNormal,
      ),
    );
  }

  // ============================================
  // APP BAR THEME
  // ============================================

  static AppBarTheme _appBarTheme({required bool isLight}) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      backgroundColor: isLight ? AppColors.primaryLight : AppColors.cardDark,
      foregroundColor: isLight ? AppColors.textOnPrimaryLight : AppColors.textPrimaryDark,
      iconTheme: IconThemeData(
        color: isLight ? AppColors.textOnPrimaryLight : AppColors.textPrimaryDark,
        size: AppSizes.iconAppBar,
      ),
      actionsIconTheme: IconThemeData(
        color: isLight ? AppColors.textOnPrimaryLight : AppColors.textPrimaryDark,
        size: AppSizes.iconAppBar,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontLG,
        fontWeight: FontWeight.w600,
        color: isLight ? AppColors.textOnPrimaryLight : AppColors.textPrimaryDark,
      ),
      systemOverlayStyle: isLight
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
    );
  }

  // ============================================
  // CARD THEME
  // ============================================

  static CardThemeData _cardTheme({required bool isLight}) {
    return CardThemeData(
      elevation: AppSizes.cardElevation,
      color: isLight ? AppColors.cardLight : AppColors.cardDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: isLight ? AppColors.borderLight : AppColors.borderDark,
          width: AppSizes.borderWidth,
        ),
      ),
      margin: const EdgeInsets.all(AppSizes.spacing8),
    );
  }

  // ============================================
  // ELEVATED BUTTON THEME
  // ============================================

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isLight}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isLight ? AppColors.primaryLight : AppColors.primaryDark,
        foregroundColor: isLight ? AppColors.textOnPrimaryLight : AppColors.textOnPrimaryDark,
        disabledBackgroundColor: isLight ? AppColors.borderLight : AppColors.borderDark,
        disabledForegroundColor: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLG,
          vertical: AppSizes.paddingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================
  // OUTLINED BUTTON THEME
  // ============================================

  static OutlinedButtonThemeData _outlinedButtonTheme({required bool isLight}) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isLight ? AppColors.primaryLight : AppColors.primaryDark,
        disabledForegroundColor: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLG,
          vertical: AppSizes.paddingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
        side: BorderSide(
          color: isLight ? AppColors.primaryLight : AppColors.primaryDark,
          width: AppSizes.borderWidthMD,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================
  // TEXT BUTTON THEME
  // ============================================

  static TextButtonThemeData _textButtonTheme({required bool isLight}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isLight ? AppColors.primaryLight : AppColors.primaryDark,
        disabledForegroundColor: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================
  // INPUT DECORATION THEME
  // ============================================

  static InputDecorationTheme _inputDecorationTheme({required bool isLight}) {
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final focusedColor = isLight ? AppColors.primaryLight : AppColors.primaryDark;
    final errorColor = isLight ? AppColors.errorLight : AppColors.errorDark;
    final fillColor = isLight ? AppColors.cardLight : AppColors.cardDark;
    final hintColor = isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.paddingMD,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontMD,
        color: hintColor,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontMD,
        color: hintColor,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w500,
        color: focusedColor,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        color: errorColor,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: focusedColor, width: AppSizes.borderWidthMD),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: errorColor, width: AppSizes.borderWidthMD),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      ),
    );
  }

  // ============================================
  // FLOATING ACTION BUTTON THEME
  // ============================================

  static FloatingActionButtonThemeData _fabTheme({required bool isLight}) {
    return FloatingActionButtonThemeData(
      backgroundColor: isLight ? AppColors.secondaryLight : AppColors.secondaryDark,
      foregroundColor: isLight ? AppColors.primaryLight : AppColors.textOnPrimaryDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      ),
    );
  }

  // ============================================
  // BOTTOM NAVIGATION BAR THEME
  // ============================================

  static BottomNavigationBarThemeData _bottomNavTheme({required bool isLight}) {
    return BottomNavigationBarThemeData(
      backgroundColor: isLight ? AppColors.cardLight : AppColors.cardDark,
      selectedItemColor: isLight ? AppColors.primaryLight : AppColors.primaryDark,
      unselectedItemColor: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  // ============================================
  // NAVIGATION BAR THEME (Material 3)
  // ============================================

  static NavigationBarThemeData _navigationBarTheme({required bool isLight}) {
    return NavigationBarThemeData(
      backgroundColor: isLight ? AppColors.cardLight : AppColors.cardDark,
      indicatorColor: isLight
          ? AppColors.secondaryLight.withValues(alpha: 0.2)
          : AppColors.secondaryDark.withValues(alpha: 0.2),
      elevation: 0,
      height: AppSizes.bottomNavHeight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: isLight ? AppColors.primaryLight : AppColors.primaryDark,
            size: AppSizes.iconNav,
          );
        }
        return IconThemeData(
          color: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
          size: AppSizes.iconNav,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            fontSize: AppSizes.fontXS,
            fontWeight: FontWeight.w600,
            color: isLight ? AppColors.primaryLight : AppColors.primaryDark,
          );
        }
        return GoogleFonts.inter(
          fontSize: AppSizes.fontXS,
          fontWeight: FontWeight.normal,
          color: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
        );
      }),
    );
  }

  // ============================================
  // DIVIDER THEME
  // ============================================

  static DividerThemeData _dividerTheme({required bool isLight}) {
    return DividerThemeData(
      color: isLight ? AppColors.borderLight : AppColors.borderDark,
      thickness: AppSizes.dividerThickness,
      space: AppSizes.spacing16,
    );
  }

  // ============================================
  // CHIP THEME
  // ============================================

  static ChipThemeData _chipTheme({required bool isLight}) {
    return ChipThemeData(
      backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      selectedColor: isLight
          ? AppColors.secondaryLight.withValues(alpha: 0.2)
          : AppColors.secondaryDark.withValues(alpha: 0.2),
      disabledColor: isLight ? AppColors.borderLight : AppColors.borderDark,
      labelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        color: isLight ? AppColors.primaryLight : AppColors.primaryDark,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        side: BorderSide(
          color: isLight ? AppColors.borderLight : AppColors.borderDark,
        ),
      ),
    );
  }

  // ============================================
  // DIALOG THEME
  // ============================================

  static DialogThemeData _dialogTheme({required bool isLight}) {
    return DialogThemeData(
      backgroundColor: isLight ? AppColors.cardLight : AppColors.cardDark,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusDialog),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontLG,
        fontWeight: FontWeight.w600,
        color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontMD,
        color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
      ),
    );
  }

  // ============================================
  // BOTTOM SHEET THEME
  // ============================================

  static BottomSheetThemeData _bottomSheetTheme({required bool isLight}) {
    return BottomSheetThemeData(
      backgroundColor: isLight ? AppColors.cardLight : AppColors.cardDark,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusBottomSheet),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: isLight ? AppColors.borderLight : AppColors.borderDark,
      dragHandleSize: const Size(
        AppSizes.bottomSheetHandleWidth,
        AppSizes.bottomSheetHandleHeight,
      ),
    );
  }

  // ============================================
  // SNACKBAR THEME
  // ============================================

  static SnackBarThemeData _snackBarTheme({required bool isLight}) {
    return SnackBarThemeData(
      backgroundColor: isLight ? AppColors.textPrimaryLight : AppColors.cardDark,
      contentTextStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        color: isLight ? AppColors.white : AppColors.textPrimaryDark,
      ),
      actionTextColor: isLight ? AppColors.secondaryLight : AppColors.secondaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
    );
  }

  // ============================================
  // TAB BAR THEME
  // ============================================

  static TabBarThemeData _tabBarTheme({required bool isLight}) {
    return TabBarThemeData(
      labelColor: isLight ? AppColors.primaryLight : AppColors.primaryDark,
      unselectedLabelColor: isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark,
      indicatorColor: isLight ? AppColors.primaryLight : AppColors.primaryDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  // ============================================
  // CHECKBOX THEME
  // ============================================

  static CheckboxThemeData _checkboxTheme({required bool isLight}) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isLight ? AppColors.primaryLight : AppColors.primaryDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(
        isLight ? AppColors.textOnPrimaryLight : AppColors.textOnPrimaryDark,
      ),
      side: BorderSide(
        color: isLight ? AppColors.borderLight : AppColors.borderDark,
        width: AppSizes.borderWidthMD,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXS),
      ),
    );
  }

  // ============================================
  // RADIO THEME
  // ============================================

  static RadioThemeData _radioTheme({required bool isLight}) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isLight ? AppColors.primaryLight : AppColors.primaryDark;
        }
        return isLight ? AppColors.borderLight : AppColors.borderDark;
      }),
    );
  }

  // ============================================
  // SWITCH THEME
  // ============================================

  static SwitchThemeData _switchTheme({required bool isLight}) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isLight ? AppColors.primaryLight : AppColors.primaryDark;
        }
        return isLight ? AppColors.tertiaryLight : AppColors.tertiaryDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isLight
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : AppColors.primaryDark.withValues(alpha: 0.3);
        }
        return isLight ? AppColors.borderLight : AppColors.borderDark;
      }),
    );
  }

  // ============================================
  // PROGRESS INDICATOR THEME
  // ============================================

  static ProgressIndicatorThemeData _progressIndicatorTheme({required bool isLight}) {
    return ProgressIndicatorThemeData(
      color: isLight ? AppColors.primaryLight : AppColors.primaryDark,
      linearTrackColor: isLight ? AppColors.borderLight : AppColors.borderDark,
      circularTrackColor: isLight ? AppColors.borderLight : AppColors.borderDark,
    );
  }
}
