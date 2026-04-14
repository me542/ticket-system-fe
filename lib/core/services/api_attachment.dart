import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'api_login.dart';

class ApiAttachment {
  static const String _baseUrl = 'http://localhost:8080/api/user';

  // ── Auth header helper ────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await ApiLogin.getToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // ── Fetch raw bytes (used by _AuthImage widget in the sidebar) ────────────
  // The URL coming from the backend is already a full URL like:
  // http://localhost:8080/uploads/attachments/SR000001_xxx_file.png
  // We fetch it with the auth token so protected files work too.
  static Future<Uint8List?> fetchBytes(String url) async {
    if (url.isEmpty) return null;
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── View file — opens in a new browser tab ────────────────────────────────
  // On Flutter Web we use universal_html to open a blob URL.
  // The route is: GET /api/user/attachments/:id
  // But the sidebar passes the full file URL directly, so we support both.
  static Future<void> viewFile(String url, String fileName) async {
    if (url.isEmpty) return;

    final bytes = await fetchBytes(url);
    if (bytes == null) throw Exception('Could not load file');

    if (kIsWeb) {
      _openBlobInNewTab(bytes, fileName);
    } else {
      // On mobile/desktop you could use open_file or path_provider.
      // For now throw so the caller can handle it.
      throw UnsupportedError('viewFile is only supported on Web');
    }
  }

  // ── Download file — triggers browser "Save As" dialog ────────────────────
  static Future<void> downloadFile(String url, String fileName) async {
    if (url.isEmpty) return;

    final bytes = await fetchBytes(url);
    if (bytes == null) throw Exception('Could not load file');

    if (kIsWeb) {
      _triggerDownload(bytes, fileName);
    } else {
      throw UnsupportedError('downloadFile is only supported on Web');
    }
  }

  // ── View attachment by numeric DB id ─────────────────────────────────────
  // Calls GET /api/user/attachments/:id with auth token.
  // Returns bytes so the caller can display or save.
  static Future<Uint8List?> fetchAttachmentById(String attachmentId) async {
    if (attachmentId.isEmpty) return null;
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/uploads/attachments/$attachmentId'),
        headers: headers,
      );
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Open blob in new tab (Web only) ──────────────────────────────────────
  static void _openBlobInNewTab(Uint8List bytes, String fileName) {
    final mimeType = _mimeFromName(fileName);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Open in new tab
    html.window.open(url, '_blank');

    // Revoke after a short delay so the tab has time to load
    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  // ── Trigger browser download (Web only) ──────────────────────────────────
  static void _triggerDownload(Uint8List bytes, String fileName) {
    final mimeType = _mimeFromName(fileName);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();

    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  // ── MIME type helper ──────────────────────────────────────────────────────
  static String _mimeFromName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}