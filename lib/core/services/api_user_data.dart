import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiGetUser {

  //static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080') + '/api/user/list/all/users';

  // Prod
  static const String baseUrl =
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://idiyanale-be.bakawan-ai.com',
      ) +
          '/api/user/list/all/users';

  /// Fetch all users from backend
  static Future<List<Map<String, String>>> fetchUsers() async {
    try {
      final token = await ApiLogin.getToken();

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
        jsonDecode(response.body);

        final List data = jsonResponse['data'] ?? [];

        return data.map<Map<String, String>>((user) {
          // ================= FIRST & LAST NAME =================
          final firstName =
              user['first_name']?.toString().trim() ?? '';

          final lastName =
              user['last_name']?.toString().trim() ?? '';

          // ================= FULL NAME =================
          final fullName =
          ('$firstName $lastName').trim().isNotEmpty
              ? ('$firstName $lastName').trim()
              : (user['username']?.toString() ?? 'Unknown');

          return {
            'id': user['user_id']?.toString() ?? '',

            // Individual fields
            'first_name': firstName,
            'last_name': lastName,

            // Combined full name
            'full_name': fullName,

            'username': user['username']?.toString() ?? '',
            'email': user['email']?.toString() ?? '',

            'institution': (user['institution']?.toString().trim().isNotEmpty ?? false)
                ? user['institution'].toString().trim()
                : '',

            'position':
            (user['position'] as String?)
                ?.trim()
                .isNotEmpty ==
                true
                ? user['position']!.trim()
                : '',

            'role':
            (user['role'] as String?)
                ?.trim()
                .isNotEmpty ==
                true
                ? user['role']!.trim()
                : '',

            'status':
            (user['status'] as String?)
                ?.trim()
                .isNotEmpty ==
                true
                ? user['status']!.trim()
                : 'active',

            'created_at': user['created_at']?.toString() ?? '',

            // ================= INITIALS =================
            'initials': [
              if (firstName.isNotEmpty)
                firstName[0].toUpperCase(),
              if (lastName.isNotEmpty)
                lastName[0].toUpperCase(),
            ].join(),
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e, stack) {
      return [];
    }
  }
}

class ApiUserData {
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
}