class Validators {
  static String? validateBahrainPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces or special characters
    final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Check if it's exactly 8 digits
    if (cleanNumber.length != 8) {
      return 'Phone number must be 8 digits';
    }

    // Check if it starts with valid Bahrain mobile prefixes
    final validPrefixes = ['3', '6'];
    if (!validPrefixes.contains(cleanNumber[0])) {
      return 'Invalid Bahrain mobile number';
    }

    return null;
  }

  static String formatBahrainPhoneNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return '+973$cleanNumber';
  }

  static String extractLocalNumber(String fullNumber) {
    return fullNumber.replaceAll('+973', '');
  }
}
