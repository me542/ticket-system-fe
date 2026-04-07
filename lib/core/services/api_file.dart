import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_login.dart'; // your login API

class ApiTicket {
  static const String baseUrl = 'http://localhost:8080/api/user';

  /// CREATE TICKET
  static Future<bool> createTicket({
    required String subject,
    required String tickettype,
    required String category,
    required String organization,
    required int priority,
    required String description,
    required String endorser, // ✅ added
    PlatformFile? file,
  }) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return false;

      final uri = Uri.parse('$baseUrl/ticket/create');
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Fields
      request.fields['subject'] = subject;
      request.fields['tickettype'] = tickettype; // backend typo
      request.fields['category'] = category;
      request.fields['institution'] = organization;
      request.fields['priority'] = priority.toString();
      request.fields['description'] = description;
      request.fields['endorser'] = endorser; // ✅ send endorser

      // Add attachment if present
      if (file != null && file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachments',
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      print('STATUS: ${response.statusCode}');
      print('BODY: $resBody');

      return response.statusCode == 201;
    } catch (e) {
      print('ERROR: $e');
      return false;
    }
  }

  /// GET ALL TICKETS
  static Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/list/all/tickets');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token'
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['data'];

        if (raw is List) {
          return raw.map<Map<String, dynamic>>((e) {
            return {
              'ticket_id': e['ticket_id'] ?? e['ticket']?['ticket_id'] ?? '',
              'subject': e['subject'] ?? e['ticket']?['subject'] ?? '',
              'priority': e['priority'] ?? e['ticket']?['priority'] ?? 0,
              'status': e['status'] ?? e['ticket']?['status'] ?? '',
              'username': e['username'] ??
                  e['user']?['username'] ??
                  e['ticket']?['username'] ??
                  'Unknown',
              'category': e['category'] ??
                  e['ticket']?['category'] ??
                  e['user']?['category'] ??
                  '',
              'created_at': e['created_at'] ?? '',
            };
          }).toList();
        }

        return [];
      }

      return [];
    } catch (e) {
      print('ERROR: $e');
      return [];
    }
  }

  /// GET TICKETS FOR LOGGED-IN USER
  static Future<List<dynamic>> getUserTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/ticket/user');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? [];
      }

      print('Failed to fetch user tickets: ${res.body}');
      return [];
    } catch (e) {
      print('ERROR: $e');
      return [];
    }
  }

  /// GET SINGLE TICKET BY ID
  static Future<Map<String, dynamic>?> getTicketByID(String ticketID) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/ticket/$ticketID');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'];
      }

      print('Failed to fetch ticket: ${res.body}');
      return null;
    } catch (e) {
      print('ERROR: $e');
      return null;
    }
  }
}
