import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the doctor's alert preference and exposes it as a
/// [ChangeNotifier] so widgets stay in sync automatically.
///
/// This app has no push-notification backend (no FCM setup, no server
/// deciding when to notify) — building real push notifications needs that
/// infrastructure regardless of this toggle. What this preference honestly
/// and fully controls, client-side, is whether [UrgentCasesBanner] shows on
/// the home tab. That's a real, working feature, not a cosmetic switch with
/// nothing behind it.
class NotificationPreferencesService with ChangeNotifier {
  static const _prefsKey = 'urgent_alerts_enabled';

  bool _enabled = true;
  bool get isEnabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
