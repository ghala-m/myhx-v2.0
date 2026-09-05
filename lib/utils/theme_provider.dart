import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

/// Manages the app's theme mode (light / dark / system) and the selected
/// colour palette, persisting both between sessions.
class ThemeProvider with ChangeNotifier {
  static const _kMode = 'theme_mode';
  static const _kPalette = 'theme_palette';

  ThemeMode _themeMode;
  AppPalette _palette = AppPalettes.teal;

  ThemeProvider([ThemeMode initialMode = ThemeMode.system])
      : _themeMode = initialMode;

  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;

  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_kMode);
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _palette = AppPalettes.byId(prefs.getString(_kPalette));
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _persistMode();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  void setPalette(AppPalette palette) {
    if (_palette.id == palette.id) return;
    _palette = palette;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString(_kPalette, palette.id));
  }

  void _persistMode() {
    final value = switch (_themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    SharedPreferences.getInstance().then((p) => p.setString(_kMode, value));
  }
}
