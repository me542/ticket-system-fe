// lib/core/utils/validators.dart
class Validators {
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return "Enter a valid email";
    return null;
  }

  // Validate password (min 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  // Validate name (letters only)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return "Name is required";
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) return "Name can only contain letters";
    return null;
  }

  // Validate phone number (numbers only, 10-15 digits)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";
    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (!phoneRegex.hasMatch(value)) return "Enter a valid phone number";
    return null;
  }

  // Validate ticket title (non-empty)
  static String? validateTicketTitle(String? value) {
    if (value == null || value.isEmpty) return "Ticket title is required";
    return null;
  }

  // Validate ticket description (non-empty)
  static String? validateTicketDescription(String? value) {
    if (value == null || value.isEmpty) return "Ticket description is required";
    return null;
  }

  // Confirm password matches
  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) return "Please confirm your password";
    if (password != confirm) return "Passwords do not match";
    return null;
  }
}
