import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'api_login.dart';

class AttachmentException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;
  const AttachmentException(this.message, {this.statusCode, this.cause});

  @override
  String toString() {
    final parts = ['AttachmentException: $message'];
    if (statusCode != null) parts.add('(HTTP $statusCode)');
    if (cause != null) parts.add('— caused by: $cause');
    return parts.join(' ');
  }
}

class AttachmentNotFoundException extends AttachmentException {
  const AttachmentNotFoundException(String id)
      : super('Attachment not found: $id', statusCode: 404);
}

class AttachmentUnauthorizedException extends AttachmentException {
  const AttachmentUnauthorizedException()
      : super('Unauthorized — token may be missing or expired', statusCode: 401);
}

class AttachmentNetworkException extends AttachmentException {
  const AttachmentNetworkException(Object cause)
      : super('Network error while fetching attachment', cause: cause);
}

class ApiAttachment {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://idiyanale-be.bakawan-ai.com',
  ) + '/api/user';

  // ── Auth headers ────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await ApiLogin.getToken();
    if (token == null || token.isEmpty) {
      throw const AttachmentUnauthorizedException();
    }
    return {'Authorization': 'Bearer $token'};
  }

  // ── Get presigned URL from backend ──────────────────────────────────────────
  //
  // Calls GET /api/user/attachments/:id/presigned
  // Backend looks up FileKey, calls GeneratePresignedGetURL, returns the URL.
  // We use this URL directly — no CORS issue because presigned S3 URLs are public.

  static Future<String> _getPresignedUrl(String attachmentId) async {
    final headers = await _authHeaders();

    final http.Response res;
    try {
      res = await http.get(
        Uri.parse('$_baseUrl/attachments/$attachmentId/presigned'),
        headers: headers,
      );
    } catch (e) {
      throw AttachmentNetworkException(e);
    }

    _assertOk(res, context: attachmentId);

    // Backend returns: { "data": { "url": "https://s3.amazonaws.com/..." } }
    // Adjust the key path to match your actual response shape
    final decoded = jsonDecode(res.body);
    final url = decoded['data']?['url'] as String?
        ?? decoded['url']  as String?;

    if (url == null || url.isEmpty) {
      throw AttachmentException('Presigned URL missing in response');
    }

    debugPrint('🔗 Presigned URL: $url');
    return url;
  }

  // ── View file in new tab ─────────────────────────────────────────────────────
  //
  // Strategy:
  //   1. Ask backend for a presigned S3 URL (authenticated, no CORS issue)
  //   2. Open that URL directly in a new tab — browser fetches from S3 natively

  static Future<void> viewFile(String url, String fileName) async {
    if (!kIsWeb) throw UnsupportedError('viewFile is only supported on Web');

    final attachmentId = _extractAttachmentId(url);

    if (attachmentId != null) {
      // ✅ Use presigned URL via backend — avoids CORS entirely
      final presigned = await _getPresignedUrl(attachmentId);
      html.window.open(presigned, '_blank');
    } else {
      // Fallback: url is already a presigned S3 URL — open directly
      debugPrint('⚠️ No attachment ID found, opening URL directly: $url');
      html.window.open(url, '_blank');
    }
  }

  // ── Download file ────────────────────────────────────────────────────────────

  static Future<void> downloadFile(String url, String fileName) async {
    if (!kIsWeb) throw UnsupportedError('downloadFile is only supported on Web');

    final attachmentId = _extractAttachmentId(url);
    final String fetchUrl;

    if (attachmentId != null) {
      fetchUrl = await _getPresignedUrl(attachmentId);
    } else {
      fetchUrl = url;
    }

    // Fetch bytes from presigned URL — no auth header needed for presigned S3
    final http.Response res;
    try {
      res = await http.get(Uri.parse(fetchUrl));
    } catch (e) {
      throw AttachmentNetworkException(e);
    }

    _assertOk(res, context: fetchUrl);
    _triggerDownload(res.bodyBytes, fileName);
  }

  // ── Legacy: fetch by attachment ID directly ──────────────────────────────────

  static Future<Uint8List> fetchAttachmentById(String attachmentId) async {
    final presigned = await _getPresignedUrl(attachmentId);
    final res = await http.get(Uri.parse(presigned));
    _assertOk(res, context: attachmentId);
    return res.bodyBytes;
  }

  // ── Extract attachment ID from a stored URL or ID string ─────────────────────
  //
  // Handles cases where `url` might be:
  //   - A numeric/uuid ID:        "42"  or  "abc-123"
  //   - A backend URL:            "/api/user/attachments/42"
  //   - A raw S3 URL:             "https://bucket.s3.amazonaws.com/..."
  //
  // Returns null if it looks like a direct S3 URL (no backend ID to extract).

  static String? _extractAttachmentId(String url) {
    // Already a plain ID (no slashes, no http)
    if (!url.contains('/') && !url.startsWith('http')) return url;

    // Backend URL pattern: /attachments/123
    final match = RegExp(r'/attachments/([^/?#]+)').firstMatch(url);
    if (match != null) return match.group(1);

    // Looks like a raw S3 URL — no ID to extract
    return null;
  }

  // ── Trigger browser download ──────────────────────────────────────────────────

  static void _triggerDownload(Uint8List bytes, String fileName) {
    final mimeType = _mimeFromName(fileName);
    final blob = html.Blob([bytes], mimeType);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();

    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(blobUrl);
    });
  }

  // ── Response assertion ────────────────────────────────────────────────────────

  static void _assertOk(http.Response res, {required String context}) {
    if (res.statusCode == 200) return;
    switch (res.statusCode) {
      case 401:
        throw const AttachmentUnauthorizedException();
      case 403:
        throw AttachmentException('Forbidden: $context', statusCode: 403);
      case 404:
        throw AttachmentNotFoundException(context);
      case >= 500:
        throw AttachmentException('Server error: $context',
            statusCode: res.statusCode);
      default:
        throw AttachmentException('Unexpected response: $context',
            statusCode: res.statusCode);
    }
  }

  // ── MIME helper ───────────────────────────────────────────────────────────────

  static String _mimeFromName(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      case 'pdf':  return 'application/pdf';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':  return 'text/plain';
      default:     return 'application/octet-stream';
    }
  }

  static Future<Uint8List?> fetchBytes(String url) async {}
}