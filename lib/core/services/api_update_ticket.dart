import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiUpdateTicket {
  static const String baseUrl = "http://localhost:8080/api/user";

  static Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ================================
  // 🔥 INTERNAL PUT HELPER
  // ================================
  static Future<Map<String, dynamic>> _put(
      String url, String token, [Map<String, dynamic>? body]) async {
    return _request(http.put, url, token, body);
  }

  // ================================
  // 🔥 INTERNAL PATCH HELPER (NEW)
  // ================================
  static Future<Map<String, dynamic>> _patch(
      String url, String token, [Map<String, dynamic>? body]) async {
    return _request(http.patch, url, token, body);
  }

  // ================================
  // 🔥 CORE REQUEST HANDLER
  // ================================
  static Future<Map<String, dynamic>> _request(
      Future<http.Response> Function(Uri, {Map<String, String>? headers, Object? body}) method,
      String url,
      String token,
      Map<String, dynamic>? body,
      ) async {
    try {
      final res = await method(
        Uri.parse(url),
        headers: _headers(token),
        body: body != null ? jsonEncode(body) : null,
      );

      Map<String, dynamic>? data;

      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return {"success": true, "message": res.body};
        } else {
          throw Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          "success": true,
          "message": data["message"] ?? "Success",
          "data": data["data"],
        };
      } else {
        throw Exception(
          data["message"] ?? data["error"] ?? "HTTP ${res.statusCode}",
        );
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error: ${e.message}");
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  // ================================
  // ✅ ENDORSE TICKET
  // ================================
  static Future<Map<String, dynamic>> endorseTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/endorse/$ticketId", token);
  }

  // ================================
  // ✅ APPROVE TICKET
  // ================================
  static Future<Map<String, dynamic>> approveTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/approve/$ticketId", token);
  }

  // ================================
  // ✅ GRAB/ASSIGN TICKET
  // ================================
  static Future<Map<String, dynamic>> assignTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/grab/$ticketId", token);
  }

  // ================================
  // ✅ UNGRAB/UNASSIGN TICKET
  // ================================
  static Future<Map<String, dynamic>> ungrabTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/ungrab/$ticketId", token);
  }

  // ================================
  // ✅ RESOLVE TICKET
  // ================================
  static Future<Map<String, dynamic>> resolveTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/resolve/$ticketId", token);
  }

  // ================================
  // ✅ CANCEL TICKET
  // ================================
  static Future<Map<String, dynamic>> cancelTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/cancel/$ticketId", token);
  }

  // ================================
  // ⚠️ REJECT TICKET (fallback)
  // ================================
  static Future<Map<String, dynamic>> rejectTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/cancel/$ticketId", token);
  }

  // ================================
  // ✅ HOLD TICKET (PATCH)
  // ================================
  static Future<Map<String, dynamic>> holdTicket(
      String token, String ticketId) async {
    return _patch("$baseUrl/ticket/hold/$ticketId", token);
  }

  // ================================
  // ✅ RESUME TICKET (PATCH)
  // ================================
  static Future<Map<String, dynamic>> resumeTicket(
      String token, String ticketId) async {
    return _patch("$baseUrl/ticket/unhold/$ticketId", token);
  }
}
