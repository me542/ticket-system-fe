import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiUpdateTicket {
  // 🔥 CHANGE THIS to your actual base URL
  static const String baseUrl = "http://localhost:8080/api/user";

  // 🔑 Common headers with JWT
  static Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ================================
  // ✅ ENDORSE TICKET
  // ================================
  static Future<Map<String, dynamic>> endorseTicket(
      String token, String ticketId) async {
    final url = Uri.parse("$baseUrl/ticket/endorse/$ticketId");

    final res = await http.put(url, headers: _headers(token));

    return _handleResponse(res);
  }

  // ================================
  // ✅ APPROVE TICKET
  // ================================
  static Future<Map<String, dynamic>> approveTicket(
      String token, String ticketId) async {
    final url = Uri.parse("$baseUrl/ticket/approve/$ticketId");

    final res = await http.put(url, headers: _headers(token));

    return _handleResponse(res);
  }

  // ================================
  // ✅ GRAB TICKET
  // ================================
  static Future<Map<String, dynamic>> grabTicket(
      String token, String ticketId) async {
    final url = Uri.parse("$baseUrl/ticket/grab/$ticketId");

    final res = await http.put(url, headers: _headers(token));

    return _handleResponse(res);
  }

  // ================================
  // ✅ RESOLVE TICKET
  // ================================
  static Future<Map<String, dynamic>> resolveTicket(
      String token, String ticketId) async {
    final url = Uri.parse("$baseUrl/ticket/resolve/$ticketId");

    final res = await http.put(url, headers: _headers(token));

    return _handleResponse(res);
  }

  // ================================
  // ✅ CANCEL TICKET
  // ================================
  static Future<Map<String, dynamic>> cancelTicket(
      String token, String ticketId) async {
    final url = Uri.parse("$baseUrl/ticket/cancel/$ticketId");

    final res = await http.put(url, headers: _headers(token));

    return _handleResponse(res);
  }

  // ================================
  // 🔥 COMMON RESPONSE HANDLER
  // ================================
  static Map<String, dynamic> _handleResponse(http.Response res) {
    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {
        "success": true,
        "message": data["message"],
        "data": data["data"],
      };
    } else {
      return {
        "success": false,
        "message": data["message"] ?? "Something went wrong",
      };
    }
  }
}



