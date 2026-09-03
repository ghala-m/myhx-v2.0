import 'package:flutter/services.dart';

/// Data entry is English-only for now; Arabic is produced automatically by
/// the translation layer when the app language is switched.
class EnglishInput {
  EnglishInput._();

  /// Blocks Arabic (and other non-Latin) characters while typing.
  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.deny(RegExp(r'[\u0600-\u06FF\u0750-\u077F]')),
  ];

  static bool isEnglish(String text) =>
      !RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  static String? validate(String? value, {bool arabicUi = false}) {
    if (value == null || value.trim().isEmpty) return null;
    if (isEnglish(value)) return null;
    return arabicUi
        ? 'الرجاء الإدخال بالإنجليزية — سيتم الترجمة تلقائياً'
        : 'Please type in English — Arabic is generated automatically';
  }
}
