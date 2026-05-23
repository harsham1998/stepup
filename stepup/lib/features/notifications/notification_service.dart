import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler — must be top-level function
  debugPrint('Background FCM message: ${message.messageId}');
}

class NotificationService {
  static Future<void> initialise() async {
    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);
      messaging.onTokenRefresh.listen(_saveToken);
    }

    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('Foreground FCM: ${msg.notification?.title}');
    });
  }

  static Future<void> _saveToken(String token) async {
    try {
      await ApiClient.instance.put('/auth/profile', {'fcm_token': token});
    } catch (_) {}
  }
}
