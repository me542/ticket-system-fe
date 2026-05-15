import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiRegistration {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://idiyanale-be.bakawan-ai.com') + '/api/user';




  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String position,
    required String institution,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");


    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username":    username,
        "email":       email,
        "first_name":  firstName,
        "last_name":   lastName,
        "position":    position,
        "institution": institution,
        "password":    password,
      }),
    );


    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Registration failed: ${response.body}");
    }
  }
}