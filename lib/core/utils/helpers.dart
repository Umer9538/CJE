import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// CJE Platform Helper Functions
/// Common utility functions used throughout the app
class Helpers {
  Helpers._();

  // ============================================
  // PLATFORM HELPERS
  // ============================================

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if running on mobile (iOS or Android)
  static bool get isMobile => isIOS || isAndroid;

  // ============================================
  // UI HELPERS
  // ============================================

  /// Hide keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Set system UI overlay style for light status bar
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  /// Set system UI overlay style for dark status bar
  static void setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  /// Set preferred orientations
  static Future<void> setPreferredOrientations({
    bool portraitOnly = true,
  }) async {
    if (portraitOnly) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  // ============================================
  // COLOR HELPERS
  // ============================================

  /// Get color from hex string
  static Color colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Get contrasting text color (black or white)
  static Color getContrastingColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? AppColors.black : AppColors.white;
  }

  // ============================================
  // STRING HELPERS
  // ============================================

  /// Generate initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
  }

  /// Mask email (e.g., "john.doe@example.com" -> "jo***@example.com")
  static String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return '***@$domain';
    }
    return '${name.substring(0, 2)}***@$domain';
  }

  /// Mask phone number (e.g., "0721234567" -> "****234567")
  static String maskPhone(String phone) {
    if (phone.length < 6) return phone;
    final visiblePart = phone.substring(phone.length - 6);
    return '****$visiblePart';
  }

  // ============================================
  // DEBOUNCE & THROTTLE
  // ============================================

  /// Debounce a function call
  static Function() debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    DelayedCallback? timer;
    return () {
      timer?.cancel();
      timer = DelayedCallback(duration, callback);
    };
  }

  // ============================================
  // FILE HELPERS
  // ============================================

  /// Get file extension from path
  static String getFileExtension(String path) {
    final parts = path.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Get file name from path
  static String getFileName(String path) {
    return path.split('/').last;
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String path) {
    final fileName = getFileName(path);
    final lastDot = fileName.lastIndexOf('.');
    return lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
  }

  /// Check if file is an image
  static bool isImageFile(String path) {
    final ext = getFileExtension(path);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Check if file is a document
  static bool isDocumentFile(String path) {
    final ext = getFileExtension(path);
    return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']
        .contains(ext);
  }

  // ============================================
  // RESPONSIVE HELPERS
  // ============================================

  /// Check if screen is mobile size
  static bool isMobileScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is tablet size
  static bool isTabletScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if screen is desktop size
  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Get responsive value based on screen size
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktopScreen(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTabletScreen(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Simple debounce timer class
/// Named DelayedCallback to avoid conflict with dart:async Timer
class DelayedCallback {
  final Duration duration;
  final VoidCallback callback;
  bool _cancelled = false;

  DelayedCallback(this.duration, this.callback) {
    Future.delayed(duration, () {
      if (!_cancelled) callback();
    });
  }

  void cancel() {
    _cancelled = true;
  }
}
