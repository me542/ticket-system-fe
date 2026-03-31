import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiUser {
  static const String baseUrl = 'http://localhost:8080/api/user'; // change to your backend

  static Future<bool> createUser({
    required String username,
    required String fullname,
    required String email,
    required String password,
    required String Position,
    required String role,
    required String position,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final body = jsonEncode({
      'username': username,
      'fullname': fullname,
      'email': email,
      'password': password,
      'position': Position,
      'role': role,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
