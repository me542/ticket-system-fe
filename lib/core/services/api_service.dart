import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiLogin {
  static const String baseUrl = 'http://localhost:8080/api/user/login';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data; // success
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }
}
