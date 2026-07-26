import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends user prompt to Spring Boot chat endpoint
  Future<String> sendChatMessage({
    required String userId,
    required String message,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat');

    try {
      final response = await _client.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'userId': userId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Backend Error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }
}