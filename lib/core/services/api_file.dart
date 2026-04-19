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
    PlatformFile? file, required String subcategory,
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
  /// Handles both flat and nested { "ticket": {...} } shapes.
  /// Also handles GORM's CamelCase JSON keys (CreatedAt, UpdatedAt, etc.)
  static Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('$baseUrl/list/all/tickets');
      final res = await http.get(
          uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['data'];

        if (raw is List) {
          return raw.map<Map<String, dynamic>>((e) {
            // Backend wraps as { "ticket": {...}, "attachments": [...] }
            // Fall back to flat if no nested ticket key
            final Map t =
            (e['ticket'] is Map) ? e['ticket'] as Map : e as Map;

            // Pick the first non-empty value from a list of key candidates.
            // This handles both snake_case (json tags) and CamelCase (GORM default).
            String pick(List<String> keys) {
              for (final k in keys) {
                final v = t[k] ?? e[k];
                if (v != null && v.toString().trim().isNotEmpty) {
                  return v.toString().trim();
                }
              }
              return '';
            }

            dynamic pickNum(List<String> keys) {
              for (final k in keys) {
                final v = t[k] ?? e[k];
                if (v != null) return v;
              }
              return 0;
            }

            return {
              'ticket_id':    pick(['ticket_id', 'TicketID',    'ticketId']),
              'subject':      pick(['subject',    'Subject']),
              'category':     pick(['category',   'Category']),
              'description':  pick(['description','Description']),
              'institution':  pick(['institution','Institution']),
              'tickettype':   pick(['tickettype', 'Tickettype', 'ticket_type', 'TicketType']),
              'priority':     pickNum(['priority','Priority']),
              'status':       pick(['status',     'Status']),
              'username':     pick(['username',   'Username']),
              'assignee':     pick(['assignee',   'Assignee']),
              'endorser':     pick(['endorser',   'Endorser']),
              'approver':     pick(['approver',   'Approver']),
              'created_at':   pick(['created_at', 'CreatedAt', 'createdAt']),
              'updated_at':   pick(['updated_at', 'UpdatedAt', 'updatedAt']),
              'cancelled_by': pick(['cancelled_by','CancelledBy','cancelledBy']),
              'cancelled_at': pick(['cancelled_at','CancelledAt','cancelledAt']),
              'started_at':   pick(['started_at', 'StartedAt', 'startedAt']),
              'resolved_at':  pick(['resolved_at', 'ResolvedAt', 'resolvedAt']),
              'resolution_minutes': pick(['resolution_minutes', 'ResolutionMinutes', 'resolutionMinutes']),
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
      final res = await http.get(
          uri, headers: {'Authorization': 'Bearer $token'});

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
      final res = await http.get(
          uri, headers: {'Authorization': 'Bearer $token'});

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('getTicketByID  SR: $ticketID');
      print('STATUS: ${res.statusCode}');
      print('RAW BODY: ${res.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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