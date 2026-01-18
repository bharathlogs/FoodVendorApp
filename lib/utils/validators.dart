/// Validation utilities for form fields
class Validators {
  /// Validate email address
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validate password with strength requirements
  static String? passwordStrong(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate name field
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  /// Validate phone number (optional)
  static String? phoneOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove spaces, dashes, and parentheses for validation
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Allow formats: +1234567890, 1234567890
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate phone number (required)
  static String? phoneRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    return phoneOptional(value);
  }

  /// Validate required field
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int min, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }

    return null;
  }

  /// Validate password confirmation matches
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }

      if (value != password) {
        return 'Passwords do not match';
      }

      return null;
    };
  }

  /// Validate business name
  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }

    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Business name must be under 100 characters';
    }

    // Check for potentially malicious content
    if (_containsHtmlOrScript(value)) {
      return 'Invalid characters detected';
    }

    return null;
  }

  /// Validate description field
  static String? description(String? value, {int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return null; // Description is optional
    }

    if (value.length > maxLength) {
      return 'Description must be under $maxLength characters';
    }

    if (_containsHtmlOrScript(value)) {
      return 'Invalid characters detected';
    }

    return null;
  }

  /// Check for HTML tags or script content
  static bool _containsHtmlOrScript(String value) {
    return RegExp(r'<[^>]*>|javascript:|on\w+=', caseSensitive: false)
        .hasMatch(value);
  }
}

/// Validators specific to menu items
class MenuItemValidators {
  /// Validate menu item name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Name must be under 100 characters';
    }

    // Sanitize HTML/script injection
    if (RegExp(r'<[^>]*>|javascript:|on\w+=', caseSensitive: false)
        .hasMatch(value)) {
      return 'Invalid characters detected';
    }

    return null;
  }

  /// Validate menu item price
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Please enter a valid number';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price > 99999) {
      return 'Price must be under 99,999';
    }

    return null;
  }

  /// Validate menu item description (optional)
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }

    if (value.length > 200) {
      return 'Description must be under 200 characters';
    }

    // Sanitize HTML/script injection
    if (RegExp(r'<[^>]*>|javascript:|on\w+=', caseSensitive: false)
        .hasMatch(value)) {
      return 'Invalid characters detected';
    }

    return null;
  }
}
