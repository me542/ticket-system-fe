import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'api_user_data.dart';

class ApiLogin {
  static const String loginUrl = 'http://localhost:8080/api/user/login';

  static String? _token;
  static String? _username;
  static String? _role;

  // ✅ NEW
  static String? _userId;

  // ── sessionStorage helpers (web only) ─────────────────────────────────────

  static void _sessionSet(String key, String value) {
    if (kIsWeb) {
      html.window.sessionStorage[key] = value;
    }
  }

  static String? _sessionGet(String key) {
    if (kIsWeb) {
      return html.window.sessionStorage[key];
    }
    return null;
  }

  static void _sessionClear() {
    if (kIsWeb) {
      html.window.sessionStorage.clear();
    }
  }

  // ── Save to both sessionStorage (web) and SharedPreferences (mobile) ──────

  // 🔥 UPDATED: added userId
  static Future<void> _saveToStorage(
      String token,
      String username,
      String role,
      String userId,
      ) async {
    // Web
    _sessionSet('user_token', token);
    _sessionSet('username', username);
    _sessionSet('role', role);
    _sessionSet('user_id', userId); // ✅ NEW

    // Mobile
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', token);
      await prefs.setString('username', username);
      await prefs.setString('role', role);
      await prefs.setString('user_id', userId); // ✅ NEW
    }
  }

  static Future<void> _clearStorage() async {
    _sessionClear();

    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  static Future<String?> _readFromStorage(String key) async {
    if (kIsWeb) {
      return _sessionGet(key);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // ── Login ──────────────────────────────────────────────────────────────────

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // ⚠️ Your backend uses lowercase "data"
        final userData = data['data'];

        if (userData != null) {
          _token    = userData['token'];
          _username = userData['username'];
          _role     = userData['role'];

          // ✅ NEW: extract user_id
          _userId   = userData['user_id']?.toString();

          if (_token == null || _token!.isEmpty) {
            return {'success': false, 'error': 'Invalid token from server'};
          }

          // 🔥 UPDATED CALL
          await _saveToStorage(
            _token!,
            _username ?? '',
            _role ?? '',
            _userId ?? '',
          );

          if (_role == null || _role!.isEmpty) {
            await _fetchAndCacheRole();
          }
        }

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Fetch and cache role ───────────────────────────────────────────────────

  static Future<void> _fetchAndCacheRole() async {
    try {
      final users = await ApiGetUser.fetchUsers();
      final currentUsername = _username ?? '';

      final currentUser = users.firstWhere(
            (u) => u['username']?.toLowerCase() == currentUsername.toLowerCase(),
        orElse: () => {},
      );

      final role = currentUser['role'] ?? '';

      if (role.isNotEmpty) {
        _role = role;
        _sessionSet('role', role);

        if (!kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('role', role);
        }
      }
    } catch (e) {
      //
    }
  }

  // ── isLoggedIn ─────────────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final token = await _readFromStorage('user_token');
    return (token ?? '').isNotEmpty;
  }

  // ── getToken ───────────────────────────────────────────────────────────────

  static Future<String?> getToken({String? id}) async {
    if (_token != null) return _token;
    _token = await _readFromStorage('user_token');
    return _token;
  }

  // ── getUserId (🔥 THIS FIXES YOUR ERROR) ───────────────────────────────────

  static Future<String?> getUserId() async {
    if (_userId != null) return _userId;
    _userId = await _readFromStorage('user_id');
    return _userId;
  }

  // ── getUsername ────────────────────────────────────────────────────────────

  static Future<String> getUsername({String? id}) async {
    if (_username != null) return _username!;
    _username = await _readFromStorage('username') ?? 'Unknown';
    return _username!;
  }

  // ── getRole ────────────────────────────────────────────────────────────────

  static Future<String> getRole({String? id}) async {
    if (_role != null && _role!.isNotEmpty) return _role!;

    final savedRole = await _readFromStorage('role') ?? '';
    if (savedRole.isNotEmpty) {
      _role = savedRole;
      return _role!;
    }

    await _fetchAndCacheRole();
    return _role ?? '';
  }

  // ── getInitials ────────────────────────────────────────────────────────────

  static Future<String> getInitials({String? id}) async {
    final name = await getUsername();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // ── logout ─────────────────────────────────────────────────────────────────

  static Future<void> logout({String? id}) async {
    _token    = null;
    _username = null;
    _role     = null;
    _userId   = null; // ✅ NEW

    await _clearStorage();
  }
}
