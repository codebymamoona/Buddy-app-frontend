import 'dart:io';

class ApiConfig {
  // 10.0.2.2 routes to host machine from Android Emulator
  // localhost routes to host machine from iOS Simulator or Web
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://127.0.0.1:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}