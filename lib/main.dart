import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'theme/app_theme.dart';
import 'models/spending_cap.dart';
import 'models/audit_entry.dart';
import 'models/gift_idea.dart';
import 'models/user_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/approval_screen.dart';
import 'screens/friend_profile_screen.dart';
import 'screens/audit_trail_screen.dart';
//import 'screens/gift_recommendation_screen.dart';
import 'screens/spending_cap_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'dart:async';

StreamSubscription? _overlaySubscription;

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

void main() => runApp(const BuddyApp());

class BuddyApp extends StatelessWidget {
  const BuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
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
  String? _loggedInEmail;

  void _handleLoginSuccess(String email) => setState(() => _loggedInEmail = email);

  void _handleLogout() => setState(() {
    _loggedInEmail = null;
  });

  @override
  Widget build(BuildContext context) {
    if (_loggedInEmail == null) {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }
    // Bypassed PreferencesScreen entirely to keep backend logic clean and stable
    return HomeTabs(userEmail: _loggedInEmail!, onLogout: _handleLogout);
  }
}

class HomeTabs extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;

  const HomeTabs({super.key, required this.userEmail, required this.onLogout});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _index = 0;
  String? _pendingQuickReplyMessage; // Tracks incoming messages from overlay

  // Central app state
  double _capLimit = 2000;
  double _capUsed = 450;
  double _pendingAmount = 450;
  String _pendingItem = 'Birthday cake order for Ayesha';

  final List<AuditEntry> _auditEntries = [
    AuditEntry(
        timestamp: DateTime.now(), action: 'Order placed', detail: 'Cake, Rs 450'),
  ];

  final List<GiftIdea> _giftIdeas = [
    GiftIdea(
        title: 'Scented candle set', price: 800, reason: 'She mentioned liking cozy things'),
    GiftIdea(
        title: 'Book: Local bestseller', price: 1200, reason: 'Likes reading, per her profile'),
    GiftIdea(
        title: 'Shopping: Ethnic Brand', price: 5000, reason: 'love wearing new clothes'),
    GiftIdea(
        title: 'Perfume: Janan set', price: 8000, reason: 'perfume lover'),
  ];

  static const _titles = [
    'Buddy AI Assistant',
    'Approval Needed',
    'Friend Profile',
    'Activity Log',
    'Gift Ideas',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _initOverlayListener();
  }

  void _initOverlayListener() {
    // Cancel previous subscription if it exists
    _overlaySubscription?.cancel();

    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen(
          (event) async {
        if (!mounted) return;

        if (event == "OPEN_APPROVAL") {
          setState(() => _index = 1);
        } else if (event == "OPEN_CHAT") {
          setState(() => _index = 0);
        } else if (event is String && event.startsWith("QUICK_REPLY:")) {
          final quickMsg = event.replaceFirst("QUICK_REPLY:", "").trim();
          final lowerMsg = quickMsg.toLowerCase();

          final isPurchaseIntent = lowerMsg.contains("order") ||
              lowerMsg.contains("buy") ||
              lowerMsg.contains("purchase") ||
              lowerMsg.contains("get") ||
              lowerMsg.contains("pay");

          if (isPurchaseIntent) {
            final formattedItem = quickMsg.isNotEmpty ? quickMsg : "Requested Order";

            await _bringAppToForeground();

            setState(() {
              _pendingItem = formattedItem;
              _pendingAmount = 500.0;
              _index = 1; // Switch to Approval tab
            });

            await FlutterOverlayWindow.shareData("SHOW_APPROVAL_BADGE");
            _showSnack('Approval requested for: "$formattedItem"', AppColors.primary);
          } else {
            await _bringAppToForeground();
            setState(() {
              _index = 0;
              _pendingQuickReplyMessage = quickMsg;
            });
            _showSnack('Sent to Buddy: "$quickMsg"', AppColors.primary);
          }
        }
      },
      onError: (error) {
        debugPrint("Overlay stream error: $error");
        // Re-initialize listener if it crashes or disconnects
        _initOverlayListener();
      },
    );
  }

  @override
  void dispose() {
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

  // PARAMETERS REMOVED HERE
  void _handleChatPurchaseIntent() {
    setState(() {
      _pendingItem = "Pending AI Draft (Check Database)";
      _pendingAmount = 0.0;
    });

    // Notify the floating bubble overlay to increment badge
    FlutterOverlayWindow.shareData("SHOW_APPROVAL_BADGE");

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _index = 1);
    });
  }

  void _handleApprove() {
    setState(() {
      _capUsed += _pendingAmount;
      _auditEntries.insert(
        0,
        AuditEntry(
            timestamp: DateTime.now(), action: 'Approved', detail: _pendingItem),
      );
    });

    // Clear badge on approval
    FlutterOverlayWindow.shareData("CLEAR_BADGE");
    _showSnack('Approved', AppColors.success);
  }

  void _handleDeny() {
    setState(() {
      _auditEntries.insert(
        0,
        AuditEntry(
            timestamp: DateTime.now(), action: 'Denied', detail: _pendingItem),
      );
    });

    // Clear badge on denial
    FlutterOverlayWindow.shareData("CLEAR_BADGE");
    _showSnack('Denied', AppColors.danger);
  }

  void _handleOrderGift(GiftIdea idea) {
    setState(() {
      _pendingAmount = idea.price;
      _pendingItem = 'Gift: ${idea.title}';
      _index = 1;
    });

    // Trigger badge increment for gift order approval
    FlutterOverlayWindow.shareData("SHOW_APPROVAL_BADGE");
  }

  void _handleSaveCap(double newCap) {
    setState(() => _capLimit = newCap);
    _showSnack('Cap saved', AppColors.primary);
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

  void _openSpendingCapScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const SpendingCapScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ChatScreen(),
      const ApprovalScreen(), // RESTORED
      const Scaffold(body: Center(child: Text('Friend Profile Offline'))),
      const AuditTrailScreen(), // RESTORED
      const Scaffold(body: Center(child: Text('Settings Offline'))),
    ];

    // Clear pending quick message after injecting it to prevent repeated calls
    _pendingQuickReplyMessage = null;

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
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat'),
            NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
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