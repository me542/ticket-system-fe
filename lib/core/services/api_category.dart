import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiCategory {
  // ✅ FIXED: removed /get (this caused your 404 error)
  static const String _baseUrl = 'http://localhost:8080/api/user';

  // ─────────────────────────────────────────────────────────────
  // ✅ GET ALL CATEGORIES (with subcategories)
  // FIX: /get/categories → /categories
  // ─────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchCategories({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/get/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('>>> fetchCategories ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(
          body['data'] ?? body['Data'] ?? [],
        );
      }
    } catch (e) {
      debugPrint('>>> fetchCategories ERROR: $e');
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ ADD CATEGORY
  // POST /add-category
  // ─────────────────────────────────────────────────────────────
  static Future<bool> addCategory({
    required String name,
    required String token,
  }) async {
    try {
      final payload = jsonEncode({'name': name});

      debugPrint('>>> addCategory PAYLOAD: $payload');

      final res = await http.post(
        Uri.parse('$_baseUrl/add-category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      debugPrint('>>> addCategory ${res.statusCode}: ${res.body}');
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('>>> addCategory ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ SAVE TEMPLATE
  // POST /template/save
  // ─────────────────────────────────────────────────────────────
  static Future<bool> saveTemplate({
    required String category,
    required String subcategory,
    required String description,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/template/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'category': category,
          'subcategory': subcategory,
          'description': description,
        }),
      );

      debugPrint('>>> saveTemplate ${res.statusCode}: ${res.body}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('>>> saveTemplate ERROR: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ ADD SUBCATEGORY
  // POST /add-sub-category
  // ─────────────────────────────────────────────────────────────
  static Future<bool> addSubcategory({
    required int categoryId,
    required String name,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/categories/$categoryId/sub-categories');

      final payload = {'category_id': categoryId, 'name': name};

      debugPrint('>>> addSubcategory PAYLOAD: $payload');

      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('>>> addSubcategory ${res.statusCode}: ${res.body}');

      return res.statusCode == 201;
    } catch (e) {
      debugPrint('>>> addSubcategory ERROR: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ UPDATE CATEGORY
  // PUT /update-categories/:id
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // ✅ UPDATE SUBCATEGORY NAME
  // PUT /update-sub-categories/:id
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // ✅ UPDATE SUBCATEGORY DESCRIPTION
  // PATCH /subcategories/:id/description
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // ✅ DELETE CATEGORY
  // DELETE /delete-category/:id
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // ✅ DELETE SUBCATEGORY
  // DELETE /delete-subcategory/:id
  // ─────────────────────────────────────────────────────────────
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
