import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:bring_app_to_foreground/bring_app_to_foreground.dart';

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
import 'screens/gift_recommendation_screen.dart';
import 'screens/spending_cap_settings_screen.dart';
import 'screens/settings_screen.dart';

/// Top-level entry point for the floating Chat Head overlay
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatBubbleOverlay(),
    ),
  );
}

/// Floating Chat Head Bubble Widget with Dynamic Number Badge
class ChatBubbleOverlay extends StatefulWidget {
  const ChatBubbleOverlay({super.key});

  @override
  State<ChatBubbleOverlay> createState() => _ChatBubbleOverlayState();
}

class _ChatBubbleOverlayState extends State<ChatBubbleOverlay> {
  int _pendingCount = 0;

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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            // 1. Wake up and bring main app to foreground
            await BringAppToForeground.bringToFront();

            // 2. Contextual Routing: Send targeted tab event based on pending count
            if (_pendingCount > 0) {
              await FlutterOverlayWindow.shareData("OPEN_APPROVAL");
            } else {
              await FlutterOverlayWindow.shareData("OPEN_CHAT");
            }

            // 3. Close the floating overlay window
            await FlutterOverlayWindow.closeOverlay();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Circular Chat Bubble
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 28,
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
  UserPreferences? _preferences;

  void _handleLoginSuccess(String email) => setState(() => _loggedInEmail = email);

  void _handleLogout() => setState(() {
    _loggedInEmail = null;
    _preferences = null;
  });

  void _handlePreferencesComplete(UserPreferences prefs) =>
      setState(() => _preferences = prefs);

  @override
  Widget build(BuildContext context) {
    if (_loggedInEmail == null) {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }
    if (_preferences == null) {
      return PreferencesScreen(onComplete: _handlePreferencesComplete);
    }
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
    // Listen for routing events sent from the overlay bubble
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (mounted) {
        if (event == "OPEN_APPROVAL") {
          setState(() => _index = 1); // Routes to Approval tab
        } else if (event == "OPEN_CHAT") {
          setState(() => _index = 0); // Routes to Chat tab
        }
      }
    });
  }

  void _handleChatPurchaseIntent(String item, double amount) {
    setState(() {
      _pendingItem = item;
      _pendingAmount = amount;
    });

    // Notify the floating bubble overlay to update/increment badge
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
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Spending Cap')),
        body: SpendingCapSettingsScreen(
          initialCap: _capLimit,
          onSave: (v) {
            _handleSaveCap(v);
            Navigator.of(context).pop();
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(
        onPurchaseIntent: _handleChatPurchaseIntent,
        onGiftIntent: () => setState(() => _index = 4),
      ),
      ApprovalScreen(
        itemDescription: _pendingItem,
        amount: _pendingAmount,
        cap: SpendingCap(limit: _capLimit, used: _capUsed),
        onApprove: _handleApprove,
        onDeny: _handleDeny,
      ),
      const FriendProfileScreen(),
      AuditTrailScreen(entries: _auditEntries),
      GiftRecommendationScreen(
          friendName: 'Ayesha', ideas: _giftIdeas, onOrder: _handleOrderGift),
      SettingsScreen(
        userEmail: widget.userEmail,
        onLogout: widget.onLogout,
        onOpenSpendingCap: _openSpendingCapScreen,
      ),
    ];

    return Scaffold(
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
      body: SafeArea(bottom: false, child: screens[_index]),
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
          NavigationDestination(
              icon: Icon(Icons.card_giftcard_outlined),
              selectedIcon: Icon(Icons.card_giftcard),
              label: 'Gifts'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}