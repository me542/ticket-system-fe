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

  Future<void> _exportExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Report'];
      excel.delete('Sheet1');

      // ── Styles ────────────────────────────────────────────
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
        'January','February','March','April','May','June',
        'July','August','September','October','November','December',
      ];

      const durationBuckets = [
        '1 hour', '3 hours', '8 hours', '1 day',
        '2 days', '5 days', '2 weeks', '1 month',
        '2 months', '3 months',
      ];

      const bucketThresholds = [
        60, 180, 480, 1440, 2880, 7200, 20160, 43200, 86400, 129600
      ];

      // ── Compute data ──────────────────────────────────────
      final bucketData = List.generate(
        durationBuckets.length, (_) => List.filled(12, 0),
      );
      final bucketTotals = List.filled(durationBuckets.length, 0);

      final monthRequests      = List.filled(12, 0);
      final monthCancelled     = List.filled(12, 0);
      final monthDisapprove    = List.filled(12, 0);
      final monthPending       = List.filled(12, 0);
      final monthTotalMins     = List.filled(12, 0.0);
      final monthResolvedCount = List.filled(12, 0);

      _monthly.forEach((key, m) {
        final parts = key.split('-');
        if (parts.length != 2) return;
        final monthIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        if (monthIdx < 0 || monthIdx > 11) return;

        monthRequests[monthIdx]      += (m['total']        as int?    ?? 0);
        monthCancelled[monthIdx]     += (m['cancelled']    as int?    ?? 0);
        monthDisapprove[monthIdx]    += (m['disapprove']   as int?    ?? 0);
        monthPending[monthIdx]       += (m['pending']      as int?    ?? 0);
        monthTotalMins[monthIdx]     += (m['totalMinutes'] as double? ?? 0.0);
        monthResolvedCount[monthIdx] += (m['resolvedCount'] as int?   ?? 0);
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

      // ─────────────────────────────────────────────────────
      // LEFT TABLE
      // ─────────────────────────────────────────────────────

      // Title
      final titleCellL = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      );
      titleCellL.value     = TextCellValue('Monthly Ticket Duration Summary');
      titleCellL.cellStyle = titleStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0,  rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: 0),
      );

      // Header row
      final leftHeaders = ['Duration', ...months, 'Total'];
      for (var c = 0; c < leftHeaders.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1),
        );
        cell.value     = TextCellValue(leftHeaders[c]);
        cell.cellStyle = headerStyle;
      }

      // Bucket rows
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

      // Total row
      const totalRow = 13;
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      ).value = TextCellValue('Total');
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      ).cellStyle = totalStyle;

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
      final grandTotalCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: totalRow),
      );
      grandTotalCell.value     = TextCellValue(grandTotal == 0 ? '-' : grandTotal.toString());
      grandTotalCell.cellStyle = totalStyle;

      // Variance row
      const varRow = 14;
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: varRow),
      ).value = TextCellValue('check variance');
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: varRow),
      ).cellStyle = varianceStyle;

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

      // ─────────────────────────────────────────────────────
      // RIGHT TABLE
      // ─────────────────────────────────────────────────────

      // Title
      final titleCellR = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: rStart, rowIndex: 0),
      );
      titleCellR.value     = TextCellValue('Monthly Ticket Aging Summary');
      titleCellR.cellStyle = titleStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: rStart,     rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: rStart + 6, rowIndex: 0),
      );

      // Header row
      const rightHeaders = [
        'Month', 'Request', 'Cancelled', 'Disapproved',
        'Pending', 'Avg Resolution Time', 'Cancelled',
      ];
      for (var c = 0; c < rightHeaders.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: 1),
        );
        cell.value     = TextCellValue(rightHeaders[c]);
        cell.cellStyle = headerStyle;
      }

      // Month rows
      int totalReq = 0, totalCan = 0, totalDis = 0, totalPen = 0;
      double totalMins = 0.0;
      int totalResCount = 0;

      for (var mi = 0; mi < 12; mi++) {
        final row = mi + 2;
        final req = monthRequests[mi];
        final can = monthCancelled[mi];
        final dis = monthDisapprove[mi];
        final pen = monthPending[mi];
        final rc  = monthResolvedCount[mi];
        final avg = rc > 0 ? monthTotalMins[mi] / rc : 0.0;

        totalReq += req;
        totalCan += can;
        totalDis += dis;
        totalPen += pen;
        totalMins += monthTotalMins[mi];
        totalResCount += rc;

        final rowData = [
          months[mi],
          req == 0 ? '-' : req.toString(),
          can == 0 ? '-' : can.toString(),
          dis == 0 ? '-' : dis.toString(),
          pen == 0 ? '-' : pen.toString(),
          rc  == 0 ? '-' : _formatMinutes(avg),
          can == 0 ? '-' : can.toString(),
        ];

        for (var c = 0; c < rowData.length; c++) {
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: row),
          ).value = TextCellValue(rowData[c]);
        }
      }

      // Total row
      const rTotalRow = 15;
      final overallAvg = totalResCount > 0 ? totalMins / totalResCount : 0.0;
      final rTotalData = [
        'Total',
        totalReq == 0 ? '-' : totalReq.toString(),
        totalCan == 0 ? '-' : totalCan.toString(),
        totalDis == 0 ? '-' : totalDis.toString(),
        totalPen == 0 ? '-' : totalPen.toString(),
        totalResCount == 0 ? '-' : _formatMinutes(overallAvg),
        totalCan == 0 ? '-' : totalCan.toString(),
      ];
      for (var c = 0; c < rTotalData.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: rTotalRow),
        );
        cell.value     = TextCellValue(rTotalData[c]);
        cell.cellStyle = totalStyle;
      }

      // Variance row
      const rVarRow = 16;
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: rStart, rowIndex: rVarRow),
      ).value = TextCellValue('check variance');
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: rStart, rowIndex: rVarRow),
      ).cellStyle = varianceStyle;
      for (var c = 1; c < rightHeaders.length; c++) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: rStart + c, rowIndex: rVarRow),
        ).value = TextCellValue('-');
      }

      // ── Column widths ─────────────────────────────────────
      sheet.setColumnWidth(0, 12.0);
      for (var i = 1; i <= 12; i++) sheet.setColumnWidth(i, 10.0);
      sheet.setColumnWidth(13, 8.0);
      sheet.setColumnWidth(14, 2.0);
      sheet.setColumnWidth(rStart,     12.0);
      sheet.setColumnWidth(rStart + 1, 10.0);
      sheet.setColumnWidth(rStart + 2, 12.0);
      sheet.setColumnWidth(rStart + 3, 14.0);
      sheet.setColumnWidth(rStart + 4, 10.0);
      sheet.setColumnWidth(rStart + 5, 20.0);
      sheet.setColumnWidth(rStart + 6, 12.0);

      // ── Download ──────────────────────────────────────────
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
      _monthly = {};

      for (final t in data) {

        final created = _parseDate(
          t['created_at'] ?? t['createdAt'] ?? t['date_created'],
        );

        final date = created ?? DateTime.now();
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";

        _monthly.putIfAbsent(key, () => {
          'total': 0,
          'resolved': 0,
          'cancelled': 0,
          'disapprove': 0,
          'pending': 0,
          'totalMinutes': 0.0,
          'resolvedCount': 0,
        });

        final m = _monthly[key]!;
        m['total']++;

        final status = (t['status'] ?? '').toString().toLowerCase();

        // FIX: use num.tryParse so it safely handles both num and String types
        double parsedMinutes = 0.0;

        final rawMinutes = t['resolution_minutes'];
        if (rawMinutes != null) {
          final parsed = num.tryParse(rawMinutes.toString()) ?? 0;
          if (parsed > 0) parsedMinutes = parsed.toDouble();
        }

        // Fallback: compute from timestamps if resolution_minutes is still 0
        if (parsedMinutes == 0.0) {
          final resolved = _parseDate(
            t['resolved_at'] ?? t['resolvedAt'],
          );

          if (created != null && resolved != null) {
            final diff = resolved.difference(created).inMinutes.toDouble();
            if (diff > 0) parsedMinutes = diff;
          } else {
          }
        }

        if (status.contains('resolved')) {
          m['resolved']++;
          // FIX: only count toward average if we actually have a valid time
          if (parsedMinutes > 0) {
            m['totalMinutes'] += parsedMinutes;
            m['resolvedCount']++;
          }
        } else if (status.contains('cancel')) {
          m['cancelled']++;
        } else if (status.contains('disapprove')) {
          m['disapprove']++;
        } else {
          m['pending']++;
        }
      }
    } catch (e) {
    }

    setState(() => _loading = false);
  }

  String _month(String key) {
    final p = key.split('-');
    if (p.length != 2) return key;
    final y = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    const months = [
      '', 'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return "${months[m]} $y";
  }

  List<List<String>> _rows() {
    final keys = _monthly.keys.toList()..sort();
    return keys.map((k) {
      final m = _monthly[k]!;
      return [
        _month(k),
        m['total'].toString(),
        m['resolved'].toString(),
        m['cancelled'].toString(),
        m['disapprove'].toString(),
        m['pending'].toString(),
        _avg(m),
      ];
    }).toList();
  }

  String _avg(Map<String, dynamic> m) {
    final count = m['resolvedCount'] ?? 0;
    if (count == 0) return "N/A";
    final avg = (m['totalMinutes'] ?? 0) / count;
    return _formatMinutes(avg);
  }

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return "N/A";
    if (minutes >= 60 * 24) {
      return "${(minutes / (60 * 24)).toStringAsFixed(1)} days";
    } else if (minutes >= 60) {
      return "${(minutes / 60).toStringAsFixed(1)} hrs";
    }
    return "${minutes.toStringAsFixed(1)} min";
  }

  // ===================== STATS =====================
  Map<String, dynamic> _stats() {
    double total = 0;
    double resolved = 0;
    double totalMinutes = 0;
    double resolvedCount = 0;

    _monthly.forEach((_, m) {
      total += m['total'] ?? 0;
      resolved += m['resolved'] ?? 0;
      totalMinutes += (m['totalMinutes'] ?? 0);
      resolvedCount += (m['resolvedCount'] ?? 0);
    });

    final completionRate = total == 0 ? 0 : (resolved / total) * 100;
    final avgResolution = resolvedCount == 0 ? 0 : totalMinutes / resolvedCount;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final avgPerDay = total == 0 ? 0 : total / daysInMonth;

    return {
      "total": total,
      "avgPerDay": avgPerDay,
      "completionRate": completionRate,
      "avgResolution": avgResolution,
    };
  }

  Widget _cell(String t, {bool header = false}) {
    return SizedBox(
      width: 160,
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
      "Date","Total","Resolved",
      "Cancelled","Disapprove","Pending","Avg Time"
    ];
    return Row(
      children: h.map((e) => _cell(e, header: true)).toList(),
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

  // ===================== SUMMARY =====================
  Widget _summary() {
    final s = _stats();

    Widget card(String title, String value) {
      return Expanded(
        child: Container(
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
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card("Total Request (Month)", "${s['total'].toInt()}"),
        card("Avg Req / Day", (s['avgPerDay'] as double).toStringAsFixed(1)),
        card(
          "Completion Rate",
          s['total'] == 0
              ? "No data"
              : "${(s['completionRate'] as double).toStringAsFixed(1)}%",
        ),
        card(
          "Avg Resolution Time",
          s['avgResolution'] == 0
              ? "No data"
              : _formatMinutes((s['avgResolution'] as num).toDouble()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();

    return Column(
      children: [
        // TOP BAR
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppTheme.sidebarBg,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              const Text(
                "Reports",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loading ? null : _exportExcel,
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Download"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // TABLE + SUMMARY
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
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
                      children: [
                        _header(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (_, i) => _row(rows[i], i % 2 == 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _summary(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}