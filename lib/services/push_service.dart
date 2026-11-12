import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';
import 'app_signals.dart';

/// FCM registration + notification routing.
///
///  - HITL_APPROVAL pushes   -> refresh Approve/Audit, tap opens the Approve tab
///  - BIRTHDAY_REMINDER push -> tap opens Chat with a "want gift ideas?" notice (no order is created)
///  Foreground pushes are re-shown as heads-up local notifications; background/terminated taps are
///  handled via onMessageOpenedApp / getInitialMessage.
class PushService {
  static const String _approvalType = 'HITL_APPROVAL';
  static const String _reminderType = 'BIRTHDAY_REMINDER';
  static const String _expiredType = 'APPROVAL_EXPIRED';

  /// Must match the title NotificationService.sendHitlApprovalPush sets on the backend.
  static const String _approvalPushTitle = 'Buddy AI: Approval Required';

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _approvalChannel = AndroidNotificationChannel(
    'hitl_approvals',
    'Approval requests',
    description: 'Orders and bookings waiting for your approval',
    importance: Importance.high,
  );

  /// The id must match ReminderNotificationService.REMINDER_CHANNEL_ID on the backend.
  static const AndroidNotificationChannel _reminderChannel = AndroidNotificationChannel(
    'buddy_reminders',
    'Reminders',
    description: 'Birthday and other proactive reminders from Buddy',
    importance: Importance.high,
  );

  static bool _started = false;
  static bool _localReady = false;
  static StreamSubscription<String>? _tokenSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<RemoteMessage>? _openedSub;

  // ---- "open Approve tab" requests ----
  static final ValueNotifier<int> openApprovalRequests = ValueNotifier<int>(0);
  static bool _openPending = false;

  /// True exactly once if a notification tap is waiting to open the Approve tab.
  static bool consumeOpenRequest() {
    final v = _openPending;
    _openPending = false;
    return v;
  }

  static void _requestOpenApproval() {
    _openPending = true;
    openApprovalRequests.value++;
    AppSignals.refreshApprovals();
    AppSignals.refreshAudit();
  }

  // ---- "open Chat with a reminder notice" requests ----
  static final ValueNotifier<int> openChatRequests = ValueNotifier<int>(0);
  static String? _pendingChatNotice;

  /// The notice text for a tapped reminder, or null. Returns it once.
  static String? consumeChatNotice() {
    final v = _pendingChatNotice;
    _pendingChatNotice = null;
    return v;
  }

  static void _requestOpenChat(Map<String, dynamic> data) {
    if (data['type'] == _expiredType) {
      // Already put in the chat by the foreground handler? Then do not post it a second time.
      if (!_announceExpiry(data)) return;
      _pendingChatNotice = _expiredText(data);
    } else {
      _pendingChatNotice = _reminderText(data);
    }
    openChatRequests.value++;
  }

  static final Set<String> _announcedExpiries = <String>{};

  /// True the first time an expired action is announced in this app run.
  static bool _announceExpiry(Map<String, dynamic> data) {
    final id = (data['actionId'] ?? '').toString();
    if (id.isEmpty) return true;
    return _announcedExpiries.add(id);
  }

  /// Informational only: it never re-orders. The user has to ask again themselves.
  static String _expiredText(Map<String, dynamic> data) {
    final item = (data['itemName'] ?? '').toString().trim();
    final brand = (data['brand'] ?? '').toString().trim();
    final what = item.isEmpty ? 'your order' : (brand.isEmpty ? item : '$item from $brand');
    return 'The approval window for $what ran out, so nothing was ordered. '
        'If you still want it, just ask me again.';
  }

  static String _reminderText(Map<String, dynamic> data) {
    final name = (data['contactName'] ?? 'Your friend').toString();
    final days = int.tryParse('${data['daysUntil']}') ?? -1;
    final when = days == 0
        ? 'is today'
        : days == 1
        ? 'is tomorrow'
        : days > 1
        ? 'is in $days days'
        : 'is coming up';
    return "$name's birthday $when. Want gift ideas? Just say \"gift for $name\".";
  }

