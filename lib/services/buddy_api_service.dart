import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BuddyApiService {
  final String baseUrl;
  BuddyApiService({this.baseUrl = ApiConfig.baseUrl});

  // ---------------------------------------------------------------------
  // 1. CHAT
  // POST /api/chat
  // Request:  { "message": "order a cake for Ayesha" }
  // Response: { "reply": "...", "intent": "PURCHASE"|"GIFT"|"CHAT",
  //             "item": "..." | null, "amount": number | null }
  // ---------------------------------------------------------------------
  Future<BuddyChatResponse> sendMessage(String message) async {
    final uri = Uri.parse('$baseUrl/api/chat');
    final response = await _post(uri, {'message': message});
    return BuddyChatResponse.fromJson(response);
  }

  // ---------------------------------------------------------------------
  // 2. SPENDING CAP
  // GET /api/spending-cap  -> { "limit": 2000.0, "used": 450.0 }
  // PUT /api/spending-cap  <- { "limit": 2500.0 }
  //                        -> { "limit": 2500.0, "used": 450.0 }
  // ---------------------------------------------------------------------
  Future<SpendingCapResponse> getSpendingCap() async {
    final uri = Uri.parse('$baseUrl/api/spending-cap');
    final response = await _get(uri);
    return SpendingCapResponse.fromJson(response);
  }

  Future<SpendingCapResponse> updateSpendingCap(double newLimit) async {
    final uri = Uri.parse('$baseUrl/api/spending-cap');
    final response = await _put(uri, {'limit': newLimit});
    return SpendingCapResponse.fromJson(response);
  }

  // ---------------------------------------------------------------------
  // 3. APPROVAL
  // POST /api/approval
  // Request:  { "approved": true, "item": "...", "amount": 450.0 }
  // Response: { "status": "ok" }
  // ---------------------------------------------------------------------
  Future<void> submitApproval({
    required bool approved,
    required String item,
    required double amount,
  }) async {
    final uri = Uri.parse('$baseUrl/api/approval');
    await _post(uri, {
      'approved': approved,
      'item': item,
      'amount': amount,
    });
  }

  // ---------------------------------------------------------------------
  // 4. AUDIT LOG
  // GET /api/audit-log -> [ { "timestamp": "...", "action": "...", "detail": "..." }, ... ]
  // ---------------------------------------------------------------------
  Future<List<AuditLogEntryResponse>> getAuditLog() async {
    final uri = Uri.parse('$baseUrl/api/audit-log');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => AuditLogEntryResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------
  // 5. FRIEND PROFILE
  // POST /api/friend-profile
  //   Request:  { "name": "...", "birthday": "..." | null, "likes": ["..."] }
  //   Response: { "status": "ok" }
  // GET /api/friend-profile/{name} -> { "name": "...", "birthday": "...", "likes": [...] }
  // ---------------------------------------------------------------------
  Future<void> saveFriendProfile({
    required String name,
    String? birthday,
    required List<String> likes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/friend-profile');
    await _post(uri, {
      'name': name,
      'birthday': birthday,
      'likes': likes,
    });
  }

  Future<FriendProfileResponse> getFriendProfile(String name) async {
    final uri = Uri.parse('$baseUrl/api/friend-profile/$name');
    final response = await _get(uri);
    return FriendProfileResponse.fromJson(response);
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      _checkStatus(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on http.ClientException {
      throw BuddyApiException('Could not reach Buddy — is the server running?');
    }
  }

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      _checkStatus(response);
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on http.ClientException {
      throw BuddyApiException('Could not reach Buddy — is the server running?');
    }
  }

  Future<Map<String, dynamic>> _put(Uri uri, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      _checkStatus(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on http.ClientException {
      throw BuddyApiException('Could not reach Buddy — is the server running?');
    }
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BuddyApiException('Server returned ${response.statusCode}');
    }
  }
}

// ---------------------------------------------------------------------
// Response models
// ---------------------------------------------------------------------

class BuddyChatResponse {
  final String reply;
  final String intent;
  final String? item;
  final double? amount;

  BuddyChatResponse({required this.reply, required this.intent, this.item, this.amount});

  factory BuddyChatResponse.fromJson(Map<String, dynamic> json) => BuddyChatResponse(
    reply: json['reply'] as String? ?? '',
    intent: json['intent'] as String? ?? 'CHAT',
    item: json['item'] as String?,
    amount: (json['amount'] as num?)?.toDouble(),
  );
}

class SpendingCapResponse {
  final double limit;
  final double used;

  SpendingCapResponse({required this.limit, required this.used});

  factory SpendingCapResponse.fromJson(Map<String, dynamic> json) => SpendingCapResponse(
    limit: (json['limit'] as num?)?.toDouble() ?? 0,
    used: (json['used'] as num?)?.toDouble() ?? 0,
  );
}

class AuditLogEntryResponse {
  final String timestamp;
  final String action;
  final String detail;

  AuditLogEntryResponse({required this.timestamp, required this.action, required this.detail});

  factory AuditLogEntryResponse.fromJson(Map<String, dynamic> json) => AuditLogEntryResponse(
    timestamp: json['timestamp'] as String? ?? '',
    action: json['action'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
  );
}

class FriendProfileResponse {
  final String name;
  final String? birthday;
  final List<String> likes;

  FriendProfileResponse({required this.name, this.birthday, required this.likes});

  factory FriendProfileResponse.fromJson(Map<String, dynamic> json) => FriendProfileResponse(
    name: json['name'] as String? ?? '',
    birthday: json['birthday'] as String?,
    likes: (json['likes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
  );
}

class BuddyApiException implements Exception {
  final String message;
  BuddyApiException(this.message);
  @override
  String toString() => message;
}