import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_user_data.dart';

class ApiLogin {
  static const String loginUrl = 'http://localhost:8080/api/user/login';

  static String? _token;
  static String? _username;
  static String? _role;

  /// Login user and save token + user info
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? id,
  }) async {
    final tag = id ?? 'ApiLogin.login';
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('🔹 [$tag] Login status: ${response.statusCode}');
      print('🔹 [$tag] Login response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final userData = data['data'];

        if (userData != null) {
          _token = userData['token'];
          _username = userData['username'];
          _role = userData['role'];

          print('🔑 TOKEN: $_token');
          print('🔑 USERNAME: $_username');
          print('🔑 ROLE FROM LOGIN: $_role');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', _token ?? '');
          await prefs.setString('username', _username ?? '');
          await prefs.setString('role', _role ?? '');

          // If role is empty from login response, fetch from users list
          if (_role == null || _role!.isEmpty) {
            print('⚠️ Role empty from login, fetching from users list...');
            await _fetchAndCacheRole();
          }

          print('✅ [$tag] Saved token and user info to SharedPreferences');
        }

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        print('❌ [$tag] Login failed: ${error['message']}');
        return {
          'success': false,
          'error': error['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('💥 [$tag] Login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch role from users list and cache it
  static Future<void> _fetchAndCacheRole() async {
    try {
      final users = await ApiGetUser.fetchUsers();
      final currentUsername = _username ?? '';

      final currentUser = users.firstWhere(
            (u) => u['username']?.toLowerCase() == currentUsername.toLowerCase(),
        orElse: () => {},
      );

      final role = currentUser['role'] ?? '';
      print('✅ Fetched role from users list: $role');

      if (role.isNotEmpty) {
        _role = role;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', role);
        print('✅ Role cached to SharedPreferences: $role');
      }
    } catch (e) {
      print('💥 Error fetching role from users list: $e');
    }
  }

  /// ── NEW: quick check used by main() and auth guards ──────────────────────
  /// Returns true if a non-empty token exists in SharedPreferences.
  /// Does NOT make a network call — purely local.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token') ?? '';
    return token.isNotEmpty;
  }

  /// Get token
  static Future<String?> getToken({String? id}) async {
    final tag = id ?? 'ApiLogin.getToken';
    if (_token != null) {
      print('🔹 [$tag] Returning cached token');
      return _token;
    }

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('user_token');
    print('🔹 [$tag] Loaded token from SharedPreferences: $_token');
    return _token;
  }

  /// Get username
  static Future<String> getUsername({String? id}) async {
    final tag = id ?? 'ApiLogin.getUsername';
    if (_username != null) {
      print('🔹 [$tag] Returning cached username: $_username');
      return _username!;
    }

    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Unknown';
    print('🔹 [$tag] Loaded username from SharedPreferences: $_username');
    return _username!;
  }

  /// Get role — falls back to fetching from users list if empty
  static Future<String> getRole({String? id}) async {
    final tag = id ?? 'ApiLogin.getRole';

    if (_role != null && _role!.isNotEmpty) {
      print('🔹 [$tag] Returning cached role: $_role');
      return _role!;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('role') ?? '';

    if (savedRole.isNotEmpty) {
      _role = savedRole;
      print('🔹 [$tag] Loaded role from SharedPreferences: $_role');
      return _role!;
    }

    print('⚠️ [$tag] Role not found in cache, fetching from users list...');
    await _fetchAndCacheRole();

    print('🔹 [$tag] Final role: $_role');
    return _role ?? '';
  }

  /// Get initials
  static Future<String> getInitials({String? id}) async {
    final tag = id ?? 'ApiLogin.getInitials';
    final name = await getUsername(id: tag);
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    print('🔹 [$tag] Initials: $initials');
    return initials;
  }

  /// Logout — clears everything and returns to LoginScreen
  static Future<void> logout({String? id}) async {
    final tag = id ?? 'ApiLogin.logout';
    _token = null;
    _username = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ [$tag] Logged out and cleared SharedPreferences');
  }
}