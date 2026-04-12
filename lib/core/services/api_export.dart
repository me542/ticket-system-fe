import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'api_login.dart';

class ApiExport {
  static const String _baseUrl = 'http://localhost:8080/api/user';

  // ── Download all tickets as Excel ─────────────────────────────────────────
  // 1. Fetches CSV from GET /api/user/tickets/export
  // 2. Parses the CSV rows
  // 3. Builds an Excel workbook with styled headers
  // 4. Triggers browser download as tickets_report.xlsx
  static Future<void> downloadTicketsExcel({
    String? month,
    String? year,
  }) async {
    final token = await ApiLogin.getToken();
    if (token == null) throw Exception('Not authenticated');

    // ── Build URL with optional month/year filter ─────────────────────────
    var url = '$_baseUrl/tickets/export'; // matches GET /api/user/tickets/export
    final params = <String>[];
    if (month != null && month.isNotEmpty) params.add('month=$month');
    if (year != null && year.isNotEmpty) params.add('year=$year');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    // ── Fetch CSV from backend ────────────────────────────────────────────
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch export data: ${res.statusCode}');
    }

    // ── Parse CSV ─────────────────────────────────────────────────────────
    final csvLines = res.body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (csvLines.isEmpty) throw Exception('No data to export');

    final rows = csvLines.map((line) => _parseCsvLine(line)).toList();

    // ── Build Excel workbook ──────────────────────────────────────────────
    final excel = Excel.createExcel();
    final sheet = excel['Tickets Report'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A3A5C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Row style (alternating)
    final rowStyleEven = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F0F4F8'),
    );

    // ── Write header row ──────────────────────────────────────────────────
    if (rows.isNotEmpty) {
      final headers = rows.first;
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }
    }

    // ── Write data rows ───────────────────────────────────────────────────
    for (var rowIdx = 1; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx];
      final isEven = rowIdx % 2 == 0;

      for (var col = 0; col < row.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
        );
        cell.value = TextCellValue(row[col]);
        if (isEven) cell.cellStyle = rowStyleEven;
      }
    }

    // ── Auto-size columns (set reasonable widths) ─────────────────────────
    final colWidths = [20, 15, 20, 30, 20, 15, 40, 10, 15, 15, 15, 15, 10, 20, 20, 15, 20];
    for (var i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i].toDouble());
    }

    // ── Encode and download ───────────────────────────────────────────────
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file');

    final fileName =
        'tickets_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (kIsWeb) {
      _triggerDownload(Uint8List.fromList(bytes), fileName);
    } else {
      throw UnsupportedError('Excel download is only supported on Web');
    }
  }

  // ── CSV line parser (handles quoted fields with commas) ───────────────────
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  // ── Trigger browser download ──────────────────────────────────────────────
  static void _triggerDownload(Uint8List bytes, String fileName) {
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
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
}