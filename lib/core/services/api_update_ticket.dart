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
  // ✅ ENDORSE TICKET
  // PUT /api/user/ticket/endorse/:id
  // ================================
  static Future<Map<String, dynamic>> endorseTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/endorse/$ticketId", token);
  }

  // ================================
  // ✅ APPROVE TICKET
  // PUT /api/user/ticket/approve/:id
  // ================================
  static Future<Map<String, dynamic>> approveTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/approve/$ticketId", token);
  }

  // ================================
  // ✅ GRAB/ASSIGN TICKET
  // PUT /api/user/ticket/grab/:id
  // ================================
  static Future<Map<String, dynamic>> assignTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/grab/$ticketId", token);
  }

  // ================================
  // ✅ UNGRAB/UNASSIGN TICKET
  // PUT /api/user/ticket/ungrab/:id
  // ================================
  static Future<Map<String, dynamic>> ungrabTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/ungrab/$ticketId", token);
  }

  // ================================
  // ✅ RESOLVE TICKET
  // PUT /api/user/ticket/resolve/:id
  // ================================
  static Future<Map<String, dynamic>> resolveTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/resolve/$ticketId", token);
  }

  // ================================
  // ✅ CANCEL TICKET
  // PUT /api/user/ticket/cancel/:id
  // ================================
  static Future<Map<String, dynamic>> cancelTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/cancel/$ticketId", token);
  }

  // ================================
  // ⚠️  REJECT TICKET
  // No dedicated backend route — falls back to cancel.
  // Add PUT /ticket/reject/:id on backend to use its own route.
  // ================================
  static Future<Map<String, dynamic>> rejectTicket(
      String token, String ticketId) async {
    return _put("$baseUrl/ticket/cancel/$ticketId", token);
  }

  // ================================
  // 🔥 INTERNAL PUT HELPER
  // Safe: handles both JSON and plain-text error responses
  // ================================
  static Future<Map<String, dynamic>> _put(
      String url, String token, [Map<String, dynamic>? body]) async {
    try {
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: body != null ? jsonEncode(body) : null,
      );

      // ── Try to parse as JSON ──────────────────────────────────────────────
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        // Response is plain text (e.g. "Cannot PUT /api/...")
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return {"success": true, "message": res.body};
        } else {
          throw Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      }

      // ── JSON parsed successfully ──────────────────────────────────────────
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
}