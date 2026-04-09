import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_login.dart';

class TicketService {
  static const String baseUrl = 'http://localhost:8080/api/user';

  /// CREATE NEW TICKET
  static Future<bool> create({
    required String subject,
    required String ticketType,
    required String category,
    required String organization,
    required int priority,
    required String description,
    required String endorser,
    PlatformFile? attachment,
  }) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return false;

      final uri = Uri.parse('$baseUrl/ticket/create');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['subject'] = subject;
      request.fields['tickettype'] = ticketType;
      request.fields['category'] = category;
      request.fields['institution'] = organization;
      request.fields['priority'] = priority.toString();
      request.fields['description'] = description;
      request.fields['endorser'] = endorser;

      if (attachment != null && attachment.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'attachments',
          attachment.bytes!,
          filename: attachment.name,
        ));
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      print('Create Ticket Status: ${response.statusCode}');
      print('Create Ticket Response: $body');

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating ticket: $e');
      return false;
    }
  }

  /// GET ALL TICKETS
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/list/all/tickets');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data is List) {
          return data.map<Map<String, dynamic>>((e) {
            return {
              'ticket_id': e['ticket_id'] ?? e['ticket']?['ticket_id'] ?? '',
              'subject': e['subject'] ?? e['ticket']?['subject'] ?? '',
              'priority': e['priority'] ?? e['ticket']?['priority'] ?? 0,
              'status': e['status'] ?? e['ticket']?['status'] ?? '',
              'description': e['description'] ?? e['ticket']?['description'] ?? '',
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
      }

      print('Failed to fetch tickets: ${res.body}');
      return [];
    } catch (e) {
      print('Error fetching tickets: $e');
      return [];
    }
  }

  /// GET SINGLE TICKET BY ID
  static Future<Map<String, dynamic>?> getById(String ticketId) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/ticket/$ticketId');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      print('getById Response: ${res.body}'); // 🔹 Debug

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        // Handle nested ticket or flat
        if (data == null) return null;
        if (data['ticket'] != null) return data['ticket'];
        return data;
      }

      print('Failed to fetch ticket by ID: ${res.body}');
      return null;
    } catch (e) {
      print('Error fetching ticket by ID: $e');
      return null;
    }
  }

  /// GET TICKETS FOR LOGGED-IN USER
  static Future<List<Map<String, dynamic>>> getUserTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/ticket/user');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data is List) {
          return data.map<Map<String, dynamic>>((e) {
            return {
              'ticket_id': e['ticket_id'] ?? '',
              'subject': e['subject'] ?? '',
              'priority': e['priority'] ?? 0,
              'status': e['status'] ?? '',
              'description': e['description'] ?? '',
              'created_at': e['created_at'] ?? '',
            };
          }).toList();
        }
      }

      print('Failed to fetch user tickets: ${res.body}');
      return [];
    } catch (e) {
      print('Error fetching user tickets: $e');
      return [];
    }
  }
}
