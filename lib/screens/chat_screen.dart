import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String userId; // 🚨 FIXED: Now accepts the ID from main.dart

  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ApiService _api = ApiService();
  bool _buddyTyping = false;

  late final PendingActionService _actionService;

  final List<ChatMessage> _messages = [
    ChatMessage(
      fromBuddy: true,
      text: "Hi, I'm Buddy. I can help order food, plan a trip, or find a gift. What do you need?",
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _actionService = PendingActionService(
      onNewActionDetected: _showReceiptBottomSheet,
    );
    _actionService.startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scroll.dispose();
    _actionService.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _actionService.startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _actionService.stopPolling();
    }
  }

  // TODO: confirm the real /api/chat response shape with the backend — this
  // guesses common key names (reply/message/response) and falls back to the
  // raw body only if the response isn't JSON at all.
  String _extractReplyText(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return (decoded['reply'] ?? decoded['message'] ?? decoded['response'] ?? rawBody).toString();
      }
      return decoded.toString();
    } catch (_) {
      return rawBody;
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
      setState(() {
        _messages.add(ChatMessage(text: _extractReplyText(replyBody), fromBuddy: true));
      });
    } catch (e) {
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
      setState(() {
        _buddyTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _showReceiptBottomSheet(Map<String, dynamic> action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Map<String, dynamic> payloadDetails = jsonDecode(action['payload']);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Needs your approval",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text("Type: ${action['toolName']}", style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...payloadDetails.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text("${e.key.toUpperCase()}: ${e.value}",
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              )),
              const Divider(height: 32, color: AppColors.border),
              Text(
                "Total: PKR ${action['cost']}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          foregroundColor: AppColors.danger),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _actionService.submitDecision(action['id'], "REJECT");
                      },
                      child: const Text("Deny"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success, foregroundColor: Colors.white),
                      onPressed: () async {
                        Navigator.pop(context);
                        bool success = await _actionService.submitDecision(action['id'], "APPROVE");
                        if (success) {
                          setState(() {
                            _messages.add(ChatMessage(text: "Done — order placed.", fromBuddy: true));
                          });
                          _scrollToBottom();
                        } else {
                          setState(() {
                            _messages.add(ChatMessage(
                                text: "That approval didn't go through. Check activity to confirm before assuming it's placed.",
                                fromBuddy: true));
                          });
                          _scrollToBottom();
                        }
                      },
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
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
                final m = _messages[index];
                return _MessageBubble(message: m);
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
  ChatMessage({required this.text, required this.fromBuddy});
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isBuddy = message.fromBuddy;
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
              child: Text(
                message.text,
                style: TextStyle(
                    color: isBuddy ? AppColors.textPrimary : Colors.white, fontSize: 15),
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

class PendingActionService {
  final ApiService _api;
  Timer? _pollingTimer;
  Function(Map<String, dynamic>)? onNewActionDetected;

  PendingActionService({ApiService? api, this.onNewActionDetected}) : _api = api ?? ApiService();

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final actions = await _api.getPendingActions();
        if (actions.isNotEmpty && onNewActionDetected != null) {
          stopPolling();
          onNewActionDetected!(actions.first);
        }
      } catch (e) {
        // Intentionally silent: a 3-second poll failing once shouldn't spam
        // the user with errors.
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<bool> submitDecision(int actionId, String decision) async {
    try {
      final success = await _api.submitActionDecision(actionId, decision);
      startPolling();
      return success;
    } catch (e) {
      return false;
    }
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