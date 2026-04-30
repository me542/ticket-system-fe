import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiCategory {
  static const String _baseUrl = 'http://localhost:8080/api/user';

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

      debugPrint('>>> fetchCategories status: ${res.statusCode}');
      debugPrint('>>> fetchCategories body: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        // Debug: print all top-level keys to confirm casing
        debugPrint('>>> body keys: ${(body as Map).keys.toList()}');

        // Go's ResponseModel uses capital 'Data'
        final dataRaw = body['Data'] ?? body['data'] ?? [];
        debugPrint('>>> Data value: $dataRaw');

        if (dataRaw is! List) return [];

        return List<Map<String, dynamic>>.from(dataRaw);
      }
    } catch (e) {
      debugPrint('>>> fetchCategories ERROR: $e');
    }
    return [];
  }

  // ─────────────────────────────────────────────
  // ✅ ADD CATEGORY
  // ─────────────────────────────────────────────
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

      debugPrint('>>> addCategory ${res.statusCode}: ${res.body}');
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('>>> addCategory ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ✅ ADD SUBCATEGORY
  // ─────────────────────────────────────────────
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

      debugPrint('>>> addSubcategory ${res.statusCode}: ${res.body}');
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('>>> addSubcategory ERROR: $e');
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

      debugPrint('>>> updateCategory ${res.statusCode}: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('>>> updateCategory ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ✅ UPDATE SUBCATEGORY NAME
  // ─────────────────────────────────────────────
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

      debugPrint('>>> updateSubcategoryName ${res.statusCode}: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('>>> updateSubcategoryName ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ✅ UPDATE DESCRIPTION
  // ─────────────────────────────────────────────
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

      debugPrint('>>> updateDescription ${res.statusCode}: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('>>> updateDescription ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ✅ DELETE CATEGORY
  // ─────────────────────────────────────────────
  static Future<bool> deleteCategory({
    required int categoryId,
    required String token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/delete-category/$categoryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('>>> deleteCategory ${res.statusCode}: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('>>> deleteCategory ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ✅ DELETE SUBCATEGORY
  // ─────────────────────────────────────────────
  static Future<bool> deleteSubcategory({
    required int subcategoryId,
    required String token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/delete-subcategory/$subcategoryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('>>> deleteSubcategory ${res.statusCode}: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('>>> deleteSubcategory ERROR: $e');
    }
    return false;
  }
}