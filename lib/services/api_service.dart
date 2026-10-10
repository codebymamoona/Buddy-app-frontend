import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DecisionResult {
  final bool ok;
  final int statusCode;
  final String message;
  const DecisionResult(this.ok, this.statusCode, this.message);
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<DecisionResult> submitActionDecisionDetailed(int actionId, String decision) async {
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

  Future<String> sendChatMessage({required String message}) async {
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
    final url = Uri.parse('${ApiConfig.baseUrl}/actions/pending');
    final response = await _client.get(url, headers: await ApiConfig.authHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Backend Error (${response.statusCode}): ${response.body}');
  }

  Future<bool> submitActionDecision(int actionId, String decision) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/actions/$actionId/decision');
    final response = await _client.post(
      url,
      headers: await ApiConfig.authHeaders(),
      body: jsonEncode({'decision': decision}),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getAuditLog() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/audit-log');
    final response = await _client.get(url, headers: await ApiConfig.authHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Backend Error (${response.statusCode}): ${response.body}');
  }

  Future<double?> getSpendingCap() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me/spending-cap');
    final response = await _client.get(url, headers: await ApiConfig.authHeaders());
    if (response.statusCode == 200) {
      return double.tryParse(response.body);
    }
    return null;
  }

  Future<bool> updateSpendingCap(double cap) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/me/spending-cap');
    final response = await _client.put(
      url,
      headers: await ApiConfig.authHeaders(),
      body: jsonEncode({'cap': cap}),
    );
    return response.statusCode == 200;
  }
}