class AppValidators {
  // Validates email/phone format
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';

    // Check if it's a valid email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (emailRegex.hasMatch(value)) {
      return null; // Valid email
    }

    // Check if it's a valid phone number (digits only, at least 10 digits)
    final phoneRegex = RegExp(r'^\d{10,}$');
    if (phoneRegex.hasMatch(value)) {
      return null; // Valid phone number
    }

    return 'Enter a valid email or phone number';
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (RegExp(r'^\d').hasMatch(value)) {
      return 'Name cannot start with a number';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    // Phone number is optional - allow null or empty
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Check if only digits are entered
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Phone number must contain only digits';
    }

    if (value.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
