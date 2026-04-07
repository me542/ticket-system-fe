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
      print('❌ Error creating user: $e');
      return false;
    }
  }

  // ================= UPDATE =================
  static Future<bool> updateUser({
    required String username,
    required String fullname,
    required String email,
    String? password, // optional
    required String role,
    required String position,
  }) async {
    final url = Uri.parse('$baseUrl/update');

    final body = jsonEncode({
      'username': username,
      'full_name': fullname,
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
      'role': role,
      'position': position,
    });

    try {
      final response = await http.put(url, headers: await _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  // ================= DISABLE =================
  static Future<bool> disableUser({required String email}) async {
    final url = Uri.parse('$baseUrl/disable');

    final body = jsonEncode({'email': email});

    try {
      final response = await http.put(url, headers: await _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error disabling user: $e');
      return false;
    }
  }

  // ================= ENABLE =================
  static Future<bool> enableUser({required String email}) async {
    final url = Uri.parse('$baseUrl/enable');

    final body = jsonEncode({'email': email});

    try {
      final response = await http.put(url, headers: await _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error enabling user: $e');
      return false;
    }
  }
}



