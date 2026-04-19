import 'package:flutter/material.dart';
import '../core/services/api_ticket_service.dart';
import '../data/light_theme.dart';

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
        final key = "${date.year}-${date.month}";

        _monthly.putIfAbsent(key, () {
          return {
            'total': 0,
            'resolved': 0,
            'cancelled': 0,
            'disapprove': 0,
            'pending': 0,
            'totalMinutes': 0.0,
            'resolvedCount': 0,
          };
        });

        final m = _monthly[key]!;

        m['total']++;

        final status = (t['status'] ?? '').toString().toLowerCase();

        final minutes =
            double.tryParse(t['resolution_minutes']?.toString() ?? '0') ?? 0;

        if (status.contains('resolved')) {
          m['resolved']++;
          m['totalMinutes'] += minutes;
          m['resolvedCount']++;
        } else if (status.contains('cancel')) {
          m['cancelled']++;
        } else if (status.contains('disapprove')) {
          m['disapprove']++;
        } else {
          m['pending']++;
        }
      }
    } catch (e) {
      debugPrint("LOAD ERROR: $e");
    }

    setState(() => _loading = false);
  }

  String _month(String key) {
    final p = key.split('-');
    if (p.length != 2) return key;

    final y = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;

    const months = [
      '',
      'Jan','Feb','Mar','Apr','May','Jun',
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
    if (count == 0) return "0 min";

    final avg = (m['totalMinutes'] ?? 0) / count;
    return _formatMinutes(avg);
  }

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return "0 min";

    if (minutes >= 60 * 24) {
      return "${(minutes / (60 * 24)).toStringAsFixed(1)} days";
    } else if (minutes >= 60) {
      return "${(minutes / 60).toStringAsFixed(1)} hrs";
    }

    return "${minutes.toStringAsFixed(0)} min";
  }

  // ===================== STATS =====================
  Map<String, dynamic> _stats() {
    int total = 0;
    int resolved = 0;
    double totalMinutes = 0;
    int resolvedCount = 0;

    _monthly.forEach((_, m) {
      // total += m['total'] ?? 0;
      // resolved += m['resolved'] ?? 0;
      // totalMinutes += (m['totalMinutes'] ?? 0);
      // resolvedCount += (m['resolvedCount'] ?? 0);
    });

    final completionRate = total == 0 ? 0 : (resolved / total) * 100;

    final avgResolution =
    resolvedCount == 0 ? 0 : totalMinutes / resolvedCount;

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
        ),
      );
    }

    return Row(
      children: [
        card("Total Request (Month)", "${s['total']}"),
        card("Avg Req / Day",
            (s['avgPerDay'] as double).toStringAsFixed(1)),
        card(
          "Completion Rate",
          s['total'] == 0
              ? "No data"
              : "${(s['completionRate'] as double).toStringAsFixed(1)}%",
        ),
        card("Avg Resolution Time",
            _formatMinutes(s['avgResolution'])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();

    return Column(
      children: [
        // TOP BAR (RESTORED DOWNLOAD UI)
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
                onPressed: () {},
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Download"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
                            itemBuilder: (_, i) =>
                                _row(rows[i], i % 2 == 0),
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
