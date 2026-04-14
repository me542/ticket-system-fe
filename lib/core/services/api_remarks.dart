import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_login.dart';

class ApiRemarks {
  static const String _baseUrl = 'http://localhost:8080/api/user';

  // ─── Fetch all remarks for a ticket ──────────────────────────────────────

  /// Returns a list of remark maps sorted ascending by created_at.
  /// Each item is the unwrapped remark object (not the {"remark": {...}} wrapper).
  static Future<List<Map<String, dynamic>>> fetchRemarks(String ticketId) async {
    final token = await ApiLogin.getToken();
    if (token == null) throw Exception('Not authenticated');

    final res = await http.get(
      Uri.parse('$_baseUrl/ticket/$ticketId/remarks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint('📝 GET remarks [$ticketId] → ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final raw = body['data'];

      if (raw == null) {
        debugPrint('⚠️ No remarks (null)');
        return [];
      }

      if (raw is! List) {
        debugPrint('⚠️ Unexpected format: $raw');
        return [];
      }

      return raw.map<Map<String, dynamic>>((e) {
        if (e is Map && e.containsKey('remark')) {
          return Map<String, dynamic>.from(e['remark']);
        }
        return Map<String, dynamic>.from(e);
      }).toList();
    }


    throw Exception('Failed to fetch remarks: ${res.statusCode}');
  }

  // ─── Post a new remark ────────────────────────────────────────────────────

  /// Creates a remark and returns the saved remark map from the server.
  static Future<Map<String, dynamic>> postRemark({
    required String ticketId,
    required String userId,
    required String message,
    String username = '',
  }) async {
    if (ticketId.isEmpty || userId.isEmpty || message.trim().isEmpty) {
      throw ArgumentError('ticketId, userId, and message are required');
    }

    final token = await ApiLogin.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{
      'ticket_id': ticketId,
      'user_id':   userId,
      'message':   message.trim(),
    };
    if (username.isNotEmpty) body['username'] = username;

    final res = await http.post(
      Uri.parse('$_baseUrl/ticket/remark'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint('📤 POST remark [$ticketId] → ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(body['data'] as Map);
    }

    final errorBody = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(errorBody['message'] ?? 'Failed to post remark');
  }
}