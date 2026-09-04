import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// 🚨 ADDED WidgetsBindingObserver TO LISTEN TO OS LIFECYCLE 🚨
class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _buddyTyping = false;

  late final PendingActionService _actionService;

  final List<ChatMessage> _messages = [
    ChatMessage(
      fromBuddy: true,
      text: "System Secure. Zero-Trust Backend Online. I can handle food, clothing, and travel. What do you need?",
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 🚨 REGISTER THE OBSERVER
    WidgetsBinding.instance.addObserver(this);

    _actionService = PendingActionService(
      userId: "aqil_01",
      onNewActionDetected: _showReceiptBottomSheet,
    );
    _actionService.startPolling();
  }

  @override
  void dispose() {
    // 🚨 CLEAN UP THE OBSERVER
    WidgetsBinding.instance.removeObserver(this);

    _controller.dispose();
    _scroll.dispose();
    _actionService.stopPolling();
    super.dispose();
  }

  // 🚨 THE LIFECYCLE ROUTER: KILLS THE ZOMBIE TIMER 🚨
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("📱 APP IN FOREGROUND: Waking up background poller");
      _actionService.startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      print("💤 APP IN BACKGROUND: Suspending poller to save battery");
      _actionService.stopPolling();
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
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": "aqil_01",
          "message": text
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages.add(ChatMessage(text: response.body, fromBuddy: true));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(text: "SYSTEM ERROR: ${response.statusCode}", fromBuddy: true));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "NETWORK ERROR: Cannot reach Spring Boot. Ensure it is running on port 8080.", fromBuddy: true));
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
                "Pending Approval",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text("Type: ${action['toolName']}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),

              ...payloadDetails.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text("${e.key.toUpperCase()}: ${e.value}", style: const TextStyle(fontSize: 16)),
              )),

              const Divider(height: 32, thickness: 2),
              Text(
                "Total Deduction: PKR ${action['cost']}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _actionService.submitDecision(action['id'], "REJECT");
                      },
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        Navigator.pop(context);
                        bool success = await _actionService.submitDecision(action['id'], "APPROVE");
                        if (success) {
                          setState(() {
                            _messages.add(ChatMessage(text: "TRANSACTION SUCCESSFUL. Wallet Deducted.", fromBuddy: true));
                          });
                          _scrollToBottom();
                        }
                      },
                      child: const Text("Approve", style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        title: const Text('Buddy AI Assistant'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_buddyTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Buddy is thinking...", style: TextStyle(color: Colors.grey)),
                    ),
                  );
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

// ==========================================
// INTERNAL CLASSES
// ==========================================

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
                color: isBuddy ? Colors.grey[200] : Colors.blueAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: isBuddy ? Colors.black87 : Colors.white, fontSize: 15),
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
                decoration: const InputDecoration(
                  hintText: 'Message Buddy...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class PendingActionService {
  final String baseUrl = "http://127.0.0.1:8080/api/actions";
  final String userId;
  Timer? _pollingTimer;
  Function(Map<String, dynamic>)? onNewActionDetected;

  PendingActionService({required this.userId, this.onNewActionDetected});

  void startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/pending/$userId'));
        if (response.statusCode == 200) {
          List<dynamic> actions = jsonDecode(response.body);
          if (actions.isNotEmpty && onNewActionDetected != null) {
            stopPolling();
            onNewActionDetected!(actions.first);
          }
        }
      } catch (e) {
        // Silently fail if backend is unreachable during polling
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<bool> submitDecision(int actionId, String decision) async {
    print("🚀 ATTEMPTING TO SEND DECISION: $decision FOR ID: $actionId");
    print("🔗 ENDPOINT: $baseUrl/$actionId/decision");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$actionId/decision'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "decision": decision}),
      );

      print("📥 BACKEND STATUS CODE: ${response.statusCode}");
      print("📥 BACKEND RESPONSE: ${response.body}");

      startPolling();
      return response.statusCode == 200;
    } catch (e) {
      print("❌ NETWORK CRASH: $e");
      return false;
    }
  }
}