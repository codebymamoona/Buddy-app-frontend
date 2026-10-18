import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/app_mode.dart';
import 'api_result.dart';
import 'mock_backend.dart';

class DecisionResult {
  final bool ok;
  final int statusCode;
  final String message;
  const DecisionResult(this.ok, this.statusCode, this.message);
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> sendChatMessage({required String message}) async {
    if (AppMode.useMock) return MockBackend.instance.chat(message);
    final url = Uri.parse('${ApiConfig.baseUrl}/chat');
    try {
      final response = await _client.post(
        url,
        headers: await ApiConfig.authHeaders(),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Backend Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Backend Error')) rethrow;
      throw Exception('Network connection failed: $e');
    }
  }

  Future<List<dynamic>> getPendingActions() async {
    if (AppMode.useMock) return MockBackend.instance.getPending();
    final url = Uri.parse('${ApiConfig.baseUrl}/actions/pending');
    final response = await _client.get(url, headers: await ApiConfig.authHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Backend Error (${response.statusCode}): ${response.body}');
  }

  Future<bool> submitActionDecision(int actionId, String decision) async {
    if (AppMode.useMock) return (await MockBackend.instance.decide(actionId, decision)).ok;
    final url = Uri.parse('${ApiConfig.baseUrl}/actions/$actionId/decision');
    final response = await _client.post(
      url,
      headers: await ApiConfig.authHeaders(),
      body: jsonEncode({'decision': decision}),
    );
    return response.statusCode == 200;
  }

  Future<DecisionResult> submitActionDecisionDetailed(int actionId, String decision) async {
    if (AppMode.useMock) {
      final r = await MockBackend.instance.decide(actionId, decision);
      return DecisionResult(r.ok, r.status, r.message);
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/actions/$actionId/decision');
    try {
      final response = await _client.post(
        url,
        headers: await ApiConfig.authHeaders(),
        body: jsonEncode({'decision': decision}),
      );
      final code = response.statusCode;
      if (code == 200) return DecisionResult(true, code, '');
      if (code == 401) return DecisionResult(false, code, 'Your session expired. Please sign in again.');
      if (code >= 500) return DecisionResult(false, code, 'The server hit an error. Please try again.');
      final text = response.body.replaceFirst(RegExp(r'^(ERROR|SUCCESS):\s*'), '').trim();
      return DecisionResult(false, code, text.isNotEmpty ? text : 'The request could not be completed.');
    } catch (_) {
      return const DecisionResult(false, 0, "Couldn't reach the server. Your decision was not sent.");
    }
  }

  /// POST /api/friends. The backend must take the owner from the verified token, never from the body.
  /// This endpoint is not built yet: the real server answers 404 today.
  Future<ApiResult> saveFriendProfile(Map<String, dynamic> profile) async {
    if (AppMode.useMock) return MockBackend.instance.saveFriend(profile);
    final url = Uri.parse('${ApiConfig.baseUrl}/friends');
    try {
      final response = await _client.post(
        url,
        headers: await ApiConfig.authHeaders(),
        body: jsonEncode(profile),
      );
      final code = response.statusCode;
      if (code >= 200 && code < 300) return const ApiResult(true, 200, '');
      if (code == 401) {
        return ApiResult(false, code, 'Your session expired. Please sign in again.');
      }
      if (code == 404) {
        return ApiResult(false, code, "Friend profiles aren't available on the server yet.");
      }
      return ApiResult(false, code, "Couldn't save. Try again.");
    } catch (_) {
      return const ApiResult(false, 0, 'Network error: cannot reach the server.');
    }
  }

  Future<List<dynamic>> getAuditLog() async {
    if (AppMode.useMock) return MockBackend.instance.getAudit();
    final url = Uri.parse('${ApiConfig.baseUrl}/audit-log');
    final response = await _client.get(url, headers: await ApiConfig.authHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Backend Error (${response.statusCode}): ${response.body}');
  }

  Future<double?> getSpendingCap() async {
    if (AppMode.useMock) return MockBackend.instance.getCap();
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me/spending-cap');
    final response = await _client.get(url, headers: await ApiConfig.authHeaders());
    if (response.statusCode == 200) {
      return double.tryParse(response.body);
    }
    return null;
  }

  Future<bool> updateSpendingCap(double cap) async {
    if (AppMode.useMock) return MockBackend.instance.setCap(cap);
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me/spending-cap');
    final response = await _client.put(
      url,
      headers: await ApiConfig.authHeaders(),
      body: jsonEncode({'cap': cap}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateFcmToken(String token) async {
    if (AppMode.useMock) return true;
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me/fcm-token');
    try {
      final response = await _client.put(
        url,
        headers: await ApiConfig.authHeaders(),
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        print('Successfully registered FCM token with backend.');
        return true;
      }
      print('Backend rejected FCM token (${response.statusCode}): ${response.body}');
      return false;
    } catch (e) {
      print('Network error updating FCM token: $e');
      return false;
    }
  }
}