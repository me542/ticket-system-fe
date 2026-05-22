import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_login.dart';

class ApiInstitutionPosition {
  //static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080') + '/api/user';

  // Prod
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://idiyanale-be.bakawan-ai.com') + '/api/user';


  // ─────────────────────────────────────────────
  // HEADERS
  // ─────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await ApiLogin.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────
  // INSTITUTIONS
  // ─────────────────────────────────────────────

  // GET /get/all-insitutions
  static Future<List<Map<String, dynamic>>> getInstitutions() async {
    final res = await http.get(
      Uri.parse('$baseUrl/get/all-institutions'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch institutions');
    }
  }

  // POST /add-institution
  static Future<bool> createInstitution({
    required String name,
    String status = 'active',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add-institution'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'status': status,
      }),
    );

    return res.statusCode == 200;
  }

  // PUT /institution/update/:id  — updates status only
  static Future<bool> updateInstitutionStatus({
    required int id,
    required String status,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/institution/update/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'status': status,
      }),
    );

    return res.statusCode == 200;
  }

  // ─────────────────────────────────────────────
  // POSITIONS
  // ─────────────────────────────────────────────

  // GET /get/all-positions
  static Future<List<Map<String, dynamic>>> getPositions() async {
    final res = await http.get(
      Uri.parse('$baseUrl/get/all-positions'),
      headers: await _headers(),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch positions');
    }
  }

  // POST /add-position
  static Future<bool> createPosition({
    required String name,
    required int institutionId,
    String status = 'active',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add-position'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'institution_id': institutionId,
        'status': status,
      }),
    );

    return res.statusCode == 200;
  }

  // PUT /position-name/update/:id  — updates name only
  static Future<bool> updatePositionName({
    required int id,
    required String name,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/position-name/update/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
      }),
    );

    return res.statusCode == 200;
  }
}