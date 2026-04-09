import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_login.dart';

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
    required String endorser,
    PlatformFile? file,
  }) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return false;

      final uri = Uri.parse('$baseUrl/ticket/create');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['subject'] = subject;
      request.fields['tickettype'] = tickettype;
      request.fields['category'] = category;
      request.fields['institution'] = organization;
      request.fields['priority'] = priority.toString();
      request.fields['description'] = description;
      request.fields['endorser'] = endorser;

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
      print('CREATE STATUS: ${response.statusCode}');
      print('CREATE BODY: $resBody');
      return response.statusCode == 201;
    } catch (e) {
      print('CREATE ERROR: $e');
      return false;
    }
  }

  /// GET ALL TICKETS
  static Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/list/all/tickets');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['data'];

        if (raw is List) {
          return raw.map<Map<String, dynamic>>((e) {
            return {
              'ticket_id': e['ticket_id'] ?? e['ticket']?['ticket_id'] ?? '',
              'subject':   e['subject']   ?? e['ticket']?['subject']   ?? '',
              'priority':  e['priority']  ?? e['ticket']?['priority']  ?? 0,
              'status':    e['status']    ?? e['ticket']?['status']    ?? '',
              'username':  e['username']  ?? e['user']?['username']    ?? e['ticket']?['username'] ?? 'Unknown',
              'category':  e['category']  ?? e['ticket']?['category']  ?? e['user']?['category']  ?? '',
              'created_at': e['created_at'] ?? '',
            };
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('GET ALL ERROR: $e');
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

      print('USER TICKETS FAILED: ${res.body}');
      return [];
    } catch (e) {
      print('USER TICKETS ERROR: $e');
      return [];
    }
  }

  /// GET SINGLE TICKET BY SR NUMBER
  /// Returns a flat map with all available fields regardless of nesting.
  static Future<Map<String, dynamic>?> getTicketByID(String ticketID) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/tickets/$ticketID');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      // ── DEBUG: print raw so you can see the exact shape ──────────────────
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('getTicketByID  SR: $ticketID');
      print('STATUS: ${res.statusCode}');
      print('RAW BODY: ${res.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        // The API might wrap the ticket in different ways.
        // We try each common shape and flatten into one map.
        final Map<String, dynamic> flat = {};

        // Shape A: { "data": { ...ticket fields... } }
        // Shape B: { "data": { "ticket": {...}, "user": {...}, ... } }
        // Shape C: { "data": [ { ...ticket... } ] }  (rare but guard it)

        dynamic raw = decoded['data'];

        if (raw is List && raw.isNotEmpty) raw = raw.first;

        if (raw is Map<String, dynamic>) {
          // Merge top-level fields first
          flat.addAll(raw);

          // If there are sub-objects, hoist their fields too (without overwriting)
          for (final key in ['ticket', 'user', 'endorser_info', 'approver_info', 'resolver_info']) {
            final sub = raw[key];
            if (sub is Map<String, dynamic>) {
              sub.forEach((k, v) {
                flat.putIfAbsent(k, () => v);
              });
            }
          }
        }

        print('FLATTENED: $flat');
        return flat.isEmpty ? null : flat;
      }

      print('getTicketByID FAILED: ${res.body}');
      return null;
    } catch (e) {
      print('getTicketByID ERROR: $e');
      return null;
    }
  }
}