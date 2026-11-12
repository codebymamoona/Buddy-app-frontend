import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/foundation.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';
import 'config/app_mode.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/approval_screen.dart';
import 'screens/friend_profile_screen.dart';
import 'screens/audit_trail_screen.dart';
//import 'screens/gift_recommendation_screen.dart';
import 'screens/settings_screen.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/app_signals.dart';

StreamSubscription? _overlaySubscription;
// The plugin's stream may only be listened to once per process; wrap it once so HomeTabs can re-listen after logout/login.
final Stream<dynamic> _overlayEvents = FlutterOverlayWindow.overlayListener.asBroadcastStream();

/// Top-level entry point for the floating Chat Head overlay
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: ChatBubbleOverlay(),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppMode.useMock && kReleaseMode) {
    throw StateError('USE_MOCK must never be enabled in a release build.');
  }
  if (!AppMode.useMock) {
    await Firebase.initializeApp();
  }
  runApp(const BuddyApp());
}

/// Floating Robot Bubble Widget with Mini Inline Quick Reply & Keyboard Support
class ChatBubbleOverlay extends StatefulWidget {
  const ChatBubbleOverlay({super.key});

  @override
  State<ChatBubbleOverlay> createState() => _ChatBubbleOverlayState();
}

class _ChatBubbleOverlayState extends State<ChatBubbleOverlay> {
  int _pendingCount = 0;
  bool _isExpanded = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen for badge counts sent from the main application isolate
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (mounted) {
        if (data is int) {
          setState(() => _pendingCount = data);
        } else if (data == "SHOW_APPROVAL_BADGE") {
          setState(() => _pendingCount += 1);
        } else if (data == "CLEAR_BADGE") {
          setState(() => _pendingCount = 0);
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendQuickReply() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Send the message to the main app isolate
    await FlutterOverlayWindow.shareData("QUICK_REPLY:$text");
    _textController.clear();

    await Future.delayed(const Duration(milliseconds: 150));
    await _collapseOverlay();
  }

  void _expandOverlay() async {
    // 1. Resize overlay window to fit the quick input card
    await FlutterOverlayWindow.resizeOverlay(280, 320, true);

    // 2. Enable pointer focus flag so Android opens the soft keyboard
    await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);

    if (mounted) {
      setState(() => _isExpanded = true);
      // 3. Request focus on the text field after render frame
      Future.delayed(const Duration(milliseconds: 100), () {
        _focusNode.requestFocus();
      });
    }
  }

  Future<void> _collapseOverlay() async {
    // 1. Dismiss focus and soft keyboard
    _focusNode.unfocus();

    // 2. Reset flag so touches outside pass through
    await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);

    // 3. Shrink window back to compact bubble size
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);

    if (mounted) setState(() => _isExpanded = false);
  }

  void _openFullApp() async {
    try {
      final channel = MethodChannel('com.example.budyy_app/app_retain');
      await channel.invokeMethod('bringToForeground');
    } catch (e) {
      debugPrint("Failed to launch main activity: $e");
    }

    if (_pendingCount > 0) {
      await FlutterOverlayWindow.shareData("OPEN_APPROVAL");
    } else {
      await FlutterOverlayWindow.shareData("OPEN_CHAT");
    }

    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: _isExpanded ? _buildExpandedCard() : _buildCompactBubble(),
      ),
    );
  }

  // --- 1. Compact Robot Bubble View ---
  Widget _buildCompactBubble() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _expandOverlay, // Tap to expand into mini quick reply
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Circular Robot Bubble
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded, // 🤖 Robot Icon
              color: Colors.white,
              size: 30,
            ),
          ),

          // Red Dynamic Number Badge
          if (_pendingCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 22,
                  minHeight: 22,
                ),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _pendingCount > 99 ? '99+' : '$_pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 2. Expanded Floating Mini Card View ---
  Widget _buildExpandedCard() {
    return SingleChildScrollView(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Quick Ask Buddy',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                  tooltip: 'Open Full App',
                  onPressed: _openFullApp,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _collapseOverlay,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Inline Text Field
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type a fast message...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onTap: () async {
                // Reinforce window focus on direct text tap
                await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
                _focusNode.requestFocus();
              },
              onSubmitted: (_) => _sendQuickReply(),
            ),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _collapseOverlay,
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _sendQuickReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Send', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class BuddyApp extends StatelessWidget {
  const BuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buddy',
      builder: (context, child) => AppMode.useMock
          ? Banner(message: 'MOCK', location: BannerLocation.topEnd, child: child)
          : child!,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppMode.useMock
          ? (AppMode.start == 'login'
          ? LoginScreen(onLoginSuccess: (_) {})
          : HomeTabs(userEmail: 'demo@buddy.app', onLogout: () {}))
          : const AuthGate(),
    );
  }
}

