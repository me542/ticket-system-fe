import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiForgotPassword {
  static const String baseUrl = 'http://localhost:8080/api';
  // replace with your PC IP if testing on a real device

  // -----------------------------
  // STEP 1: Request OTP
  // -----------------------------
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Use lowercase keys matching backend
      String? resetToken;
      if (data.containsKey('data') && data['data'] != null) {
        resetToken = data['data']['reset_token']?.toString();
      }

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Request completed',
        'token': resetToken, // dev-only
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // -----------------------------
  // STEP 2: Verify OTP
  // -----------------------------
  // -----------------------------
  static Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['Message'],
        'token': data['Data']?['token'], // to use in reset-password
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // -----------------------------
  // STEP 3: Reset Password
  // -----------------------------
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'new_password': newPassword}),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['Message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }
}
