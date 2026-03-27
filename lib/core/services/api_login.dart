// lib/core/services/api_login.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiLogin {
  // 🔥 Replace this with your backend login endpoint
  static const String loginUrl = 'http://localhost:8080/api/user/login';

  // Optional: Store token after login
  static String? _token;

  /// Login function
  /// Returns a Map with "success" and "data" or "error"
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Optional: store token if backend returns it
        if (data['token'] != null) {
          _token = data['token'];
        }

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Optional: Get stored token
  static String? get token => _token;

  /// Optional: Clear stored token (logout)
  static void logout() {
    _token = null;
  }
}
