import 'dart:convert';

import '../config/app_mode.dart';
import 'api_result.dart';

/// In-memory stand-in for the Spring Boot backend, used only with --dart-define=USE_MOCK=true.
/// Keep its JSON shapes in sync with the real backend.
class MockBackend {
  MockBackend._() {
    _seedAudit();
  }
  static final MockBackend instance = MockBackend._();

  int _nextId = 100;
  double _wallet = 5000;
  double _cap = 5000;
  double _spentToday = 0;
  bool _awaitingFoodYes = false;
  final List<Map<String, dynamic>> _pending = [];
  final List<Map<String, dynamic>> _audit = [];   // newest first
  final List<Map<String, dynamic>> _friends = [];

  Future<void> _latency() =>
      Future<void>.delayed(Duration(milliseconds: AppMode.mockDelayMs));

  String _iso(DateTime t) => t.toIso8601String();

  void _logAudit(String type, String detail) {
    _audit.insert(0, {'timestamp': _iso(DateTime.now()), 'action': type, 'detail': detail});
  }

  void _seedAudit() {
    final now = DateTime.now();
    void add(Duration ago, String type, String detail) =>
        _audit.add({'timestamp': _iso(now.subtract(ago)), 'action': type, 'detail': detail});
    const zinger = '{"brand":"Cheezious","item":"Zinger Burger","cost":650.0}';
    add(const Duration(minutes: 20), 'FAILED', 'Execution blocked: daily cap of PKR 5000.0 would be exceeded.');
    add(const Duration(minutes: 21), 'DRAFTED', '{"airline":"Emirates","origin":"Islamabad","destination":"Dubai","cost":92000.0}');
    add(const Duration(hours: 5), 'REJECTED', 'User explicitly rejected the order.');
    add(const Duration(hours: 5, minutes: 1), 'DRAFTED', '{"brand":"Savour","item":"Chicken Karahi (Full)","cost":2400.0}');
    add(const Duration(days: 1), 'EXECUTED', zinger);
    add(const Duration(days: 1, minutes: 1), 'DRAFTED', zinger);
    add(const Duration(days: 3), 'EXPIRED', 'TTL expired before user approval.');
    add(const Duration(days: 3, minutes: 15), 'DRAFTED', '{"brand":"Juice Land","item":"Mango Shake","cost":400.0}');
  }

  int _draft(String tool, Map<String, dynamic> payload, double cost) {
    final id = _nextId++;
    final now = DateTime.now();
    final json = jsonEncode(payload);
    _pending.add({
      'id': id,
      'userId': 'mock-user',
      'toolName': tool,
      'payload': json,
      'cost': cost,
      'status': 'PENDING',
      'createdAt': _iso(now),
      'expiresAt': _iso(now.add(const Duration(minutes: 15))),
    });
    _logAudit('DRAFTED', json);
    return id;
  }

  // ---------------- chat ----------------

  /// Magic messages: /error (network failure), /long (long reply to check wrapping).
  Future<String> chat(String message) async {
    await _latency();
    final m = message.trim().toLowerCase();
    if (AppMode.fails('chat') || m == '/error') {
      throw Exception('Network connection failed: mock failure');
    }

    final wasAwaiting = _awaitingFoodYes;
    _awaitingFoodYes = false;
    final ids = <int>[];
    String reply;

    if (m == '/long') {
      reply = 'This is a deliberately long reply so you can check line wrapping, line height and bubble width. '
          'It keeps going on purpose, so you can see how a paragraph of text sits inside a chat bubble on a small screen, '
          'including what happens to words that do not fit at the end of a line.';
    } else if (wasAwaiting && RegExp(r'\b(yes|yeah|yep|sure|ok|okay)\b').hasMatch(m)) {
      ids.add(_draft('FoodDeliveryTool',
          {'brand': 'Cheezious', 'item': 'Zinger Burger', 'cost': 650.0}, 650.0));
      reply = 'I have drafted your order for a Zinger Burger from Cheezious for PKR 650.0. '
          'Tap the Review and approve button below to check the details and confirm.';
    } else if (m.contains('hungry') || m.contains('something to eat')) {
      _awaitingFoodYes = true;
      reply = 'Last time you ordered a Zinger Burger from Cheezious. Do you want that again, or something else today?';
    } else if (m.contains('flight') || m.contains('fly')) {
      ids.add(_draft('TravelDelegatorTool',
          {'airline': 'Emirates', 'origin': 'Islamabad', 'destination': 'Dubai', 'cost': 92000.0}, 92000.0));
      reply = 'I have drafted your flight booking from Islamabad to Dubai via Emirates for PKR 92000.0. '
          'Tap the Review and approve button below to check the details and confirm.';
    } else if (m.contains('shirt') || m.contains('buy')) {
      ids.add(_draft('CommerceDelegatorTool',
          {'brand': 'Stylo', 'item': 'T-Shirt', 'color': 'Blue', 'size': 'Large', 'cost': 1800.0}, 1800.0));
      reply = 'I have drafted your order for a Large Blue T-Shirt from Stylo for PKR 1800.0. '
          'Tap the Review and approve button below to check the details and confirm.';
    } else {
      reply = 'I am running in demo mode. Try "I am hungry", "Book a flight to Dubai" or "Buy a blue T-shirt". '
          'Also try /long and /error.';
    }
    return jsonEncode({'reply': reply, 'pendingActionIds': ids});
  }

