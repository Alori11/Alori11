import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value != password) {
      return AppStrings.passwordsNotMatch;
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final cleaned = value.trim().replaceAll(' ', '').replaceAll('-', '');
    // Saudi phone: +966xxxxxxxxx or 05xxxxxxxx or 966xxxxxxxxx
    final saudiRegex = RegExp(r'^(\+966|966|0)5[0-9]{8}$');
    if (!saudiRegex.hasMatch(cleaned)) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.trim().length < 2) {
      return AppStrings.nameTooShort;
    }
    return null;
  }

  static String? validateIMEI(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final cleaned = value.trim().replaceAll(' ', '');
    if (cleaned.length != 15 || !RegExp(r'^\d{15}$').hasMatch(cleaned)) {
      return AppStrings.invalidImei;
    }
    return null;
  }

  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  static String? validateMileage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'يرجى إدخال رقم صحيح';
    }
    return null;
  }

  static String? validateCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'يرجى إدخال مبلغ صحيح';
    }
    return null;
  }
}
