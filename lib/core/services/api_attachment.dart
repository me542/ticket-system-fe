// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_login.dart';

class ApiAttachment {
  /// Fetches attachment bytes using Bearer token then opens in a new browser tab.
  static Future<void> viewFile(String fileUrl, String fileName) async {
    final bytes = await _fetchBytes(_toFullUrl(fileUrl));
    if (bytes == null) throw Exception('Could not fetch file');
    _openBlob(bytes, fileName, download: false);
  }

  /// Fetches attachment bytes using Bearer token then triggers browser download.
  static Future<void> downloadFile(String fileUrl, String fileName) async {
    final bytes = await _fetchBytes(_toFullUrl(fileUrl));
    if (bytes == null) throw Exception('Could not fetch file');
    _openBlob(bytes, fileName, download: true);
  }

  /// Fetches raw bytes for an attachment URL with auth token.
  /// Used by the image preview widget to render images that require auth.
  static Future<Uint8List?> fetchBytes(String fileUrl) async {
    return _fetchBytes(_toFullUrl(fileUrl));
  }

  /// Fetches all attachments for a given ticket SR number.
  /// Returns a list of maps with 'file_name' and 'file_path' keys.
  static Future<List<Map<String, dynamic>>> getAttachments(String ticketId) async {
    try {
      final token = await ApiLogin.getToken();
      if (token == null) return [];

      final uri = Uri.parse('http://localhost:8080/api/user/ticket/$ticketId/attachments');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      print('ATTACHMENTS STATUS: ${res.statusCode}');
      print('ATTACHMENTS BODY: ${res.body}');

      if (res.statusCode == 200) {
        // handled via getTicketByID — attachments are nested in the ticket response
      }
      return [];
    } catch (e) {
      print('ATTACHMENTS ERROR: $e');
      return [];
    }
  }

  // ─── private helpers ────────────────────────────────────────────────────────

  static const String _baseUrl = 'http://localhost:8080';

  /// Normalizes any file_path value from the DB into a valid full URL.
  /// Handles all three shapes:
  ///   "http://localhost:8080/uploads/file.png"  → used as-is
  ///   "uploads/attachments/file.png"            → baseUrl + /path
  ///   "/uploads/attachments/file.png"           → baseUrl + path
  static String _toFullUrl(String filePath) {
    final t = filePath.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t.replaceAll(' ', '%20');
    }
    final path = t.startsWith('/') ? t : '/$t';
    return '$_baseUrl$path'.replaceAll(' ', '%20');
  }

  static Future<Uint8List?> _fetchBytes(String fileUrl) async {
    try {
      final token = await ApiLogin.getToken();
      final uri   = Uri.parse(_toFullUrl(fileUrl));
      final res = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      if (res.statusCode == 200) return res.bodyBytes;
      print('FETCH FILE ERROR: ${res.statusCode} — $fileUrl');
      return null;
    } catch (e) {
      print('FETCH FILE EXCEPTION: $e');
      return null;
    }
  }

  static void _openBlob(Uint8List bytes, String fileName, {required bool download}) {
    final ext  = fileName.split('.').last.toLowerCase();
    final mime = _mimeType(ext);

    final blob    = html.Blob([bytes], mime);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: blobUrl)
      ..target = download ? '_self' : '_blank';

    if (download) anchor.download = fileName;

    anchor.click();

    // Free memory after the browser has started loading
    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(blobUrl);
    });
  }

  static String _mimeType(String ext) {
    const map = {
      'pdf'  : 'application/pdf',
      'png'  : 'image/png',
      'jpg'  : 'image/jpeg',
      'jpeg' : 'image/jpeg',
      'gif'  : 'image/gif',
      'webp' : 'image/webp',
      'bmp'  : 'image/bmp',
      'docx' : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'doc'  : 'application/msword',
      'xlsx' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'xls'  : 'application/vnd.ms-excel',
      'pptx' : 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt'  : 'text/plain',
      'zip'  : 'application/zip',
      'mp4'  : 'video/mp4',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}