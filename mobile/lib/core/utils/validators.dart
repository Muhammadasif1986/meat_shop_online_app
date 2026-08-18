class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.length != 6) return 'Enter a valid 6-digit OTP';
    if (int.tryParse(value) == null) return 'OTP must be numeric';
    return null;
  }
}
