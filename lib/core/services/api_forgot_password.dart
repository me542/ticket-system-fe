import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiForgotPassword {
  static const String baseUrl = 'http://localhost:8080/api';
  // replace 192.168.1.100 with your PC IP if testing on real device

  // STEP 1: Request code
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['Data']?['reset_token'], // dev-only
          'message': data['Message'],
        };
      } else {
        return {
          'success': false,
          'error': data['Message'] ?? 'Failed to request reset token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error',
      };
    }
  }

  // STEP 2: Verify code
  static Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['Data']?['token'],
          'message': data['Message'],
        };
      } else {
        return {
          'success': false,
          'error': data['Message'] ?? 'Invalid or expired code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error',
      };
    }
  }

  // STEP 3: Reset password
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

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['Message'],
        };
      } else {
        return {
          'success': false,
          'error': data['Message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error',
      };
    }
  }
}
