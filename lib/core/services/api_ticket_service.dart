import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_login.dart';

class TicketService {
  static const String baseUrl = 'http://localhost:8080/api/user';

  // ─────────────────────────────────────────────
  // CREATE TICKET
  // ─────────────────────────────────────────────
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
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachments',
            attachment.bytes!,
            filename: attachment.name,
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      print('CREATE STATUS: ${response.statusCode}');
      print('CREATE BODY: $body');

      return response.statusCode == 201;
    } catch (e) {
      print('CREATE ERROR: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // GET ALL TICKETS (FIXED)
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) {
        print("NO TOKEN FOUND");
        return [];
      }

      final uri = Uri.parse('$baseUrl/list/all/tickets');

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);

      List<dynamic> list = [];

      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          list = decoded['data'];
        } else if (decoded['data'] is Map &&
            decoded['data']['tickets'] is List) {
          list = decoded['data']['tickets'];
        } else if (decoded['tickets'] is List) {
          list = decoded['tickets'];
        }
      }

      print("PARSED TICKETS COUNT: ${list.length}");

      return list.map<Map<String, dynamic>>((e) {
        // FIX: API wraps all ticket fields inside e['ticket']
        // Previous code read from e directly — so all fields were empty
        final Map<String, dynamic> t =
        (e['ticket'] is Map)
            ? Map<String, dynamic>.from(e['ticket'] as Map)
            : Map<String, dynamic>.from(e as Map);

        return {
          'ticket_id':          t['ticket_id']    ?? '',
          'subject':            t['subject']      ?? '',
          'priority':           t['priority']     ?? 0,
          'status':             t['status']       ?? '',
          'description':        t['description']  ?? '',
          'username':           t['username']     ?? 'Unknown',
          'category':           t['category']     ?? '',
          'created_at':         t['created_at']   ?? '',
          'resolved_at':        t['resolved_at']  ?? '',
          // FIX: cast directly to double — no string conversion
          'resolution_time': (t['resolution_time'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // GET BY ID
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getById(String ticketId) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/ticket/$ticketId');

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      print("GET BY ID: ${res.body}");

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body)['data'];

      if (decoded == null) return null;

      if (decoded['ticket'] != null) return decoded['ticket'];

      return decoded;
    } catch (e) {
      print('GET BY ID ERROR: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GET USER TICKETS
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getUserTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/ticket/user');

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      print("USER TICKETS: ${res.body}");

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);

      List<dynamic> list = decoded['data'] ?? [];

      return list.map<Map<String, dynamic>>((e) {
        return {
          'ticket_id':  e['ticket_id']  ?? '',
          'subject':    e['subject']    ?? '',
          'priority':   e['priority']   ?? 0,
          'status':     e['status']     ?? '',
          'description':e['description']?? '',
          'created_at': e['created_at'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('USER TICKETS ERROR: $e');
      return [];
    }
  }
}