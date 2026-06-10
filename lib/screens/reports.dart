import 'package:flutter/material.dart';
import '../core/services/api_ticket_service.dart';
import '../data/light_theme.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:universal_html/html.dart' as html;

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  bool _loading = true;
  Map<String, Map<String, dynamic>> _monthly = {};

  // Category → { count, totalMinutes, resolvedCount }
  Map<String, Map<String, dynamic>> _byCategory = {};

  // Daily ticket counts: "YYYY-MM-DD" → count
  Map<String, int> _daily = {};

  // Selected month filter for the bar chart (null = current month)
  String? _selectedChartMonth;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    String s = raw.toString().trim();
    if (s.isEmpty) return null;
    try {
      s = s.replaceFirst(' ', 'T');
      final regex = RegExp(r'(\+\d{2})$');
      s = s.replaceAllMapped(regex, (m) => '${m[1]}:00');
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Converts a raw resolution value from the API into MINUTES.
  //
  // The API field `resolution_minutes` stores a string like "03m 25s".
  // We parse minutes + seconds and return the total as a decimal minute value.
  //
  // Fallback: if the value is null/unparseable we diff created_at ↔ resolved_at.
  // ─────────────────────────────────────────────────────────────────────────
  double _resolveMinutes(Map<String, dynamic> t, DateTime? created) {
    final raw = t['resolution_minutes'];
    if (raw != null) {
      final s = raw.toString().trim();

      // Format: "03m 25s" or "3m25s" etc.
      final mMatch = RegExp(r'(\d+)\s*m').firstMatch(s);
      final sMatch = RegExp(r'(\d+)\s*s').firstMatch(s);
      if (mMatch != null || sMatch != null) {
        final mins = mMatch != null ? double.parse(mMatch.group(1)!) : 0.0;
        final secs = sMatch != null ? double.parse(sMatch.group(1)!) : 0.0;
        final total = mins + secs / 60.0;
        if (total > 0) return total;
      }

      // Numeric fallback: if the API ever returns a plain number, treat as seconds
      final numeric = double.tryParse(s);
      if (numeric != null && numeric > 0) return numeric / 60.0;
    }

    // Fallback: compute from timestamps
    final resolved = _parseDate(t['resolved_at'] ?? t['resolvedAt']);
    if (created != null && resolved != null) {
      final diff = resolved.difference(created).inSeconds / 60.0;
      if (diff > 0) return diff;
    }

    return 0.0;
  }

  Future<void> _exportExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Report'];
      excel.delete('Sheet1');
      final catSheet = excel['Category Report'];

      final titleStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A7A1A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A7A1A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final totalStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
      );
      final varianceStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#CC0000'),
      );
      final dashStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
      );

      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];

      const durationBuckets = [
        '1 hour', '3 hours', '8 hours', '1 day',
        '2 days', '5 days', '2 weeks', '1 month',
        '2 months', '3 months',
      ];

      const bucketThresholds = [
        60, 180, 480, 1440, 2880, 7200, 20160, 43200, 86400, 129600
      ];

      final bucketData = List.generate(
        durationBuckets.length, (_) => List.filled(12, 0),
      );
      final bucketTotals = List.filled(durationBuckets.length, 0);

      final monthRequests      = List.filled(12, 0);
      final monthCancelled     = List.filled(12, 0);
      final monthInProgress    = List.filled(12, 0);
      final monthClosed        = List.filled(12, 0);
      final monthTotalMins     = List.filled(12, 0.0);
      final monthResolvedCount = List.filled(12, 0);

      _monthly.forEach((key, m) {
        final parts = key.split('-');
        if (parts.length != 2) return;
        final monthIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        if (monthIdx < 0 || monthIdx > 11) return;

        monthRequests[monthIdx]      += (m['total']         as int?    ?? 0);
        monthCancelled[monthIdx]     += (m['cancelled']     as int?    ?? 0);
        monthInProgress[monthIdx]    += (m['inprogress']    as int?    ?? 0);
        monthClosed[monthIdx]        += (m['closed']        as int?    ?? 0);
        monthTotalMins[monthIdx]     += (m['totalMinutes']  as double? ?? 0.0);
        monthResolvedCount[monthIdx] += (m['resolvedCount'] as int?    ?? 0);
      });

      for (var mi = 0; mi < 12; mi++) {
        if (monthResolvedCount[mi] == 0) continue;
        final avg = monthTotalMins[mi] / monthResolvedCount[mi];
        for (var bi = 0; bi < bucketThresholds.length; bi++) {
          if (avg <= bucketThresholds[bi]) {
            bucketData[bi][mi]++;
            bucketTotals[bi]++;
            break;
          }
        }
      }

      List<int> bucketVariance(List<int> row) {
        final v = List.filled(12, 0);
        for (var i = 1; i < 12; i++) {
          if (row[i] != 0 || row[i - 1] != 0) {
            v[i] = row[i] - row[i - 1];
          }
        }
        return v;
      }

      const int rStart = 15;

      // ── LEFT TABLE ──────────────────────────────────────────────────────
      final titleCellL = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      );
      titleCellL.value     = TextCellValue('Monthly Ticket Duration Summary');
      titleCellL.cellStyle = titleStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0,  rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: 0),
      );

      final leftHeaders = ['Duration', ...months, 'Total'];
      for (var c = 0; c < leftHeaders.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1),
        );
        cell.value     = TextCellValue(leftHeaders[c]);
        cell.cellStyle = headerStyle;
      }

      for (var bi = 0; bi < durationBuckets.length; bi++) {
        final row = bi + 2;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        ).value = TextCellValue(durationBuckets[bi]);

        for (var mi = 0; mi < 12; mi++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: mi + 1, rowIndex: row),
          );
          final val = bucketData[bi][mi];
          cell.value     = TextCellValue(val == 0 ? '-' : val.toString());
          cell.cellStyle = val == 0 ? dashStyle : null;
        }

        final totalCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row),
        );
        totalCell.value = TextCellValue(
          bucketTotals[bi] == 0 ? '-' : bucketTotals[bi].toString(),
        );
        totalCell.cellStyle = totalStyle;
      }

      const totalRow = 13;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
        ..value     = TextCellValue('Total')
        ..cellStyle = totalStyle;

      int grandTotal = 0;
      for (var mi = 0; mi < 12; mi++) {
        int colTotal = 0;
        for (var bi = 0; bi < durationBuckets.length; bi++) {
          colTotal += bucketData[bi][mi];
        }
        grandTotal += colTotal;
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: mi + 1, rowIndex: totalRow),
        );
        cell.value     = TextCellValue(colTotal == 0 ? '-' : colTotal.toString());
        cell.cellStyle = totalStyle;
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: totalRow))
        ..value     = TextCellValue(grandTotal == 0 ? '-' : grandTotal.toString())
        ..cellStyle = totalStyle;

      const varRow = 14;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: varRow))
        ..value     = TextCellValue('check variance')
        ..cellStyle = varianceStyle;

      for (var mi = 0; mi < 12; mi++) {
        int totalVar = 0;
        for (var bi = 0; bi < durationBuckets.length; bi++) {
          final v = bucketVariance(bucketData[bi]);
          totalVar += v[mi];
        }
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: mi + 1, rowIndex: varRow),
        );
        cell.value     = TextCellValue(totalVar == 0 ? '-' : totalVar.toString());
        cell.cellStyle = totalVar != 0 ? varianceStyle : dashStyle;
      }

      // ── RIGHT TABLE ─────────────────────────────────────────────────────
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: rStart, rowIndex: 0))
        ..value     = TextCellValue('Monthly Ticket Aging Summary')
        ..cellStyle = titleStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: rStart,     rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: rStart + 6, rowIndex: 0),
      );

      const rightHeaders = [
        'Month', 'Request', 'Cancelled',
        'Pending', 'Closed', 'Avg Resolution Time',
      ];
      for (var c = 0; c < rightHeaders.length; c++) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: 1),
        )
          ..value     = TextCellValue(rightHeaders[c])
          ..cellStyle = headerStyle;
      }

      int totalReq = 0, totalCan = 0, totalPen = 0, totalClo = 0;
      double totalMins = 0.0;
      int totalResCount = 0;

      for (var mi = 0; mi < 12; mi++) {
        final row = mi + 2;
        final req = monthRequests[mi];
        final can = monthCancelled[mi];
        final pro = monthInProgress[mi];
        final clo = monthClosed[mi];
        final rc  = monthResolvedCount[mi];
        final avg = rc > 0 ? monthTotalMins[mi] / rc : 0.0;

        totalReq += req;
        totalCan += can;
        totalPen += pro;
        totalClo += clo;
        totalMins += monthTotalMins[mi];
        totalResCount += rc;

        final rowData = [
          months[mi],
          req == 0 ? '-' : req.toString(),
          can == 0 ? '-' : can.toString(),
          pro == 0 ? '-' : pro.toString(),
          clo == 0 ? '-' : clo.toString(),
          rc  == 0 ? '-' : _formatMinutes(avg),
        ];

        for (var c = 0; c < rowData.length; c++) {
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: row),
          ).value = TextCellValue(rowData[c]);
        }
      }

      const rTotalRow = 15;
      final overallAvg = totalResCount > 0 ? totalMins / totalResCount : 0.0;
      final rTotalData = [
        'Total',
        totalReq      == 0 ? '-' : totalReq.toString(),
        totalCan      == 0 ? '-' : totalCan.toString(),
        totalPen      == 0 ? '-' : totalPen.toString(),
        totalClo      == 0 ? '-' : totalClo.toString(),
        totalResCount == 0 ? '-' : _formatMinutes(overallAvg),
      ];
      for (var c = 0; c < rTotalData.length; c++) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: rTotalRow),
        )
          ..value     = TextCellValue(rTotalData[c])
          ..cellStyle = totalStyle;
      }

      const rVarRow = 16;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: rStart, rowIndex: rVarRow))
        ..value     = TextCellValue('check variance')
        ..cellStyle = varianceStyle;
      for (var c = 1; c < rightHeaders.length; c++) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: rVarRow),
        ).value = TextCellValue('-');
      }

      sheet.setColumnWidth(0, 12.0);
      for (var i = 1; i <= 12; i++) sheet.setColumnWidth(i, 10.0);
      sheet.setColumnWidth(13, 8.0);
      sheet.setColumnWidth(14, 2.0);
      sheet.setColumnWidth(rStart,     12.0);
      sheet.setColumnWidth(rStart + 1, 10.0);
      sheet.setColumnWidth(rStart + 2, 12.0);
      sheet.setColumnWidth(rStart + 3, 14.0);
      sheet.setColumnWidth(rStart + 4, 10.0);
      sheet.setColumnWidth(rStart + 5, 12.0);
      sheet.setColumnWidth(rStart + 6, 20.0);

      // ── CATEGORY SHEET ──────────────────────────────────────────────────
      catSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value     = TextCellValue('Category Summary Report')
        ..cellStyle = titleStyle;
      catSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
      );

      const catHeaders = [
        'Category', 'Total Tickets', 'Resolved', 'Avg Resolution Time'
      ];
      for (var i = 0; i < catHeaders.length; i++) {
        catSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          ..value     = TextCellValue(catHeaders[i])
          ..cellStyle = headerStyle;
      }

      int catRow = 2;
      final sorted = _byCategory.entries.toList()
        ..sort((a, b) =>
            (b.value['count'] as int).compareTo(a.value['count'] as int));

      for (final entry in sorted) {
        final v     = entry.value;
        final count = v['count']         as int;
        final rc    = v['resolvedCount'] as int;
        final mins  = v['totalMinutes']  as double;
        final avg   = rc == 0 ? '-' : _formatMinutes(mins / rc);

        final rowData = [entry.key, count.toString(), rc.toString(), avg];
        for (var i = 0; i < rowData.length; i++) {
          catSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: catRow),
          ).value = TextCellValue(rowData[i]);
        }
        catRow++;
      }

      // ── ENCODE & DOWNLOAD ────────────────────────────────────────────────
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode');
      final now      = DateTime.now();
      final fileName =
          'ticket_report_${now.year}_${now.month.toString().padLeft(2, '0')}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob(
          [Uint8List.fromList(bytes)],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        final url    = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        Future.delayed(
          const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await TicketService.getAll();
      _monthly    = {};
      _byCategory = {};
      _daily      = {};

      for (final t in data) {
        final created = _parseDate(
          t['created_at'] ?? t['createdAt'] ?? t['date_created'],
        );

        final date = created ?? DateTime.now();
        final key  = "${date.year}-${date.month.toString().padLeft(2, '0')}";

        // Daily key: YYYY-MM-DD
        final dayKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        _daily[dayKey] = (_daily[dayKey] ?? 0) + 1;

        _monthly.putIfAbsent(key, () => {
          'total':         0,
          'resolved':      0,
          'cancelled':     0,
          'inprogress':    0,
          'closed':        0,
          'totalMinutes':  0.0,
          'resolvedCount': 0,
        });

        final m = _monthly[key]!;
        m['total']++;

        final status = (t['status'] ?? '').toString().toLowerCase();

        final category = (t['category']
            ?? t['tickettype']
            ?? t['ticket_type']
            ?? t['type']
            ?? 'Uncategorized')
            .toString()
            .trim();

        if (category.isNotEmpty) {
          _byCategory.putIfAbsent(category, () => {
            'count':         0,
            'totalMinutes':  0.0,
            'resolvedCount': 0,
          });
        }

        // ── Parse resolution time (API stores seconds, we need minutes) ──
        final parsedMinutes = _resolveMinutes(t, created);

        // ── Status counters ──
        if (status.contains('resolved')) {
          m['resolved']++;
        } else if (status.contains('closed')) {
          m['closed']++;
        } else if (status.contains('cancel')) {
          m['cancelled']++;
        } else {
          m['inprogress'] = (m['inprogress'] ?? 0) + 1;
        }

        // ── Accumulate resolution time for monthly avg ──
        final isResolved = status.contains('resolved') || status.contains('closed');
        if (isResolved) {
          m['resolvedCount'] = (m['resolvedCount'] ?? 0) + 1;  // ✅ always count
          if (parsedMinutes > 0) {
            m['totalMinutes'] = (m['totalMinutes'] ?? 0.0) + parsedMinutes;
          }
        }

        // ── Accumulate category stats ──
        if (category.isNotEmpty) {
          final cat = _byCategory[category]!;
          cat['count']++;
          if (isResolved) {
            cat['resolvedCount']++;  // ✅ always count
            if (parsedMinutes > 0) {
              cat['totalMinutes'] += parsedMinutes;
            }
          }
        }
      }
    } catch (e) {
      // silently swallow; UI stays empty
    }

    setState(() => _loading = false);
  }

  String _month(String key) {
    final p = key.split('-');
    if (p.length != 2) return key;
    final y = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${months[m]} $y";
  }

  // Returns 8 values: Date, Total, Resolved, Cancelled, Disapprove,
  //                   Pending, Closed, Avg Time
  List<List<String>> _rows() {
    final keys = _monthly.keys.toList()..sort();
    return keys.map((k) {
      final m = _monthly[k]!;
      return [
        _month(k),
        (m['total']      ?? 0).toString(),
        (m['resolved']   ?? 0).toString(),
        (m['cancelled']  ?? 0).toString(),
        (m['inprogress'] ?? 0).toString(),
        (m['closed']     ?? 0).toString(),
        _avg(m),                           // index 7 — Avg Time
      ];
    }).toList();
  }

  String _avg(Map<String, dynamic> m) {
    final count = (m['resolvedCount'] ?? 0) as int;
    if (count == 0) return 'N/A';
    final avg = (m['totalMinutes'] as double) / count;
    return _formatMinutes(avg);
  }

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return 'N/A';
    if (minutes >= 60 * 24) {
      return '${(minutes / (60 * 24)).toStringAsFixed(1)} days';
    } else if (minutes >= 60) {
      return '${(minutes / 60).toStringAsFixed(1)} hrs';
    }
    return '${minutes.toStringAsFixed(1)} min';
  }

  Map<String, dynamic> _stats() {
    double total         = 0;
    double completed     = 0; // resolved + closed
    double totalMinutes  = 0;
    double resolvedCount = 0;

    _monthly.forEach((_, m) {
      total        += (m['total']         ?? 0) as int;
      // ✅ completionRate includes both resolved AND closed
      completed    += ((m['resolved']     ?? 0) as int) +
          ((m['closed']       ?? 0) as int);
      totalMinutes += (m['totalMinutes']  ?? 0.0) as double;
      resolvedCount+= (m['resolvedCount'] ?? 0) as int;
    });

    final completionRate =
    total == 0 ? 0.0 : (completed / total) * 100;
    final avgResolution  =
    resolvedCount == 0 ? 0.0 : totalMinutes / resolvedCount;

    final now         = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final avgPerDay   = total == 0 ? 0.0 : total / daysInMonth;

    return {
      'total':          total,
      'avgPerDay':      avgPerDay,
      'completionRate': completionRate,
      'avgResolution':  avgResolution,
    };
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _cell(String t, {bool header = false}) {
    return SizedBox(
      width: 110,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 12,
            fontWeight: header ? FontWeight.bold : FontWeight.normal,
            color: header ? AppTheme.textMuted : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    const h = [
      'Date', 'Total', 'Resolved',
      'Cancelled', 'Pending', 'Closed', 'Avg Time',
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: h.map((e) => _cell(e, header: true)).toList()),
    );
  }

  Widget _row(List<String> d, bool even) {
    return Container(
      decoration: BoxDecoration(
        color: even ? Colors.transparent : AppTheme.border.withOpacity(0.1),
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _cell(d[0]),
          _cell(d[1]),
          _cell(d[2]),
          _cell(d[3]),
          _cell(d[4]),
          _cell(d[5]),
          _cell(d[6]),
        ],
      ),
    );
  }

  // ── Category table ───────────────────────────────────────────────────────
  Widget _categoryTable() {
    final entries = _byCategory.entries.toList()
      ..sort((a, b) =>
          (b.value['count'] as int).compareTo(a.value['count'] as int));

    const colWidths = [180.0, 80.0, 90.0];

    Widget catHeaderCell(String t, double w) => SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted)),
      ),
    );

    Widget catCell(String t, double w, {bool bold = false}) => SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          t,
          style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: const Text('By Category',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(children: [
              catHeaderCell('Category', colWidths[0]),
              catHeaderCell('Count',    colWidths[1]),
              catHeaderCell('Avg Time', colWidths[2]),
            ]),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No category data',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            )
          else
            ...entries.asMap().entries.map((entry) {
              final i     = entry.key;
              final cat   = entry.value.key;
              final v     = entry.value.value;
              final count = v['count']         as int;
              final rc    = v['resolvedCount'] as int;
              final mins  = v['totalMinutes']  as double;
              final avgStr = rc == 0 ? 'N/A' : _formatMinutes(mins / rc);
              return Container(
                decoration: BoxDecoration(
                  color: i % 2 != 0
                      ? AppTheme.border.withOpacity(0.1)
                      : Colors.transparent,
                  border: const Border(
                      bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(children: [
                  catCell(cat,              colWidths[0], bold: true),
                  catCell(count.toString(), colWidths[1]),
                  catCell(avgStr,           colWidths[2]),
                ]),
              );
            }),
        ],
      ),
    );
  }

  // ── Summary cards ────────────────────────────────────────────────────────
  Widget _summary() {
    final s = _stats();

    Widget card(String title, String value) {
      return Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          card('Total Request',   '${(s['total'] as double).toInt()}'),
          card('Avg Req / Day',   (s['avgPerDay'] as double).toStringAsFixed(1)),
          card('Completion Rate',
              s['total'] == 0.0
                  ? 'No data'
                  : '${(s['completionRate'] as double).toStringAsFixed(1)}%'),
          card('Avg Resolution Time',
              (s['avgResolution'] as double) == 0.0
                  ? 'No data'
                  : _formatMinutes(s['avgResolution'] as double)),
        ],
      ),
    );
  }

  // ── Daily bar chart ──────────────────────────────────────────────────────

  /// Returns the list of month keys available in the data, sorted.
  List<String> _availableMonths() {
    final months = _monthly.keys.toList()..sort();
    return months;
  }

  /// Returns daily data filtered to the selected (or latest) month.
  Map<String, int> _dailyForMonth(String monthKey) {
    final result = <String, int>{};
    _daily.forEach((dayKey, count) {
      if (dayKey.startsWith(monthKey)) result[dayKey] = count;
    });
    return result;
  }

  Widget _dailyBarChart() {
    final months   = _availableMonths();
    final selMonth = _selectedChartMonth ?? (months.isNotEmpty ? months.last : null);

    if (selMonth == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No data', style: TextStyle(fontSize: 12))),
      );
    }

    final dailyData = _dailyForMonth(selMonth);
    // Build a full list of days in the month so empty days show 0
    final parts = selMonth.split('-');
    final year  = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final days   = List.generate(daysInMonth, (i) {
      final d = i + 1;
      return "${year}-${month.toString().padLeft(2,'0')}-${d.toString().padLeft(2,'0')}";
    });
    final counts = days.map((d) => dailyData[d] ?? 0).toList();
    final maxVal = counts.fold<int>(0, (prev, v) => v > prev ? v : prev);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + month picker
          Row(
            children: [
              const Text('Daily Total Tickets',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              if (months.length > 1)
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selMonth,
                      isDense: true,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textPrimary),
                      items: months.map((mk) {
                        final p = mk.split('-');
                        const mn = ['','Jan','Feb','Mar','Apr','May','Jun',
                          'Jul','Aug','Sep','Oct','Nov','Dec'];
                        final label = '${mn[int.parse(p[1])]} ${p[0]}';
                        return DropdownMenuItem(value: mk, child: Text(label));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _selectedChartMonth = v),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Chart area
          SizedBox(
            height: 140,
            child: maxVal == 0
                ? Center(
                child: Text('No tickets this month',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)))
                : _BarChart(
              days: days,
              counts: counts,
              maxVal: maxVal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryVertical() {
    final s = _stats();

    Widget card(String title, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Row 1
        IntrinsicHeight(
          child: Row(
            children: [
              card('Total Tickets', '${(s['total'] as double).toInt()}'),
              const SizedBox(width: 10),
              card('Ave Request / Day',
                  (s['avgPerDay'] as double).toStringAsFixed(1)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Row 2
        IntrinsicHeight(
          child: Row(
            children: [
              card('Completion Rate',
                  s['total'] == 0.0
                      ? 'No data'
                      : '${(s['completionRate'] as double).toStringAsFixed(1)}%'),
              const SizedBox(width: 10),
              card('Avg Resolution Time',
                  (s['avgResolution'] as double) == 0.0
                      ? 'No data'
                      : _formatMinutes(s['avgResolution'] as double)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();

    return Column(
      children: [
        // ── TOP BAR ──
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppTheme.sidebarBg,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              const Text('Reports',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loading ? null : _confirmDownload,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // ── MAIN CONTENT ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [



                // ── Up ROW: Daily bar chart (full width) ──
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : _dailyBarChart(),
                ),

                const SizedBox(height: 16),
                // ── TOP ROW: Monthly table (left) + Category & Summary (right) ──
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly table
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 110.0 * 7,
                                    child: Column(
                                      children: [
                                        _header(),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: rows.length,
                                            itemBuilder: (_, i) =>
                                                _row(rows[i], i % 2 == 0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Category table + Summary cards
                      SizedBox(
                        width: 380,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Category table shrinks to content
                            _loading
                                ? Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            )
                                : _categoryTable(),
                            const SizedBox(height: 16),
                            // 2×2 summary grid
                            _summaryVertical(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDownload() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Download'),
        content: const Text('Do you want to download the Excel file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed == true) _exportExcel();
  }
}

// ── Bar Chart Widget ─────────────────────────────────────────────────────────

class _BarChart extends StatefulWidget {
  final List<String> days;
  final List<int>    counts;
  final int          maxVal;

  const _BarChart({
    required this.days,
    required this.counts,
    required this.maxVal,
  });

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth  = constraints.maxWidth;
      final chartHeight = constraints.maxHeight;
      final n           = widget.days.length;
      final barWidth    = (totalWidth / n).clamp(4.0, 24.0);
      final gap         = (totalWidth - barWidth * n) / (n + 1);

      return Stack(
        children: [
          // Y-axis grid lines
          CustomPaint(
            size: Size(totalWidth, chartHeight),
            painter: _GridPainter(maxVal: widget.maxVal),
          ),
          // Bars + hover overlay
          MouseRegion(
            onHover: (event) {
              final x   = event.localPosition.dx;
              int idx   = -1;
              for (var i = 0; i < n; i++) {
                final barX = gap + i * (barWidth + gap);
                if (x >= barX && x <= barX + barWidth) {
                  idx = i;
                  break;
                }
              }
              setState(() => _hoveredIndex = idx == -1 ? null : idx);
            },
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: CustomPaint(
              size: Size(totalWidth, chartHeight),
              painter: _BarPainter(
                days:         widget.days,
                counts:       widget.counts,
                maxVal:       widget.maxVal,
                barWidth:     barWidth,
                gap:          gap,
                hoveredIndex: _hoveredIndex,
              ),
            ),
          ),
          // Tooltip
          if (_hoveredIndex != null && _hoveredIndex! < n)
            _buildTooltip(
              totalWidth, chartHeight, n, barWidth, gap, _hoveredIndex!,
            ),
        ],
      );
    });
  }

  Widget _buildTooltip(double totalW, double chartH, int n,
      double barWidth, double gap, int idx) {
    final count = widget.counts[idx];
    final day   = widget.days[idx].split('-').last;
    final barX  = gap + idx * (barWidth + gap) + barWidth / 2;

    // Flip tooltip to the left side when near the right edge
    final tipW      = 72.0;
    final tipH      = 40.0;
    double tipLeft  = barX - tipW / 2;
    if (tipLeft + tipW > totalW) tipLeft = totalW - tipW - 4;
    if (tipLeft < 0) tipLeft = 4;

    final barHeightPct = widget.maxVal == 0 ? 0.0 : count / widget.maxVal;
    final barTop       = chartH * (1 - barHeightPct) - tipH - 6;
    final tipTop       = barTop.clamp(0.0, chartH - tipH - 4);

    return Positioned(
      left: tipLeft,
      top:  tipTop,
      child: IgnorePointer(
        child: Container(
          width:   tipW,
          height:  tipH,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:        const Color(0xFF1A7A1A),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Day $day',
                  style: const TextStyle(fontSize: 9, color: Colors.white70)),
              Text('$count ticket${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int maxVal;
  _GridPainter({required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * (1 - i / steps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

      final label = (maxVal * i / steps).round().toString();
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - textPainter.height - 1));
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.maxVal != maxVal;
}

class _BarPainter extends CustomPainter {
  final List<String> days;
  final List<int>    counts;
  final int          maxVal;
  final double       barWidth;
  final double       gap;
  final int?         hoveredIndex;

  _BarPainter({
    required this.days,
    required this.counts,
    required this.maxVal,
    required this.barWidth,
    required this.gap,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n           = days.length;
    final normalPaint = Paint()..color = const Color(0xFF4CAF50);
    final hovPaint    = Paint()..color = const Color(0xFF1A7A1A);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < n; i++) {
      final count  = counts[i];
      final barH = maxVal == 0 ? 0.0 : (count / maxVal) * size.height;
      final x      = gap + i * (barWidth + gap);
      final y      = size.height - barH;
      final isHov  = hoveredIndex == i;
      final rr     = const Radius.circular(3);

      final rect = RRect.fromLTRBAndCorners(
        x, y, x + barWidth, size.height,
        topLeft: rr, topRight: rr,
      );
      canvas.drawRRect(rect, isHov ? hovPaint : normalPaint);

      // Day label (show every 5th day to avoid crowding)
      if (i % 5 == 0 || i == n - 1) {
        final day = days[i].split('-').last;
        textPainter.text = TextSpan(
          text: day,
          style: const TextStyle(fontSize: 8, color: Color(0xFF757575)),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + barWidth / 2 - textPainter.width / 2,
              size.height + 2),
        );
      }

      // Count label on top of bar when hovered or bar is tall enough
      if (count > 0 && (isHov || barH > 18)) {
        textPainter.text = TextSpan(
          text: count.toString(),
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isHov ? const Color(0xFF1A7A1A) : const Color(0xFF4CAF50)),
        );
        textPainter.layout();
        canvas.drawRect(
          Rect.fromLTWH(
              x + barWidth / 2 - textPainter.width / 2 - 1,
              y - textPainter.height - 3,
              textPainter.width + 2,
              textPainter.height + 1),
          Paint()..color = Colors.white.withOpacity(0.85),
        );
        textPainter.paint(
          canvas,
          Offset(x + barWidth / 2 - textPainter.width / 2,
              y - textPainter.height - 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.hoveredIndex != hoveredIndex ||
          old.counts != counts ||
          old.maxVal != maxVal;
}