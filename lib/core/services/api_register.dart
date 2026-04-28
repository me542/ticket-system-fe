import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiRegistration {
  static const String baseUrl = "http://localhost:8080/api/user";


  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String fullName,
    required String position,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");


    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "email": email,
        "full_name": fullName,
        "position": position,
        "password": password,
      }),
    );


    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Registration failed: ${response.body}");
    }
  }
}

