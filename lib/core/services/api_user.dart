import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiUser {
  static const String baseUrl = 'http://localhost:8080/api/user';

  // ================= TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ================= CREATE =================
  static Future<bool> createUser({
    required String username,
    required String fullname,
    required String email,
    required String password,
    required String role,
    required String position,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final body = jsonEncode({
      'username': username,
      'full_name': fullname,
      'email': email,
      'password': password,
      'position': position,
      'role': role,
    });

    try {
      final response = await http.post(url, headers: await _headers(), body: body);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ================= UPDATE =================
  static Future<bool> updateUser({
    required int id,
    required String fullname,
    required String email,
    String? password,
    required String role,
    required String position,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/update/profile/$id');

    final body = jsonEncode({
      'full_name': fullname,
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
      'role': role,
      'position': position,
      'status': status,
    });

    try {
      final response = await http.put(url, headers: await _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= DISABLE =================
  static Future<bool> disableUser({required int id}) async {
    final url = Uri.parse('$baseUrl/update/profile/$id');

    final body = jsonEncode({'status': 'inactive'});

    try {
      final response = await http.put(url, headers: await _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================= ENABLE =================
  static Future<bool> enableUser({required int id}) async {
    final url = Uri.parse('$baseUrl/update/profile/$id');

    final body = jsonEncode({'status': 'active'});

    try {
      final response = await http.put(url, headers: await _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}