/// Decides whether to show Login, Preferences, or the main app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSub;
  User? _user;
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _authReady = true;
      });
      if (user != null) {
        PushService.init();    // fires for fresh login AND restored sessions
      } else {
        PushService.reset();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = _user;
    if (user == null) {
      return LoginScreen(onLoginSuccess: (_) {});
    }
    // email can be null for phone or anonymous accounts; the old code crashed on user.email!
    final label = user.email ?? user.displayName ?? user.uid;
    return HomeTabs(
      key: ValueKey(user.uid),   // a different user never inherits the previous user's screens or chat
      userEmail: label,
      onLogout: () => FirebaseAuth.instance.signOut(),
    );
  }
}


class HomeTabs extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;

  const HomeTabs({super.key, required this.userEmail, required this.onLogout});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> with WidgetsBindingObserver {
  int _index = 0;

  static const _titles = [
    'Buddy AI Assistant',
    'Approval Needed',
    'Friend Profile',
    'Activity Log',
    'System Settings', // 🚨 Replaced 'Gift Ideas' and 'Settings' with this
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initOverlayListener();
    PushService.openApprovalRequests.addListener(_onOpenApprovalRequested);
    PushService.openChatRequests.addListener(_openChatFromPush);
    AppSignals.pendingCount.addListener(_syncOverlayBadge);
    // A push tapped while the app was closed: HomeTabs did not exist yet, so pick it up now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (PushService.consumeOpenRequest()) {
        _goToTab(1);
      } else {
        _openChatFromPush();
      }
    });
  }

  // Foreground / background -> foreground: never show stale approvals.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppSignals.refreshApprovals();
      AppSignals.refreshAudit();
    }
  }

  // Birthday reminder tapped: show Chat with the "want gift ideas?" notice. Nothing is ordered here.
  void _openChatFromPush() {
    if (!mounted) return;
    final notice = PushService.consumeChatNotice();
    if (notice == null) return;
    _goToTab(0);
    AppSignals.notifyChat(notice);
  }

  void _onOpenApprovalRequested() {
    if (!mounted) return;
    PushService.consumeOpenRequest();
    _goToTab(1);
  }

  // Keep the floating bubble's badge equal to the real pending count.
  void _syncOverlayBadge() async {
    try {
      await FlutterOverlayWindow.shareData(AppSignals.pendingCount.value);
    } catch (_) {
      // overlay not running; nothing to update
    }
  }

  void _initOverlayListener() {
    _overlaySubscription?.cancel();
    _overlaySubscription = _overlayEvents.listen(
          (event) async {
        if (!mounted) return;
        if (event == "OPEN_APPROVAL") {
          _goToTab(1);
        } else if (event == "OPEN_CHAT") {
          setState(() => _index = 0);
        } else if (event is String && event.startsWith("QUICK_REPLY:")) {
          // Honest behaviour: the overlay text is NOT yet routed into the chat pipeline,
          // so nothing is drafted or ordered from here.
          await _bringAppToForeground();
          if (!mounted) return;
          setState(() => _index = 0);
          _showSnack('Quick replies are not connected to Buddy yet. Type your request in Chat.',
              AppColors.warning);
        }
      },
      onError: (error) {
        debugPrint("Overlay stream error: $error");
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushService.openApprovalRequests.removeListener(_onOpenApprovalRequested);
    PushService.openChatRequests.removeListener(_openChatFromPush);
    AppSignals.pendingCount.removeListener(_syncOverlayBadge);
    _overlaySubscription?.cancel();
    super.dispose();
  }

  /// Helper method to bring the Android Activity out of background
  Future<void> _bringAppToForeground() async {
    try {
      const channel = MethodChannel('com.example.budyy_app/app_retain');
      await channel.invokeMethod('bringToForeground');
    } catch (e) {
      debugPrint("Failed to bring app to foreground: $e");
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goToTab(int i) {
    setState(() => _index = i);
    if (i == 1) AppSignals.refreshApprovals();
    if (i == 3) AppSignals.refreshAudit();
  }

  Widget _approveIcon(IconData icon) => ValueListenableBuilder<int>(
    valueListenable: AppSignals.pendingCount,
    builder: (_, n, __) =>
        Badge(isLabelVisible: n > 0, label: Text('$n'), child: Icon(icon)),
  );

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(
        userId: widget.userEmail,
        onOpenApproval: (id) {
          AppSignals.focusActionId.value = id;
          _goToTab(1);
        },
      ),
      ApprovalScreen(userId: widget.userEmail),
      FriendProfileScreen(userId: widget.userEmail),
      AuditTrailScreen(userId: widget.userEmail),
      SettingsScreen(userId: widget.userEmail),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // If we are not on the Chat tab, route back to Chat instead of closing
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: screens,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goToTab,
          destinations: [
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat'),
            NavigationDestination(
                icon: _approveIcon(Icons.check_circle_outline),
                selectedIcon: _approveIcon(Icons.check_circle),
                label: 'Approve'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Friend'),
            NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history_toggle_off),
                label: 'Audit'),
            // NavigationDestination(
            //     icon: Icon(Icons.card_giftcard_outlined),
            //     selectedIcon: Icon(Icons.card_giftcard),
            //     label: 'Gifts'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}