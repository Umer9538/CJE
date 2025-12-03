import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// ============================================
/// STRING EXTENSIONS
/// ============================================
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,15}$');
    return phoneRegex.hasMatch(this);
  }

  /// Check if string is a valid password (min 8 chars, 1 uppercase, 1 number)
  bool get isValidPassword {
    if (length < 8) return false;
    final hasUppercase = contains(RegExp(r'[A-Z]'));
    final hasNumber = contains(RegExp(r'[0-9]'));
    return hasUppercase && hasNumber;
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Convert to initials (e.g., "John Doe" -> "JD")
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
  }
}

/// ============================================
/// STRING? (NULLABLE) EXTENSIONS
/// ============================================
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return value or default
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}

/// ============================================
/// DATETIME EXTENSIONS
/// ============================================
extension DateTimeExtensions on DateTime {
  /// Format as "dd MMM yyyy" (e.g., "15 Dec 2024")
  String get formatDate => DateFormat('dd MMM yyyy', 'ro').format(this);

  /// Format as "dd/MM/yyyy" (e.g., "15/12/2024")
  String get formatDateShort => DateFormat('dd/MM/yyyy').format(this);

  /// Format as "HH:mm" (e.g., "14:30")
  String get formatTime => DateFormat('HH:mm').format(this);

  /// Format as "dd MMM yyyy, HH:mm" (e.g., "15 Dec 2024, 14:30")
  String get formatDateTime => DateFormat('dd MMM yyyy, HH:mm', 'ro').format(this);

  /// Format as "EEEE, dd MMMM yyyy" (e.g., "Luni, 15 Decembrie 2024")
  String get formatDateFull => DateFormat('EEEE, dd MMMM yyyy', 'ro').format(this);

  /// Format as relative time (e.g., "Azi", "Ieri", "Acum 2 zile")
  String get formatRelative {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return 'Azi';
    if (difference == 1) return 'Ieri';
    if (difference == -1) return 'Mâine';
    if (difference > 1 && difference <= 7) return 'Acum $difference zile';
    if (difference < -1 && difference >= -7) return 'În ${-difference} zile';
    return formatDate;
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return subtract(Duration(days: daysToSubtract)).startOfDay;
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final daysToAdd = 7 - weekday;
    return add(Duration(days: daysToAdd)).endOfDay;
  }

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Add business days (excluding weekends)
  DateTime addBusinessDays(int days) {
    var result = this;
    var remaining = days;
    while (remaining > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        remaining--;
      }
    }
    return result;
  }
}

/// ============================================
/// NUMBER EXTENSIONS
/// ============================================
extension IntExtensions on int {
  /// Format as duration string (e.g., 90 -> "1h 30m")
  String get formatDuration {
    final hours = this ~/ 60;
    final minutes = this % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Format as file size (e.g., 1024 -> "1 KB")
  String get formatFileSize {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  /// Add leading zeros (e.g., 5.padLeft(2) -> "05")
  String padLeft(int width, [String padding = '0']) {
    return toString().padLeft(width, padding);
  }
}

extension DoubleExtensions on double {
  /// Format as percentage (e.g., 0.756 -> "75.6%")
  String get formatPercentage => '${(this * 100).toStringAsFixed(1)}%';

  /// Format with thousand separators (e.g., 1234567.89 -> "1,234,567.89")
  String formatWithSeparators([int decimals = 2]) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'ro');
    return formatter.format(this);
  }
}

/// ============================================
/// LIST EXTENSIONS
/// ============================================
extension ListExtensions<T> on List<T> {
  /// Get first item or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last item or null if empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Get item at index or null if out of bounds
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Separate list into chunks
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
}

/// ============================================
/// CONTEXT EXTENSIONS
/// ============================================
extension BuildContextExtensions on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get view insets (keyboard, etc.)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Get current theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get current locale
  Locale get locale => Localizations.localeOf(this);

  /// Get localized strings (AppLocalizations)
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }

  /// Hide current snackbar
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  /// Check if Navigator can pop (use GoRouter's pop() for navigation)
  bool get canNavigatorPop => Navigator.of(this).canPop();
}

/// ============================================
/// COLOR EXTENSIONS
/// ============================================
extension ColorExtensions on Color {
  /// Get color with different opacity
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);

  /// Darken color by percentage
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lighten color by percentage
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

  /// Convert to hex string
  String toHex({bool includeHash = true}) {
    final hex = toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return includeHash ? '#$hex' : hex;
  }
}
