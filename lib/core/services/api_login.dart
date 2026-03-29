import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiLogin {

  static const String loginUrl = 'http://localhost:8080/api/user/login';

  static String? _token;

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

  static String? get token => _token;

  static void logout() {
    _token = null;
  }
}
