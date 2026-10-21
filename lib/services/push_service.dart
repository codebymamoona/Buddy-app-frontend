import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  static bool _started = false;
  static StreamSubscription<String>? _refreshSub;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _hitlChannel = AndroidNotificationChannel(
    'hitl_approvals',
    'Approval requests',
    description: 'Orders and bookings waiting for your approval',
    importance: Importance.high,
  );

  static Future<void> _setupChannel() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_hitlChannel);
    } catch (e) {
      debugPrint('channel setup failed: $e');
    }
  }

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final fcm = FirebaseMessaging.instance;
      final settings = await fcm.requestPermission();
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      await _setupChannel();          // <-- the new line

      final token = await fcm.getToken();
      debugPrint('FCM token present: ${token != null}');
      if (token != null) await _register(token);
      await _refreshSub?.cancel();
      _refreshSub = fcm.onTokenRefresh.listen(_register);
    } catch (e) {
      debugPrint('PushService.init failed: $e');
      _started = false;
    }
  }

  static Future<void> _register(String token) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    for (var attempt = 1; attempt <= 5; attempt++) {
      if (await ApiService().updateFcmToken(token)) {
        debugPrint('FCM register: SUCCESS (backend returned 200)');
        return;
      }
      debugPrint('FCM register: attempt $attempt failed, retrying');
      await Future.delayed(Duration(seconds: 3 * attempt));
    }
    debugPrint('FCM register: GAVE UP after 5 attempts');
  }

  static Future<void> reset() async {
    _started = false;
    await _refreshSub?.cancel();
    _refreshSub = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}