import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = "http://localhost:8080/admin/list/all/tickets";


  /// ✅ Create Ticket API
  static Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String category,
    required String institution,
    required String tickettype,
    required String description,
    required String purpose,
    required String assignee,
    required String priority,
    required String endorser,
    required String approver,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/create-ticket");

      var request = http.MultipartRequest("POST", url);


      request.fields['subject'] = subject;
      request.fields['category'] = category;
      request.fields['institution'] = institution;
      request.fields['tikcettype'] = tickettype;
      request.fields['description'] = description;
      request.fields['purpose'] = purpose;
      request.fields['assignee'] = assignee;
      request.fields['priority'] = priority;
      request.fields['endorser'] = endorser;
      request.fields['approver'] = approver;

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "data": jsonDecode(responseBody),
        };
      } else {
        return {
          "success": false,
          "message": responseBody,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}
