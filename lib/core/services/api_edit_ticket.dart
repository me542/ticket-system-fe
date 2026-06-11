import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class TicketService {
  // Local Development
  static const String _baseUrl =
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ) +
          '/api/user';

  // Production
  // static const String _baseUrl =
  //     String.fromEnvironment(
  //       'API_BASE_URL',
  //       defaultValue: 'http://idiyanale-be.bakawan-ai.com',
  //     ) +
  //     '/api/user';
  // Add this helper inside TicketService:
  static MediaType _mimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'xlsx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'doc':
        return MediaType('application', 'msword');
      default:
        return MediaType('application', 'octet-stream');
    }
  }


  static Future<Map<String, dynamic>> updateTicket({
    required String token,
    required String ticketId,
    required String subject,
    required String category,
    required String subcategory,
    required String institution,
    required String description,
    required String priority,
    required String endorser,
    List<PlatformFile> attachments = const [],
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/ticket/update/$ticketId',
      );

      final request = http.MultipartRequest(
        'PUT',
        uri,
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'subject': subject,
        'category': category,
        'subcategory': subcategory,
        'institution': institution,
        'description': description,
        'priority': priority,
        'endorser': endorser,
      });

      // Upload attachments
      for (final file in attachments) {
        final mime = _mimeType(file.extension);  // ✅ get MIME type

        if (file.bytes != null) {
          // WEB / Memory-based upload
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachments',
              file.bytes!,
              filename: file.name,
              contentType: mime,  // ✅ set contentType
            ),
          );
        } else if (file.path != null) {
          // MOBILE / Desktop upload
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments',
              file.path!,
              filename: file.name,       // ✅ also pass filename explicitly
              contentType: mime,         // ✅ set contentType
            ),
          );
        }
      }

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message':
        data['message'] ??
            'Failed to update ticket',
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}