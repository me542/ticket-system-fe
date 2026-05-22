import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_login.dart';

class ApiReassignEndorser {
  // static const String baseUrl =
  //     String.fromEnvironment(
  //       'API_BASE_URL',
  //       defaultValue: 'http://localhost:8080',
  //     ) +
  //         '/api/user';

  // Prod
  static const String baseUrl =
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://idiyanale-be.bakawan-ai.com',
      ) +
          '/api/user';

  // ─────────────────────────────────────────────
  // HEADERS
  // ─────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await ApiLogin.getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ─────────────────────────────────────────────
  // REASSIGN ENDORSER
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> reassignEndorser({
    required String ticketId,
    required String newEndorser,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/tickets/$ticketId/reassign-endorser',
        ),
        headers: await _headers(),
        body: jsonEncode({
          "ticket_id": ticketId,
          "new_endorser": newEndorser,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"],
          "data": data["data"],
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to reassign endorser",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error: $e",
      };
    }
  }
}