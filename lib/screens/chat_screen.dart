import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/buddy_api_service.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final bool isAction;
  ChatMessage(this.text, this.fromUser, {this.isAction = false});
}

class ChatScreen extends StatefulWidget {
  final void Function(String item, double amount)? onPurchaseIntent;
  final VoidCallback? onGiftIntent;

  const ChatScreen({super.key, this.onPurchaseIntent, this.onGiftIntent, String? initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _api = BuddyApiService();
  final List<ChatMessage> _messages = [
    ChatMessage("Hi, I'm Buddy. I can order food or suggest gifts for your friends. What do you need?", false),
  ];
  bool _typing = false;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _controller.clear();
      _typing = true;
    });
    _scrollToBottom();

    try {
      // Try the real backend first.
      final response = await _api.sendMessage(text);
      if (!mounted) return;

      setState(() {
        _typing = false;
        _messages.add(ChatMessage(response.reply, false));
        if (response.intent == 'PURCHASE' && response.item != null && response.amount != null) {
          _messages.add(ChatMessage('Review & Approve →', false, isAction: true));
        } else if (response.intent == 'GIFT') {
          _messages.add(ChatMessage('View Gift Ideas →', false, isAction: true));
        }
      });

      if (response.intent == 'PURCHASE' && response.item != null && response.amount != null) {
        widget.onPurchaseIntent?.call(response.item!, response.amount!);
      } else if (response.intent == 'GIFT') {
        widget.onGiftIntent?.call();
      }
    } catch (e) {
      // Backend unreachable or returned something unexpected —
      // fall back to local intent detection so navigation still works.
      // TODO: remove this fallback once /api/chat is confirmed stable.
      if (!mounted) return;
      _handleLocalFallback(text);
    }

    _scrollToBottom();
  }

  void _handleLocalFallback(String text) {
    final lower = text.toLowerCase();

    if (_containsAny(lower, ['order', 'buy', 'cake', 'food', 'pizza', 'lunch', 'dinner'])) {
      final amount = _extractAmount(lower) ?? 450;
      final item = _extractItemDescription(text);
      setState(() {
        _typing = false;
        _messages.add(ChatMessage(
          "Sure — I found an order for Rs ${amount.toStringAsFixed(0)}. Since this involves spending, I need your approval before placing it.",
          false,
        ));
        _messages.add(ChatMessage('Review & Approve →', false, isAction: true));
      });
      widget.onPurchaseIntent?.call(item, amount);
    } else if (_containsAny(lower, ['gift', 'present', 'suggest', 'recommend'])) {
      setState(() {
        _typing = false;
        _messages.add(ChatMessage(
          "Let me pull up some gift ideas based on what you've told me about your friend.",
          false,
        ));
        _messages.add(ChatMessage('View Gift Ideas →', false, isAction: true));
      });
      widget.onGiftIntent?.call();
    } else if (_containsAny(lower, ['hi', 'hello', 'hey'])) {
      setState(() {
        _typing = false;
        _messages.add(ChatMessage("Hey! Want me to order something or suggest a gift?", false));
      });
    } else {
      setState(() {
        _typing = false;
        _messages.add(ChatMessage(
          "I can help with ordering food or suggesting gifts — try something like \"order a cake for Ayesha\" or \"suggest a gift for Ayesha.\"",
          false,
        ));
      });
    }
  }

  bool _containsAny(String text, List<String> keywords) => keywords.any((k) => text.contains(k));

  double? _extractAmount(String text) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  String _extractItemDescription(String original) {
    final trimmed = original.trim();
    if (trimmed.isEmpty) return 'Order';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_typing ? 1 : 0),
            itemBuilder: (context, i) {
              if (_typing && i == _messages.length) return _buildTypingIndicator();
              final m = _messages[i];
              if (m.isAction) return _buildActionChip(m.text);
              return _buildBubble(context, m);
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: m.fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!m.fromUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy_outlined, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: m.fromUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(m.fromUser ? 16 : 4),
                  bottomRight: Radius.circular(m.fromUser ? 4 : 16),
                ),
                border: m.fromUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                m.text,
                style: TextStyle(
                  color: m.fromUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(left: 36, bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.smart_toy_outlined, size: 15, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text('Buddy is typing…', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Message Buddy…',
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20), onPressed: _send),
            ),
          ],
        ),
      ),
    );
  }
}