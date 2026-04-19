import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHoldTicket {
  // Returns the API base URL. Adjust as needed.
  static String get _baseUrl => 'https://your-api-base-url.com';

  /// Holds a ticket by ID. Requires a valid JWT [token].
  static Future<Map<String, dynamic>> holdTicket(String token, String ticketId) async {
    final url = Uri.parse('$_baseUrl/ticket/hold/$ticketId');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Try to decode the JSON, fallback to empty map on error
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    } else {
      throw Exception('Failed to hold ticket: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}