import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_login.dart';

class ApiUser {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080') + '/api/user';

  // Prod
  //static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://idiyanale-be.bakawan-ai.com') + '/api/user';


  // ================= TOKEN =================
  static Future<String?> getToken() async {
    final token = await ApiLogin.getToken();
    return token;
  }

  // ================= HEADERS =================
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
    return headers;
  }



  // ================= CREATE =================
  static Future<bool> createUser({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required String position,
    required String institution,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final body = jsonEncode({
      'username':    username,
      'first_name':  firstName,
      'last_name':   lastName,
      'email':       email,
      'password':    password,
      'position':    position,
      'institution': institution,
      'role':        role,
    });

    try {
      final response = await http.post(
        url,
        headers: await _headers(),
        body: body,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      //
      return false;
    }
  }

  // ================= UPDATE =================
  static Future<bool> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    String? password,
    required String role,
    required String position,
    required String institution,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/update/profile/$id');

    final body = jsonEncode({
      'first_name':  firstName,
      'last_name':   lastName,
      'email':       email,
      if (password != null && password.isNotEmpty) 'password': password,
      'role':        role,
      'position':    position,
      'institution': institution,
      'status':      status,
    });

    try {
      final response = await http.put(
        url,
        headers: await _headers(),
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      //
      return false;
    }
  }

  // ================= DISABLE =================
  static Future<bool> disableUser({required int id}) async {
    final url = Uri.parse('$baseUrl/update/profile/$id');

    final body = jsonEncode({
      'status': 'inactive',
    });

    try {
      final response = await http.put(
        url,
        headers: await _headers(),
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      //
      return false;
    }
  }

  // ================= ENABLE =================
  static Future<bool> enableUser({required int id}) async {
    final url = Uri.parse('$baseUrl/update/profile/$id');

    final body = jsonEncode({
      'status': 'active',
    });

    try {
      final response = await http.put(
        url,
        headers: await _headers(),
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      //
      return false;
    }
  }
}