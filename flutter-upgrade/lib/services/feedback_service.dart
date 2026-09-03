import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central place for the app's motion, sound and haptic feedback.
/// Every channel can be switched off individually from Settings.
class FeedbackService with ChangeNotifier {
  static const _kSound = 'fx_sound';
  static const _kHaptics = 'fx_haptics';
  static const _kMotion = 'fx_motion';

  bool _sound = true;
  bool _haptics = true;
  bool _motion = true;

  bool get soundEnabled => _sound;
  bool get hapticsEnabled => _haptics;
  bool get motionEnabled => _motion;

  Duration get fast =>
      _motion ? const Duration(milliseconds: 180) : Duration.zero;
  Duration get normal =>
      _motion ? const Duration(milliseconds: 320) : Duration.zero;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sound = prefs.getBool(_kSound) ?? true;
    _haptics = prefs.getBool(_kHaptics) ?? true;
    _motion = prefs.getBool(_kMotion) ?? true;
    notifyListeners();
  }

  Future<void> setSound(bool v) => _set(_kSound, v, () => _sound = v);
  Future<void> setHaptics(bool v) => _set(_kHaptics, v, () => _haptics = v);
  Future<void> setMotion(bool v) => _set(_kMotion, v, () => _motion = v);

  Future<void> _set(String key, bool value, VoidCallback apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ---- effects -------------------------------------------------------

  void tap() {
    if (_haptics) HapticFeedback.selectionClick();
    if (_sound) SystemSound.play(SystemSoundType.click);
  }

  void success() {
    if (_haptics) HapticFeedback.lightImpact();
    if (_sound) SystemSound.play(SystemSoundType.click);
  }

  void warning() {
    if (_haptics) HapticFeedback.mediumImpact();
    if (_sound) SystemSound.play(SystemSoundType.alert);
  }

  void error() {
    if (_haptics) HapticFeedback.heavyImpact();
    if (_sound) SystemSound.play(SystemSoundType.alert);
  }
}
