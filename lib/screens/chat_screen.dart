import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/buddy_api_service.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final bool isAction;
  final String? intent;

  ChatMessage(this.text, this.fromUser, {this.isAction = false, this.intent});
}

class ChatScreen extends StatefulWidget {
  final void Function()? onPurchaseIntent;
  final String? initialMessage;
  final String userId;

  const ChatScreen({
    super.key,
    this.onPurchaseIntent,
    this.initialMessage,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _api = BuddyApiService();

  // Updated welcome message reflecting current scope (Food & Spending Cap only)
  final List<ChatMessage> _messages = [
    ChatMessage("Hi, I'm Buddy. I can help you order food and manage your spending approvals. What do you need?", false),
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
      // 1. Send to the real Spring Boot LangChain4j Backend
      final response = await _api.sendMessage(widget.userId, text);
      if (!mounted) return;

      setState(() {
        _typing = false;
        _messages.add(ChatMessage(response.reply, false));

        // 2. Parse LLM response strictly for purchase/approval action triggers
        final lowerReply = response.reply.toLowerCase();
        if (lowerReply.contains("draft") ||
            lowerReply.contains("approve") ||
            lowerReply.contains("review") ||
            lowerReply.contains("order")) {
          _messages.add(ChatMessage('Review & Approve →', false, isAction: true, intent: 'PURCHASE'));
        }
        // Gift intents are now intentionally ignored to match the reduced scope.
      });
    } catch (e) {
      if (!mounted) return;

      // 3. Fail loudly and securely
      setState(() {
        _typing = false;
        _messages.add(ChatMessage("System Error: Could not reach the AI core. $e", false));
      });
    }

    _scrollToBottom();
  }

  // Handles the tap on the Action Chips (Purchase only)
  void _handleActionTap(String? intent) {
    if (intent == 'PURCHASE') {
      widget.onPurchaseIntent?.call();
    }
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
              if (m.isAction) return _buildActionChip(m);
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
          if (!m.fromUser && !m.isAction) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy_outlined, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                  color: m.fromUser ? Colors.white : (m.text.contains("System Error") ? Colors.red : AppColors.textPrimary),
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

  Widget _buildActionChip(ChatMessage m) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _handleActionTap(m.intent),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(m.text, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
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
          Text('Buddy is thinking…', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
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