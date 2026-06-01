import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiCategory {
  static const String _baseUrl =
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ) +
          '/api/user';

  // Prod
  //static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://idiyanale-be.bakawan-ai.com') + '/api/user';

  // ─────────────────────────────────────────────
  // ✅ GET ALL CATEGORIES
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchCategories({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final dataRaw = body['Data'] ?? body['data'] ?? [];

        if (dataRaw is! List) return [];

        return List<Map<String, dynamic>>.from(dataRaw);
      }
    } catch (e) {
      //
    }
    return [];
  }

  static Future<bool> addCategory({
    required String name,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/add-category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );
      return res.statusCode == 201;
    } catch (e) {
      //
    }
    return false;
  }

  static Future<bool> addSubcategory({
    required int categoryId,
    required String name,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/add-sub-category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'category_id': categoryId,
          'name': name,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      //
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ✅ UPDATE CATEGORY
  // ─────────────────────────────────────────────
  static Future<bool> updateCategory({
    required int categoryId,
    required String newName,
    required String token,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/update-categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName}),
      );
      return res.statusCode == 200;
    } catch (e) {
      //
    }
    return false;
  }

  static Future<bool> updateSubcategoryName({
    required int subcategoryId,
    required String name,
    required String token,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/update-sub-categories/$subcategoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );
      return res.statusCode == 200;
    } catch (e) {
      //
    }
    return false;
  }

  static Future<bool> updateSubcategoryDescription({
    required int subcategoryId,
    required String description,
    required String token,
  }) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/subcategories/$subcategoryId/description'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'description': description}),
      );
      return res.statusCode == 200;
    } catch (e) {
      //
    }
    return false;
  }

  static Future<bool> deleteCategory({
    required int categoryId,
    required String token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/delete-category/$categoryId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200;
    } catch (e) {
      //
    }
    return false;
  }

  static Future<bool> deleteSubcategory({
    required int subcategoryId,
    required String token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/delete-subcategory/$subcategoryId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200;
    } catch (e) {
      //
    }
    return false;
  }
}