import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiRegister {

  static const String baseUrl = 'http://localhost:8080/api/user';

  static Future<dynamic> register({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    required String position,

  }) async {
    final url = Uri.parse('$baseUrl/register');

    final body = jsonEncode({
      "username": username,
      "password": password,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "position": position,

    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to register. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Register Error: $e');
    }
  }
}
