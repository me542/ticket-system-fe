import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'api_login.dart';

// ── Custom exceptions ─────────────────────────────────────────────────────────

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

// ── Main class ────────────────────────────────────────────────────────────────

class ApiAttachment {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://idiyanale-be.bakawan-ai.com',
  ) +
      '/api/user';

  // ── Auth header helper ──────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await ApiLogin.getToken();
    if (token == null || token.isEmpty) {
      throw const AttachmentUnauthorizedException();
    }
    return {'Authorization': 'Bearer $token'};
  }

  // ── Fetch raw bytes from any authenticated URL ──────────────────────────────

  /// Fetches the raw bytes at [url].
  ///
  /// Throws:
  /// - [AttachmentUnauthorizedException] on 401
  /// - [AttachmentNotFoundException] on 404
  /// - [AttachmentException] on other non-200 responses
  /// - [AttachmentNetworkException] on network/socket errors
  /// - [ArgumentError] if [url] is empty
  static Future<Uint8List> fetchBytes(String url) async {
    if (url.isEmpty) throw ArgumentError.value(url, 'url', 'URL must not be empty');

    final Map<String, String> headers;
    try {
      headers = await _authHeaders();
    } catch (_) {
      rethrow;
    }

    final http.Response res;
    try {
      res = await http.get(Uri.parse(url), headers: headers);
    } catch (e) {
      throw AttachmentNetworkException(e);
    }

    _assertOk(res, context: url);
    return res.bodyBytes;
  }

  // ── View file in a new browser tab ─────────────────────────────────────────

  /// Opens [url] in a new browser tab.
  ///
  /// Web only — throws [UnsupportedError] on other platforms.
  static Future<void> viewFile(String url, String fileName) async {
    if (url.isEmpty) throw ArgumentError.value(url, 'url', 'URL must not be empty');
    if (fileName.isEmpty) throw ArgumentError.value(fileName, 'fileName', 'File name must not be empty');

    if (!kIsWeb) throw UnsupportedError('viewFile is only supported on Web');

    final bytes = await fetchBytes(url);
    _openBlobInNewTab(bytes, fileName);
  }

  // ── Trigger browser "Save As" dialog ───────────────────────────────────────

  /// Downloads [url] and triggers a browser save-as dialog.
  ///
  /// Web only — throws [UnsupportedError] on other platforms.
  static Future<void> downloadFile(String url, String fileName) async {
    if (url.isEmpty) throw ArgumentError.value(url, 'url', 'URL must not be empty');
    if (fileName.isEmpty) throw ArgumentError.value(fileName, 'fileName', 'File name must not be empty');

    if (!kIsWeb) throw UnsupportedError('downloadFile is only supported on Web');

    final bytes = await fetchBytes(url);
    _triggerDownload(bytes, fileName);
  }

  // ── Fetch attachment by ID ──────────────────────────────────────────────────

  /// Fetches an attachment from `/uploads/attachments/[attachmentId]`.
  ///
  /// Throws:
  /// - [ArgumentError] if [attachmentId] is empty
  /// - [AttachmentUnauthorizedException] on 401
  /// - [AttachmentNotFoundException] on 404
  /// - [AttachmentException] on other non-200 responses
  /// - [AttachmentNetworkException] on network/socket errors
  static Future<Uint8List> fetchAttachmentById(String attachmentId) async {
    if (attachmentId.isEmpty) {
      throw ArgumentError.value(attachmentId, 'attachmentId', 'Attachment ID must not be empty');
    }

    final Map<String, String> headers;
    try {
      headers = await _authHeaders();
    } catch (_) {
      rethrow;
    }

    final http.Response res;
    try {
      res = await http.get(
        Uri.parse('$_baseUrl/uploads/attachments/$attachmentId'),
        headers: headers,
      );
    } catch (e) {
      throw AttachmentNetworkException(e);
    }

    _assertOk(res, context: attachmentId);
    return res.bodyBytes;
  }

  // ── Open blob in new tab (Web only) ────────────────────────────────────────

  static void _openBlobInNewTab(Uint8List bytes, String fileName) {
    final mimeType = _mimeFromName(fileName);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final window = html.window.open(url, '_blank');
    if (window == null) {
      html.Url.revokeObjectUrl(url);
      throw const AttachmentException(
        'Could not open a new tab — the browser may have blocked the pop-up',
      );
    }

    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  // ── Trigger browser download (Web only) ────────────────────────────────────

  static void _triggerDownload(Uint8List bytes, String fileName) {
    final mimeType = _mimeFromName(fileName);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final body = html.document.body;
    if (body == null) {
      html.Url.revokeObjectUrl(url);
      throw const AttachmentException('Cannot trigger download — document body is unavailable');
    }

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    body.append(anchor);
    anchor.click();
    anchor.remove();

    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  // ── Response assertion helper ───────────────────────────────────────────────

  static void _assertOk(http.Response res, {required String context}) {
    if (res.statusCode == 200) return;

    switch (res.statusCode) {
      case 401:
        throw const AttachmentUnauthorizedException();
      case 403:
        throw AttachmentException(
          'Forbidden — insufficient permissions for: $context',
          statusCode: 403,
        );
      case 404:
        throw AttachmentNotFoundException(context);
      case 422:
        throw AttachmentException(
          'Unprocessable request for: $context',
          statusCode: 422,
        );
      case >= 500:
        throw AttachmentException(
          'Server error while fetching: $context',
          statusCode: res.statusCode,
        );
      default:
        throw AttachmentException(
          'Unexpected response for: $context',
          statusCode: res.statusCode,
        );
    }
  }

  // ── MIME type helper ────────────────────────────────────────────────────────

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