import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/app_logger.dart';

/// Real push notifications, delivered even when the app is closed —
/// unlike [UrgentCasesBanner], which only shows something while the app
/// is open. The device's FCM token is stored on the user's own profile
/// doc (users/{uid}.fcmTokens, an array — a doctor may have more than one
/// device signed in); a Cloud Function (see /functions) reads it and
/// calls the FCM Admin API when:
///   - a patient is auto/manually flagged urgent (notifies the owning
///     doctor), or
///   - a mentor leaves feedback on a submitted case (notifies the
///     student who submitted it).
///
/// This class only handles the client side: asking for permission,
/// keeping the token in Firestore up to date, and showing a lightweight
/// in-app banner for messages that arrive while the app is already open
/// (Android/iOS don't surface a system notification for foreground
/// messages by default).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;

  /// Foreground messages, exposed as a stream so a widget higher up the
  /// tree (e.g. MainShell) can show an in-app banner/snackbar for them.
  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  Future<void> init() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      AppLogger.d('Push permission: ${settings.authorizationStatus}');

      await _saveCurrentToken();
      _messaging.onTokenRefresh.listen((_) => _saveCurrentToken());
    } catch (e) {
      // Permission denied, or running somewhere push isn't supported
      // (e.g. a simulator without the right entitlements) — never let
      // this block app startup.
      AppLogger.e('Push notification init failed', error: e);
    }
  }

  Future<void> _saveCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.e('Failed to save FCM token', error: e);
    }
  }

  /// Call on logout so a signed-out device stops receiving another
  /// doctor's notifications once someone else signs into the same app
  /// install.
  Future<void> removeCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      AppLogger.e('Failed to remove FCM token', error: e);
    }
  }
}
