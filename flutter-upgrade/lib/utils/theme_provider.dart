import 'package:flutter/material.dart';

/// Manages the app's theme mode (light / dark / system).
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider([ThemeMode initialMode = ThemeMode.system]) : _themeMode = initialMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
