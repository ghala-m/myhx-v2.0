import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(ThemeMode dark); // الوضع الافتراضي هو اتباع النظام

  ThemeMode get themeMode => _themeMode;

  // دالة لتغيير الثيم
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners(); // هذا السطر يخبر كل أجزاء التطبيق أن الثيم قد تغير
  }
}
