import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiHoldTicket {
  static String get _baseUrl =>
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      );

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
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    } else {
      throw Exception(
        'Failed to hold ticket: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}