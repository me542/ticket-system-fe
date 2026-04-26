import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiCategory {
  static const String _baseUrl = 'http://localhost:8080/api/user';

  static Future<List<Map<String, dynamic>>> fetchCategories({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        // backend returns ARRAY directly
        return List<Map<String, dynamic>>.from(body);
      }
    } catch (e) {
      // optionally handle error silently or rethrow
    }
    return [];
  }


  static Future<bool> addCategoryWithSubcategories({
    required String name,
    required List<String> subcategories,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/add-category/with-subcategory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'subcategories': subcategories}),
      );
      if (res.statusCode == 200) return true;
    } catch (e) {
    }
    return false;
  }

  // ─── PUT  update category name ─────────────────────────────────────────────
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

  // ─── DELETE category ───────────────────────────────────────────────────────
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

  // ─── DELETE subcategory ────────────────────────────────────────────────────
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