import 'package:flutter/material.dart';
import 'colors.dart'; // يعتمد على ملف الألوان الأصلي الخاص بك

class AppTheme {
  // --- الثيم الفاتح ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryTeal,
      // --- التصحيح هنا ---
      scaffoldBackgroundColor: AppColors.background, // استخدم 'background' بدلاً من 'backgroundLight'
      fontFamily: 'Roboto',
      cardColor: AppColors.surface, // استخدم 'surface' بدلاً من 'surfaceLight'
      dividerColor: AppColors.border, // استخدم 'border' بدلاً من 'borderLight'
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // --- التصحيح هنا ---
        iconTheme: IconThemeData(color: AppColors.textPrimary), // استخدم 'textPrimary' بدلاً من 'textPrimaryLight'
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary, // استخدم 'textPrimary' بدلاً من 'textPrimaryLight'
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryTeal,
        secondary: AppColors.primaryCyan,
        surface: AppColors.surface, // استخدم 'surface' بدلاً من 'surfaceLight'
        background: AppColors.background, // استخدم 'background' بدلاً من 'backgroundLight'
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary, // استخدم 'textPrimary' بدلاً من 'textPrimaryLight'
        onBackground: AppColors.textPrimary, // استخدم 'textPrimary' بدلاً من 'textPrimaryLight'
        onError: Colors.white,
      ),
    );
  }

  // --- الثيم الداكن ---
  static ThemeData get darkTheme {
    // ملاحظة: ملف الألوان الأصلي لا يحتوي على ألوان مخصصة للوضع الداكن.
    // لذا، سنستخدم ألوانًا داكنة قياسية مؤقتًا.
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryTeal,
      scaffoldBackgroundColor: const Color(0xFF121212), // لون داكن قياسي
      fontFamily: 'Roboto',
      cardColor: const Color(0xFF1E1E1E), // لون داكن قياسي
      dividerColor: Colors.grey[800], // لون داكن قياسي
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // أبيض للوضع الداكن
        titleTextStyle: TextStyle(
          color: Colors.white, // أبيض للوضع الداكن
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryTeal,
        secondary: AppColors.primaryCyan,
        surface: Color(0xFF1E1E1E), // لون داكن قياسي
        background: Color(0xFF121212), // لون داكن قياسي
        error: AppColors.error,
        onPrimary: Colors.black, // نص أسود على الأزرار الأساسية
        onSecondary: Colors.black,
        onSurface: Colors.white, // نص أبيض على الأسطح الداكنة
        onBackground: Colors.white, // نص أبيض على الخلفية الداكنة
        onError: Colors.white,
      ),
    );
  }
}