  static void _route(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == _approvalType) {
      _requestOpenApproval();
    } else if (type == _reminderType || type == _expiredType) {
      if (type == _expiredType) {
        AppSignals.refreshApprovals();
        AppSignals.refreshAudit();
      }
      _requestOpenChat(data);
    }
  }

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      await _setupChannels();

      await _tokenSub?.cancel();
      await _foregroundSub?.cancel();
      await _openedSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((m) => _route(m.data));

      // App was launched by tapping a push while terminated.
      final initial = await fm.getInitialMessage();
      if (initial != null) _route(initial.data);

      final token = await fm.getToken();
      if (token != null) {
        await _register(token);
      } else {
        debugPrint('FCM: getToken returned null');
      }
      _tokenSub = fm.onTokenRefresh.listen(_register);
    } catch (e) {
      debugPrint('FCM init failed: $e');
      _started = false; // allow a later retry
    }
  }

  static Future<void> _setupChannels() async {
    if (_localReady) return;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) _route(Map<String, dynamic>.from(decoded));
          } catch (_) {
            // not a payload we created; ignore
          }
        },
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_approvalChannel);
      await android?.createNotificationChannel(_reminderChannel);
      _localReady = true;
    } catch (e) {
      debugPrint('Local notification setup failed: $e');
    }
  }

  static Future<void> _onForeground(RemoteMessage m) async {
    final type = m.data['type'];
    if (type == _approvalType) {
      // Refresh so the Approve tab and badge are never stale while the app is open.
      AppSignals.refreshApprovals();
      AppSignals.refreshAudit();
      // The push can arrive a few seconds AFTER you already decided inside the app. Posting it then would
      // leave a stale notification that nothing ever clears, so only alert if something is still waiting.
      var stillPending = true; // if we cannot tell, alert (a spurious alert beats a missed one)
      try {
        stillPending = (await ApiService().getPendingActions()).isNotEmpty;
      } catch (_) {}
      if (stillPending) {
        await _showLocal(m, _approvalChannel, 'Approval needed',
            'Buddy drafted an action that needs your approval.');
      }
    } else if (type == _reminderType) {
      await _showLocal(m, _reminderChannel, 'Birthday coming up', 'Want gift ideas?');
    } else if (type == _expiredType) {
      // The app is open: drop the dead card, record it in Audit, and leave the explanation waiting in the chat.
      AppSignals.refreshApprovals();
      AppSignals.refreshAudit();
      if (_announceExpiry(m.data)) AppSignals.notifyChat(_expiredText(m.data));
      await _showLocal(m, _reminderChannel, 'Approval expired', 'An approval timed out. Nothing was ordered.');
    }
  }

  static Future<void> _showLocal(
      RemoteMessage m, AndroidNotificationChannel channel, String fallbackTitle, String fallbackBody) async {
    if (!_localReady) return;
    final n = m.notification;
    try {
      await _local.show(
        id: int.tryParse('${m.data['actionId']}') ?? m.hashCode, // the order's own id, so a decision can cancel exactly this one
        title: n?.title ?? fallbackTitle,
        body: n?.body ?? fallbackBody,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(m.data),
      );
    } catch (e) {
      debugPrint('Foreground notification failed: $e');
    }
  }

  /// Cancels the notification for ONE order the moment it is decided. Exact, no guessing by channel or title.
  static Future<void> cancelApprovalNotification(int actionId) async {
    if (!_localReady) return;
    try {
      // 1. A heads-up WE drew while the app was open: its id is the order id.
      await _local.cancel(id: actionId);
      // 2. One Android drew from the push while the app was in the background: the backend tags it "approval-<id>".
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final active = await android?.getActiveNotifications() ?? const <ActiveNotification>[];
      for (final n in active) {
        if (n.tag == 'approval-$actionId' && n.id != null) {
          await _local.cancel(id: n.id!, tag: n.tag);
        }
      }
      debugPrint('NOTIF cancel done for action $actionId (${active.length} active)');
    } catch (e) {
      debugPrint('Cancelling approval notification $actionId failed: $e');
    }
  }

  /// Removes approval notifications from the shade once nothing is waiting for approval,
  /// so a resolved request never leaves a stale notification behind.
  /// (If other approvals are still pending, the notifications stay, since we cannot tell which belongs to which.)
  static Future<void> syncApprovalNotifications(int pendingCount) async {
    if (pendingCount > 0 || !_localReady) return;
    try {
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final active = await android?.getActiveNotifications() ?? const <ActiveNotification>[];
      for (final n in active) {
        debugPrint('NOTIF active: id=${n.id} tag=${n.tag} channel=${n.channelId} title=${n.title}');
        final id = n.id;
        // Pushes that arrived while the app was in the background are drawn by Android on a default channel,
        // so match on the backend's fixed title as well as on our own channel.
        final isApproval = n.channelId == _approvalChannel.id || n.title == _approvalPushTitle;
        if (isApproval && id != null) {
          await _local.cancel(id: id, tag: n.tag);
        }
      }
    } catch (e) {
      debugPrint('Clearing approval notifications failed: $e');
    }
  }

  static Future<void> _register(String token) async {
    for (var attempt = 1; attempt <= 5; attempt++) {
      try {
        final ok = await ApiService().updateFcmToken(token);
        if (ok) {
          debugPrint('FCM register: SUCCESS');
          return;
        }
        debugPrint('FCM register: server rejected token (attempt $attempt)');
      } catch (e) {
        debugPrint('FCM register error (attempt $attempt): $e');
      }
      await Future.delayed(Duration(seconds: attempt * 2));
    }
    debugPrint('FCM register: gave up after 5 attempts');
    _started = false; // next auth event / app start can retry
  }

  /// Call on logout: stop listeners and drop this device's token so the next user doesn't receive it.
  static Future<void> reset() async {
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenSub = _foregroundSub = _openedSub = null;
    _started = false;
    _openPending = false;
    _pendingChatNotice = null;
    _announcedExpiries.clear();
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FCM deleteToken failed: $e');
    }
  }
}