import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ApiFileTicket {
  static Future<bool> createTicket({
    required String subject,
    required String ticketType,
    required String category,
    required String organization,
    required int priority,
    required String description,
    PlatformFile? file,
  }) async {
    try {
      var uri = Uri.parse("http://localhost:8080/api/admin/list/all/tickets");

      var request = http.MultipartRequest("POST", uri);

      // ✅ MATCH BACKEND EXACTLY
      request.fields['subject'] = subject;
      request.fields['tickettype'] = ticketType;     // ✅ FIX
      request.fields['category'] = category;
      request.fields['institution'] = organization;  // ✅ FIX
      request.fields['priority'] = priority.toString(); // ✅ FIX
      request.fields['description'] = description;

      // FILE
      if (file != null && file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // make sure backend uses this
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      var response = await request.send();
      var resBody = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $resBody");

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }
}
