import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiGetInstiAndPosition {
  // static const String baseUrl =
  //     String.fromEnvironment(
  //       'API_BASE_URL',
  //       defaultValue: 'http://localhost:8080',
  //     ) +
  //         '/api';

  //Prod
  static const String baseUrl =
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://idiyanale-be.bakawan-ai.com',
      ) +
          '/api';

  // ─────────────────────────────────────────────
  // No auth headers — these are public endpoints
  // ─────────────────────────────────────────────
  static Map<String, String> _headers() {
    return {'Content-Type': 'application/json'};
  }

  // ─────────────────────────────────────────────
  // GET /api/user/get/all-institutions  (PUBLIC)
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getInstitutions() async {
    try {
      final res = await http
          .get(
        Uri.parse('$baseUrl/get/all-institutions'),
        headers: _headers(),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('getInstitutions → ${res.statusCode}: ${res.body}');

      if (res.statusCode == 401) {
        throw Exception(
          'Server requires auth for /get/all-institutions. Make this route public in the backend.',
        );
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final raw = data['data'];
        if (raw == null) {
          throw Exception('Response missing "data" key: ${res.body}');
        }
        return List<Map<String, dynamic>>.from(raw);
      } else {
        throw Exception(
          data['message'] ?? 'Failed to fetch institutions (${res.statusCode})',
        );
      }
    } on FormatException catch (e) {
      throw Exception('Invalid JSON from server: $e');
    }
  }

  // ─────────────────────────────────────────────
  // GET /api/user/get/all-positions  (PUBLIC)
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPositions() async {
    try {
      final res = await http
          .get(
        Uri.parse('$baseUrl/get/all-positions'),
        headers: _headers(),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('getPositions → ${res.statusCode}: ${res.body}');

      if (res.statusCode == 401) {
        throw Exception(
          'Server requires auth for /get/all-positions. Make this route public in the backend.',
        );
      }

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final raw = data['data'];
        if (raw == null) {
          throw Exception('Response missing "data" key: ${res.body}');
        }
        return List<Map<String, dynamic>>.from(raw);
      } else {
        throw Exception(
          data['message'] ?? 'Failed to fetch positions (${res.statusCode})',
        );
      }
    } on FormatException catch (e) {
      throw Exception('Invalid JSON from server: $e');
    }
  }
}