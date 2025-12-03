import '../constants/app_strings.dart';

/// CJE Platform Form Validators
/// Validation functions for form fields
class Validators {
  Validators._();

  /// Validate email field
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  /// Validate password field
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Parola trebuie să conțină cel puțin o literă mare';
    }
    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Parola trebuie să conțină cel puțin o cifră';
    }
    return null;
  }

  /// Validate confirm password field
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.passwordRequired;
      }
      if (value != password) {
        return AppStrings.passwordsDoNotMatch;
      }
      return null;
    };
  }

  /// Validate name field
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.nameRequired;
    }
    if (value.length < 2) {
      return 'Numele trebuie să aibă cel puțin 2 caractere';
    }
    if (value.length > 100) {
      return 'Numele nu poate avea mai mult de 100 de caractere';
    }
    return null;
  }

  /// Validate phone field
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.phoneRequired;
    }
    // Remove spaces, dashes, and parentheses for validation
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Romanian phone number validation
    final phoneRegex = RegExp(r'^(\+40|0)[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      return AppStrings.phoneInvalid;
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName este obligatoriu'
          : AppStrings.fieldRequired;
    }
    return null;
  }

  /// Validate school selection
  static String? school(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.schoolRequired;
    }
    return null;
  }

  /// Validate city selection
  static String? city(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.cityRequired;
    }
    return null;
  }

  /// Validate city password
  static String? cityPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.cityPasswordRequired;
    }
    return null;
  }

  /// Validate minimum length
  static String? Function(String?) minLength(int min, [String? message]) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.fieldRequired;
      }
      if (value.length < min) {
        return message ?? 'Trebuie să aibă cel puțin $min caractere';
      }
      return null;
    };
  }

  /// Validate maximum length
  static String? Function(String?) maxLength(int max, [String? message]) {
    return (String? value) {
      if (value != null && value.length > max) {
        return message ?? 'Nu poate avea mai mult de $max caractere';
      }
      return null;
    };
  }

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return 'URL-ul nu este valid';
    }
    return null;
  }

  /// Validate date (must be in the future)
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return AppStrings.fieldRequired;
    }
    if (value.isBefore(DateTime.now())) {
      return 'Data trebuie să fie în viitor';
    }
    return null;
  }

  /// Validate date (must be in the past)
  static String? pastDate(DateTime? value) {
    if (value == null) {
      return AppStrings.fieldRequired;
    }
    if (value.isAfter(DateTime.now())) {
      return 'Data trebuie să fie în trecut';
    }
    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Check if string is a valid email
  static bool isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }
}
