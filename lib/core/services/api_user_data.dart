import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_login.dart';

class ApiGetUser {
  static const String baseUrl = 'http://localhost:8080/api/user/list/all/users';

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
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List data = jsonResponse['data'] ?? [];

        return data.map<Map<String, String>>((user) {
          final fullName = ((user['full_name'] as String?)?.trim().isNotEmpty == true)
              ? user['full_name']!.trim()
              : (user['username'] ?? 'Unknown');

          return {
            'id': user['user_id']?.toString() ?? '',
            'name': fullName,
            'username': user['username']?.toString() ?? '',
            'email': user['email']?.toString() ?? 'N/A',
            'position': (user['position'] as String?)?.trim().isNotEmpty == true
                ? user['position']!.trim()
                : 'N/A',
            'role': (user['role'] as String?)?.trim().isNotEmpty == true
                ? user['role']!.trim()
                : 'N/A',
            // ← ADDED: status field
            'status': (user['status'] as String?)?.trim().isNotEmpty == true
                ? user['status']!.trim()
                : 'active',
            'initials': fullName.isNotEmpty
                ? fullName
                .split(' ')
                .map((e) => e[0].toUpperCase())
                .take(2)
                .join()
                : '',
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