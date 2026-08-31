"chat_screen"

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_logo.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
const ChatScreen({super.key});

@override
State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
final TextEditingController _controller = TextEditingController();
final ScrollController _scroll = ScrollController();
bool _buddyTyping = false;

final List<ChatMessage> _messages = [
ChatMessage(
fromBuddy: true,
text: "Hi, I'm Buddy. I can order food or suggest gifts for your friends. What do you need?",
),
];

void _send([String? preset]) {
final text = preset ?? _controller.text.trim();
if (text.isEmpty) return;
setState(() {
_messages.add(ChatMessage(text: text, fromBuddy: false));
_controller.clear();
_buddyTyping = true;
});
_scrollToBottom();

Future.delayed(const Duration(milliseconds: 900), () {
if (!mounted) return;
String reply;
final lower = text.toLowerCase();
if (lower.contains('cake') || lower.contains('order') || lower.contains('birthday')) {
reply = "Got it! I've sent a Rs 450 birthday cake order for Ayesha to your Approvals tab for confirmation 🎂";
AppState.instance.requestApproval('Birthday cake order for Ayesha', 450);
} else if (lower.contains('gift')) {
reply = "Here are a couple of gift ideas — check the Gifts tab, I've queued a scented candle set for approval 🎁";
} else {
reply = "On it! I'll take care of that and let you know if I need your approval.";
}
setState(() {
_buddyTyping = false;
_messages.add(ChatMessage(text: reply, fromBuddy: true));
});
_scrollToBottom();
});
}

void _scrollToBottom() {
Future.delayed(const Duration(milliseconds: 80), () {
if (!_scroll.hasClients) return;
_scroll.animateTo(_scroll.position.maxScrollExtent + 120,
duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
});
}

@override
void dispose() {
_controller.dispose();
_scroll.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: const BuddyAppBar(title: 'Buddy AI Assistant', trailing: UserAvatar()),
body: Column(
children: [
Expanded(
child: ListView.builder(
controller: _scroll,
padding: const EdgeInsets.all(16),
itemCount: _messages.length + (_buddyTyping ? 1 : 0),
itemBuilder: (context, index) {
if (index == _messages.length) {
return const _TypingBubble();
}
final m = _messages[index];
return TweenAnimationBuilder<double>(
tween: Tween(begin: 0, end: 1),
duration: const Duration(milliseconds: 320),
curve: Curves.easeOutCubic,
builder: (context, t, child) => Opacity(
opacity: t,
child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
),
child: _MessageBubble(message: m),
);
},
),
),
_QuickChips(onTap: _send),
_Composer(controller: _controller, onSend: () => _send()),
],
),
);
}
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
crossAxisAlignment: CrossAxisAlignment.end,
children: [
if (isBuddy) ...[
Container(
width: 30,
height: 30,
margin: const EdgeInsets.only(right: 8),
decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
),
],
Flexible(
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
decoration: BoxDecoration(
color: isBuddy ? AppColors.surface : AppColors.primary,
borderRadius: BorderRadius.only(
topLeft: const Radius.circular(18),
topRight: const Radius.circular(18),
bottomLeft: Radius.circular(isBuddy ? 4 : 18),
bottomRight: Radius.circular(isBuddy ? 18 : 4),
),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
),
child: Text(
message.text,
style: TextStyle(color: isBuddy ? AppColors.pureBlack : Colors.white, fontSize: 14.5, height: 1.35),
),
),
),
],
),
);
}
}

class _TypingBubble extends StatefulWidget {
const _TypingBubble();
@override
State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

@override
void dispose() {
_c.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Align(
alignment: Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.symmetric(vertical: 6),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
child: Row(
mainAxisSize: MainAxisSize.min,
children: List.generate(3, (i) {
return AnimatedBuilder(
animation: _c,
builder: (context, _) {
final v = ((_c.value + i * 0.2) % 1.0);
final scale = 0.6 + 0.4 * (1 - (v - 0.5).abs() * 2).clamp(0.0, 1.0);
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 2),
child: Transform.scale(
scale: scale,
child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.grey, shape: BoxShape.circle)),
),
);
},
);
}),
),
),
);
}
}

class _QuickChips extends StatelessWidget {
final ValueChanged<String> onTap;
const _QuickChips({required this.onTap});

@override
Widget build(BuildContext context) {
const suggestions = ['Order a birthday cake', 'Suggest a gift', 'Remind me tomorrow'];
return SizedBox(
height: 44,
child: ListView.separated(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(horizontal: 16),
itemCount: suggestions.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (context, i) {
return ReactiveButton(
onTap: () => onTap(suggestions[i]),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14),
alignment: Alignment.center,
decoration: BoxDecoration(
color: AppColors.white,
borderRadius: BorderRadius.circular(30),
border: Border.all(color: AppColors.border),
),
child: Text(suggestions[i], style: const TextStyle(fontSize: 13, color: AppColors.pureBlack)),
),
);
},
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
top: false,
child: Padding(
padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
child: Row(
children: [
const AnimatedBuddyLogo(size: 30),
const SizedBox(width: 10),
Expanded(
child: TextField(
controller: controller,
onSubmitted: (_) => onSend(),
decoration: const InputDecoration(hintText: 'Message Buddy...'),
),
),
const SizedBox(width: 10),
ReactiveButton(
onTap: onSend,
borderRadius: BorderRadius.circular(30),
child: Container(
width: 46,
height: 46,
decoration: const BoxDecoration(gradient: AppColors.redGradient, shape: BoxShape.circle),
child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
),
),
],
),
),
);
}
}
