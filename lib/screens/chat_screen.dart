import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_signals.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final void Function(int actionId) onOpenApproval;

  const ChatScreen({super.key, required this.userId, required this.onOpenApproval});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ApiService _api = ApiService();
  bool _buddyTyping = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      fromBuddy: true,
      text: "Hi, I'm Buddy. I can help order food, plan a trip, or find a gift. What do you need?",
    ),
  ];

  @override
  void initState() {
    super.initState();
    AppSignals.chatNotice.addListener(_onChatNotice);
  }

  @override
  void dispose() {
    AppSignals.chatNotice.removeListener(_onChatNotice);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Messages posted by other screens, e.g. "Order approved: ..." from the Approve tab.
  void _onChatNotice() {
    final n = AppSignals.chatNotice.value;
    if (n == null || !mounted) return;
    setState(() => _messages.add(ChatMessage(text: n.text, fromBuddy: true)));
    _scrollToBottom();
  }

  /// Backend returns {"reply": "...", "pendingActionIds": [..]}. Plain text is still tolerated.
  ({String text, List<int> pendingIds}) _parseReply(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final text = (decoded['reply'] ?? decoded['message'] ?? decoded['response'] ?? rawBody).toString();
        final rawIds = decoded['pendingActionIds'];
        final ids = rawIds is List
            ? rawIds.whereType<num>().map((n) => n.toInt()).toList()
            : <int>[];
        return (text: text, pendingIds: ids);
      }
      return (text: decoded.toString(), pendingIds: <int>[]);
    } catch (_) {
      return (text: rawBody, pendingIds: <int>[]);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, fromBuddy: false));
      _controller.clear();
      _buddyTyping = true;
    });
    _scrollToBottom();

    try {
      final replyBody = await _api.sendChatMessage(message: text);
      if (!mounted) return;
      final parsed = _parseReply(replyBody);
      setState(() {
        _messages.add(ChatMessage(
          text: parsed.text,
          fromBuddy: true,
          pendingActionIds: parsed.pendingIds,
        ));
      });
      if (parsed.pendingIds.isNotEmpty) {
        AppSignals.refreshApprovals();
        AppSignals.refreshAudit();
      }
    } catch (e) {
      debugPrint('sendChatMessage failed: $e');
      if (!mounted) return;
      final isNetworkError = e.toString().contains('Network connection failed');
      setState(() {
        _messages.add(ChatMessage(
          text: isNetworkError
              ? "I couldn't reach the server. Check your connection and try again."
              : "Something went wrong on my end. Try that again in a moment.",
          fromBuddy: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() {
          _buddyTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_buddyTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index], onReview: widget.onOpenApproval);
              },
            ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool fromBuddy;
  final List<int> pendingActionIds;
  ChatMessage({required this.text, required this.fromBuddy, this.pendingActionIds = const []});
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(int actionId)? onReview;
  const _MessageBubble({required this.message, this.onReview});

  @override
  Widget build(BuildContext context) {
    final isBuddy = message.fromBuddy;
    final ids = message.pendingActionIds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isBuddy ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBuddy ? AppColors.surface : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                border: isBuddy ? Border.all(color: AppColors.border) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                        color: isBuddy ? AppColors.textPrimary : Colors.white, fontSize: 15),
                  ),
                  if (isBuddy && ids.isNotEmpty && onReview != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => onReview!(ids.first),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                ids.length == 1 ? 'Review & approve' : 'Review ${ids.length} orders',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask Buddy to do something',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FadeTransition(
          opacity: _animation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              const Text("Buddy is thinking...", style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}