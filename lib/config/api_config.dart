import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class ApiConfig {
  // Set at build time with: --dart-define=API_BASE_URL=https://your-app.up.railway.app/api
  // Include the trailing /api segment when you set this, since call sites
  // append paths like '/chat' directly onto baseUrl.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // 127.0.0.1 routes to the host machine from the Android Emulator.
    // localhost routes to the host machine from iOS Simulator or Web.
    if (Platform.isAndroid) {
      return 'http://127.0.0.1:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers with the current Firebase ID token attached. Async because
  /// getting a fresh token is async — every authenticated call needs this
  /// instead of the old static `headers` constant.
  static Future<Map<String, String>> authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}