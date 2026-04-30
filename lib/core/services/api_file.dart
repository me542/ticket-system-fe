import 'dart:convert';
import 'package:flutter/cupertino.dart';
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
    required String subcategory,
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

      // ── REQUIRED FIELDS (MATCH BACKEND EXACTLY)
      request.fields['subject'] = subject;
      request.fields['tickettype'] = tickettype;
      request.fields['category'] = category;
      request.fields['subcategory'] = subcategory;
      request.fields['organization'] = organization; // ✅ FIXED
      request.fields['priority'] = priority.toString();
      request.fields['description'] = description;
      request.fields['endorser'] = endorser;

      // ── FILE UPLOAD (safe check)
      if (file != null && file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachment', // ⚠️ confirm backend expects this
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      debugPrint('>>> CREATE TICKET STATUS: ${response.statusCode}');
      debugPrint('>>> CREATE TICKET BODY: $resBody');

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('CREATE TICKET ERROR: $e');
      return false;
    }
  }


  /// GET ALL TICKETS
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
            // API always wraps ticket data inside "ticket" key
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
              'resolution_time':    t['resolution_time']     ?? '', // ← fixed key + string
            };
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      //
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
      return [];
    } catch (e) {
      //
      return [];
    }
  }

  /// GET SINGLE TICKET BY SR NUMBER
  static Future<Map<String, dynamic>?> getTicketByID(String ticketID) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/tickets/$ticketID');
      final res = await http.get(
          uri, headers: {'Authorization': 'Bearer $token'});

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
      //
      return null;
    }
  }
}