  // ---------------- approvals ----------------

  Future<List<dynamic>> getPending() async {
    await _latency();
    if (AppMode.fails('pending')) throw Exception('Backend Error (500): mock failure');
    if (AppMode.isEmpty('pending')) return <dynamic>[];
    final now = DateTime.now();
    return _pending
        .where((a) =>
    a['status'] == 'PENDING' && DateTime.parse(a['expiresAt'] as String).isAfter(now))
        .map((a) => Map<String, dynamic>.from(a))
        .toList();
  }

  Future<({bool ok, int status, String message})> decide(int id, String decision) async {
    await _latency();
    if (AppMode.fails('decision')) {
      return (ok: false, status: 500, message: 'The server hit an error. Please try again.');
    }
    final index = _pending.indexWhere((a) => a['id'] == id);
    if (index < 0) return (ok: false, status: 404, message: 'Action not found.');
    final a = _pending[index];
    if (a['status'] != 'PENDING') {
      return (ok: false, status: 409, message: 'This action was already processed.');
    }
    final cost = (a['cost'] as num).toDouble();
    final detail = a['payload'] as String;

    if (decision.toUpperCase() == 'REJECT') {
      a['status'] = 'REJECTED';
      _logAudit('REJECTED', 'User explicitly rejected the order.');
      return (ok: true, status: 200, message: '');
    }
    if (!DateTime.parse(a['expiresAt'] as String).isAfter(DateTime.now())) {
      a['status'] = 'EXPIRED';
      _logAudit('EXPIRED', 'Approval attempted after the approval window closed.');
      return (ok: false, status: 410, message: 'This request has expired. Ask Buddy again.');
    }
    if (_spentToday + cost > _cap) {
      a['status'] = 'FAILED_CAP_EXCEEDED';
      _logAudit('FAILED', 'Execution blocked: daily cap of PKR $_cap would be exceeded.');
      return (ok: false, status: 422, message: 'This would exceed your daily spending cap of PKR $_cap.');
    }
    if (_wallet < cost) {
      a['status'] = 'FAILED_INSUFFICIENT_FUNDS';
      _logAudit('FAILED', 'Execution blocked: Insufficient wallet balance.');
      return (ok: false, status: 422, message: 'Insufficient funds in wallet.');
    }
    _wallet -= cost;
    _spentToday += cost;
    a['status'] = 'EXECUTED';
    _logAudit('EXECUTED', detail);
    return (ok: true, status: 200, message: '');
  }

  // ---------------- friend profiles ----------------

  Future<ApiResult> saveFriend(Map<String, dynamic> profile) async {
    await _latency();
    if (AppMode.fails('friend')) {
      return const ApiResult(false, 500, "Couldn't save. Try again.");
    }
    _friends.add(Map<String, dynamic>.from(profile));
    return const ApiResult(true, 200, '');
  }

  // ---------------- audit and settings ----------------

  Future<List<dynamic>> getAudit() async {
    await _latency();
    if (AppMode.fails('audit')) throw Exception('Backend Error (500): mock failure');
    if (AppMode.isEmpty('audit')) return <dynamic>[];
    return _audit.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<double?> getCap() async {
    await _latency();
    if (AppMode.fails('cap')) return null;
    return _cap;
  }

  Future<bool> setCap(double value) async {
    await _latency();
    if (AppMode.fails('cap')) return false;
    _cap = value;
    return true;
  }
}