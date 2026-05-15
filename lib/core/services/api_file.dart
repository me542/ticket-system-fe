import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';   // ← add this import
import 'package:file_picker/file_picker.dart';
import 'api_login.dart';

class ApiTicket {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL',
          defaultValue: 'http://idiyanale-be.bakawan-ai.com') +
          '/api/user';



  /// Maps file extension → MIME type (must match backend allowedTypes exactly)
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
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  /// CREATE TICKET
  static Future<String?> createTicket({
    required String subject,
    required String tickettype,
    required String category,
    required String subcategory,
    required String institution,
    required int priority,
    required String description,
    required String endorser,
    String assignee = '',
    String approver = '',
    PlatformFile? file,
  }) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/ticket/create');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['subject']     = subject;
      request.fields['tickettype']  = tickettype;
      request.fields['category']    = category;
      request.fields['subcategory'] = subcategory;
      request.fields['institution'] = institution;
      request.fields['priority']    = priority.toString();
      request.fields['description'] = description;
      request.fields['endorser']    = endorser;
      request.fields['assignee']    = assignee;
      request.fields['approver']    = approver;

      // ✅ Explicitly set Content-Type so backend validation passes
      if (file != null && file.bytes != null) {
        final mime = _mimeType(file.extension);

        debugPrint('📎 Attaching: ${file.name} | ext: ${file.extension} | mime: $mime');

        request.files.add(
          http.MultipartFile.fromBytes(
            'attachments',
            file.bytes!,
            filename: file.name,
            contentType: mime,   // ✅ this was missing — backend was getting empty Content-Type
          ),
        );
      }

      final streamedResponse = await request.send();
      final resBody = await streamedResponse.stream.bytesToString();

      debugPrint('📤 STATUS: ${streamedResponse.statusCode}');
      debugPrint('📤 BODY:   $resBody');

      if (streamedResponse.statusCode == 201) {
        final decoded = jsonDecode(resBody);
        final ticketCode = decoded['data']?['ticket_code'] as String?;
        return ticketCode ?? '';
      }

      return null;
    } catch (e) {
      debugPrint('❌ createTicket error: $e');
      return null;
    }
  }

  /// GET ALL TICKETS
  static Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/list/all/tickets');
      final res =
      await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['data'];

        if (raw is List) {
          return raw.map<Map<String, dynamic>>((e) {
            final Map<String, dynamic> t =
            (e['ticket'] is Map)
                ? Map<String, dynamic>.from(e['ticket'] as Map)
                : Map<String, dynamic>.from(e as Map);

            return {
              'ticket_id':          t['ticket_id']          ?? '',
              'subject':            t['subject']             ?? '',
              'category':           t['category']            ?? '',
              'description':        t['description']         ?? '',
              'institution':        t['institution']         ?? '',
              'tickettype':         t['tickettype']          ?? '',
              'priority':           t['priority']            ?? '',
              'status':             t['status']              ?? '',
              'username':           t['username']            ?? '',
              'assignee':           t['assignee']            ?? '',
              'endorser':           t['endorser']            ?? '',
              'approver':           t['approver']            ?? '',
              'created_at':         t['created_at']          ?? '',
              'updated_at':         t['updated_at']          ?? '',
              'cancelled_by':       t['cancelled_by']        ?? '',
              'cancelled_at':       t['cancelled_at'],
              'started_at':         t['started_at'],
              'resolved_at':        t['resolved_at'],
              'resolution_minutes': t['resolution_minutes']  ?? '',
              'resolution_time':    t['resolution_time']     ?? '',
            };
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET TICKETS FOR LOGGED-IN USER
  static Future<List<dynamic>> getUserTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/ticket/user');
      final res =
      await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET SINGLE TICKET BY SR NUMBER
  static Future<Object?> getTicketByID(String ticketID) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/tickets/$ticketID');
      final res =
      await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final Map<String, dynamic> flat = {};

        dynamic raw = decoded['data'];
        if (raw is List && raw.isNotEmpty) raw = raw.first;

        if (raw is Map<String, dynamic>) {
          flat.addAll(raw);
          for (final key in [
            'ticket', 'user', 'endorser_info',
            'approver_info', 'resolver_info'
          ]) {
            final sub = raw[key];
            if (sub is Map<String, dynamic>) {
              sub.forEach((k, v) => flat.putIfAbsent(k, () => v));
            }
          }
        }
        return flat.isEmpty ? null : flat;
      }
      return null;
    } catch (e) {
      return [];
    }
  }
}