import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiLogin {
  static const String loginUrl = 'http://localhost:8080/api/user/login';

  static String? _token;
  static String? _username;
  static String? _role;

  /// Login user and save token + user info
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('🔹 Login status: ${response.statusCode}');
      print('🔹 Login response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final userData = data['data'];

        if (userData != null) {
          _token = userData['token'];
          _username = userData['username']; // ⚠️ adjust if different
          _role = userData['role'];         // ⚠️ adjust if different

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('user_token', _token ?? '');
          await prefs.setString('username', _username ?? '');
          await prefs.setString('role', _role ?? '');
        }

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('💥 Login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get token
  static Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('user_token');
    return _token;
  }

  /// ✅ Get username
  static Future<String> getUsername() async {
    if (_username != null) return _username!;

    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Unknown';
    return _username!;
  }

  /// ✅ Get role
  static Future<String> getRole() async {
    if (_role != null) return _role!;

    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString('role') ?? 'User';
    return _role!;
  }

  /// ✅ Get initials
  static Future<String> getInitials() async {
    final name = await getUsername();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  /// Logout
  static Future<void> logout() async {
    _token = null;
    _username = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
