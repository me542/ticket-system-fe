import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:csv/csv.dart';

import 'api_login.dart';

class ApiExport {
  static const String _baseUrl = 'http://localhost:8080/api/user';

  static Future<void> downloadTicketsExcel({
    String? month,
    String? year,
  }) async {
    final token = await ApiLogin.getToken();
    if (token == null) throw Exception('Not authenticated');

    // ── Build URL ─────────────────────────────────────────────
    var url = '$_baseUrl/tickets/export';
    final params = <String>[];

    if (month != null && month.isNotEmpty) params.add('month=$month');
    if (year != null && year.isNotEmpty) params.add('year=$year');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    // ── Fetch CSV ─────────────────────────────────────────────
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch export data: ${res.statusCode}');
    }

    if (res.body.trim().isEmpty) {
      throw Exception('No data to export');
    }

    // ── PROPER CSV PARSING (FIX) ──────────────────────────────
    final converter = CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );

    final rows = converter
        .convert(res.body)
        .map((row) => row.map((e) => e.toString()).toList())
        .toList();

    if (rows.isEmpty) throw Exception('No data to export');

    // ── Create Excel ──────────────────────────────────────────
    final excel = Excel.createExcel();
    final sheet = excel['Tickets Report'];

    excel.delete('Sheet1');

    // ── Styles ────────────────────────────────────────────────
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A3A5C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final rowStyleEven = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F0F4F8'),
    );

    final wrapStyle = CellStyle(
      textWrapping: TextWrapping.WrapText,
    );

    // ── Write Header ──────────────────────────────────────────
    final headers = rows.first;

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // ── Write Data ────────────────────────────────────────────
    for (int rowIdx = 1; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx];
      final isEven = rowIdx % 2 == 0;

      for (int col = 0; col < row.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
        );

        cell.value = TextCellValue(row[col]);

        // alternating row color
        if (isEven) {
          cell.cellStyle = rowStyleEven;
        }

        // wrap long description column (G = index 6)
        if (col == 6) {
          cell.cellStyle = wrapStyle;
        }
      }
    }

    // ── Column widths ─────────────────────────────────────────
    final colWidths = [
      20, 15, 20, 30, 25, 18, 50, 10, 15, 15, 15, 15, 10, 20, 20, 15, 20
    ];

    for (int i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i].toDouble());
    }

    // ── Encode Excel ──────────────────────────────────────────
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final fileName =
        'tickets_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    // ── Download (Web only) ───────────────────────────────────
    if (kIsWeb) {
      _triggerDownload(Uint8List.fromList(bytes), fileName);
    } else {
      throw UnsupportedError('Excel download is only supported on Web');
    }
  }

  // ── Browser download helper ────────────────────────────────
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