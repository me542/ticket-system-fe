import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:universal_html/html.dart' as html;
import '../core/services/api_file.dart';
import '../core/services/api_login.dart';
import '../models/ticket.dart';
import '../widgets/status_sidebar.dart';
import '../data/app_theme.dart';

class AllTicketsScreen extends StatefulWidget {
  const AllTicketsScreen({super.key});

  @override
  State<AllTicketsScreen> createState() => _AllTicketsScreenState();
}

class _AllTicketsScreenState extends State<AllTicketsScreen> {
  // ── Search ────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  // ── Status Filter ─────────────────────────────────────────
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For', 'In', 'Resolved', 'Cancelled'];

  // ── Column Filters ────────────────────────────────────────
  final Map<String, String> _colFilters = {
    'category': '',
    'priority': '',
    'assignee': '',
    'endorser': '',
    'approver': '',
    'status': '',
    'tickettype': '',
    'institution': '',
    'username': '',
  };

  DateTime? _createdAtFrom;
  DateTime? _createdAtTo;

  // ── Pagination ────────────────────────────────────────────
  int _currentPage = 1;
  static const int _perPage = 20;

  // ── Data ──────────────────────────────────────────────────
  bool _loading = true;
  bool _isExporting = false;
  List<Map<String, dynamic>> _rawData = [];
  List<Ticket> _tickets = [];

  // ── Sidebar ───────────────────────────────────────────────
  Ticket? _selectedTicket;
  bool _isSidebarOpen = false;

  void _openTicket(Ticket ticket) => setState(() {
    _selectedTicket = ticket;
    _isSidebarOpen = true;
  });

  void _closeSidebar() => setState(() => _isSidebarOpen = false);

  // ── Computed ──────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredRaw {
    var list = List<Map<String, dynamic>>.from(_rawData);

    // Date range filter for "created_at"
    if (_createdAtFrom != null || _createdAtTo != null) {
      list = list.where((r) {
        final createdStr = r['created_at'] ?? '';
        final created = DateTime.tryParse(createdStr);
        if (created == null) return false;
        final afterStart = _createdAtFrom == null || !created.isBefore(_createdAtFrom!);
        final beforeEnd = _createdAtTo == null || !created.isAfter(_createdAtTo!);
        return afterStart && beforeEnd;
      }).toList();
    }



    // Status tab filter
    if (_selectedFilter != 'All') {
      final map = {
        'For': 'for',
        'In': 'in',
        'Resolved': 'resolved',
        'Cancelled': 'cancelled',
      };
      final prefix = map[_selectedFilter] ?? '';
      list = list
          .where((r) =>
          (r['status'] ?? '').toString().toLowerCase().startsWith(prefix))
          .toList();
    }

    // Search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((r) =>
      (r['ticket_id'] ?? '').toString().toLowerCase().contains(q) ||
          (r['subject'] ?? '').toString().toLowerCase().contains(q) ||
          (r['username'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }

    // Column filters
    _colFilters.forEach((col, val) {
      if (val.isNotEmpty) {
        list = list
            .where((r) =>
        (r[col] ?? '').toString().toLowerCase() == val.toLowerCase())
            .toList();
      }
    });

    return list;
  }

  List<Map<String, dynamic>> get _paginatedRaw {
    final all = _filteredRaw;
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredRaw.length / _perPage).ceil().clamp(1, 999);

  List<String> _uniqueValues(String col) {
    final vals = _rawData
        .map((r) => (r[col] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    vals.sort();
    return vals;
  }

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAllTickets();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text;
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────
  Future<void> _fetchAllTickets() async {
    setState(() => _loading = true);
    try {
      final data = await ApiTicket.getAllTickets();
      _rawData = data;
      _tickets = data.map<Ticket>((item) {
        final username = item['username'] ?? 'Unknown';
        return Ticket(
          id: item['ticket_id'] ?? '',
          title: item['subject'] ?? '',
          category: _mapCategory(item['category'] ?? ''),
          status: _mapStatus(item['status'] ?? ''),
          priority: _mapPriority(item['priority']),
          submitter: username,
          submitterInitials:
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          createdAt:
          DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          description: item['description'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Export filtered data as Excel ─────────────────────────
  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final rows = _filteredRaw;
      if (rows.isEmpty) throw Exception('No data to export');

      final excel = Excel.createExcel();
      final sheet = excel['Tickets Report'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A3A5C'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final evenStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F0F4F8'),
      );

      const headers = [
        'Ticket ID', 'Creator', 'Category', 'Subject', 'Institution',
        'Type', 'Description', 'Priority', 'Assignee', 'Endorser',
        'Approver', 'Status', 'Created At', 'Updated At',
        'Cancelled By', 'Cancelled At',
      ];

      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final vals = [
          r['ticket_id'] ?? '',
          r['username'] ?? '',
          r['category'] ?? '',
          r['subject'] ?? '',
          r['institution'] ?? '',
          r['tickettype'] ?? '',
          r['description'] ?? '',
          r['priority']?.toString() ?? '',
          r['assignee'] ?? '',
          r['endorser'] ?? '',
          r['approver'] ?? '',
          r['status'] ?? '',
          r['created_at'] ?? '',
          r['updated_at'] ?? '',
          r['cancelled_by'] ?? '',
          r['cancelled_at'] ?? '',
        ];

        for (var col = 0; col < vals.length; col++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1));
          cell.value = TextCellValue(vals[col].toString());
          if (i % 2 == 1) cell.cellStyle = evenStyle;
        }
      }

      final widths = [
        16.0, 14.0, 22.0, 30.0, 20.0, 14.0, 40.0, 10.0,
        14.0, 14.0, 14.0, 14.0, 20.0, 20.0, 14.0, 20.0,
      ];
      for (var i = 0; i < widths.length; i++) {
        sheet.setColumnWidth(i, widths[i]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode');

      final fileName =
          'tickets_${_selectedFilter.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob(
          [Uint8List.fromList(bytes)],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        Future.delayed(
            const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Mappers ───────────────────────────────────────────────
  TicketStatus _mapStatus(String s) {
    switch (s.toLowerCase().replaceAll(' ', '')) {
      case 'forassessment':
      case 'forendorsement':
      case 'forapproval':
      case 'forassignment':
        return TicketStatus.forAssessment;
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'cancelled':
        return TicketStatus.cancelled;
      default:
        return TicketStatus.forAssessment;
    }
  }

  TicketPriority _mapPriority(dynamic p) {
    switch (int.tryParse(p.toString()) ?? 1) {
      case 2:
        return TicketPriority.priority2;
      case 3:
        return TicketPriority.priority3;
      default:
        return TicketPriority.priority1;
    }
  }

  TicketCategory _mapCategory(String cat) {
    final c = cat.toLowerCase().trim();
    if (c.contains('customer premise')) return TicketCategory.customerPremise;
    if (c.contains('software')) return TicketCategory.softwareInstallation;
    if (c.contains('storage')) return TicketCategory.storageServer;
    if (c.contains('network')) return TicketCategory.networkConnection;
    if (c.contains('database')) return TicketCategory.databaseUserAccounts;
    if (c.contains('applications')) return TicketCategory.applicationsAmazon;
    if (c.contains('endpoint')) return TicketCategory.endpointDesktop;
    return TicketCategory.customerPremise;
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      Expanded(child: _buildScrollableTable()),
                      _buildPagination(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isSidebarOpen)
          GestureDetector(
            onTap: _closeSidebar,
            child: Container(color: Colors.black54),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: _isSidebarOpen ? 0 : -1040,
          child: TicketSidebar(
            ticket: _selectedTicket,
            onClose: _closeSidebar,
          ),
        ),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar() {
    final hasFilters = _selectedFilter != 'All' ||
        _colFilters.values.any((v) => v.isNotEmpty) ||
        _search.isNotEmpty;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Text('All Tickets',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search tickets...',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_search.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.close,
                            size: 14, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: hasFilters
                ? 'Download filtered tickets (${_filteredRaw.length})'
                : 'Download all tickets (${_rawData.length})',
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportExcel,
              icon: _isExporting
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.download_outlined, size: 16),
              label: Text(_isExporting ? 'Exporting…' : 'Download'),
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
          ),
        ],
      ),
    );
  }

  // ── Table header (title + active filter chips + status pills) ─
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text('Tickets',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(
            _filteredRaw.length != _rawData.length
                ? '${_filteredRaw.length} of ${_rawData.length}'
                : '${_rawData.length} total',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 8),
          // Active column filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colFilters.entries
                    .where((e) => e.value.isNotEmpty)
                    .map((e) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${e.key}: ${e.value}',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(
                                () => _colFilters[e.key] = ''),
                        child: Icon(Icons.close,
                            size: 12, color: AppTheme.accent),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),
          ),
          // Status filter pills
          Row(
            children: _filters.map((f) {
              final isSelected = _selectedFilter == f;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedFilter = f;
                  _currentPage = 1;
                }),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.border),
                  ),
                  child: Text(f,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Scrollable table ──────────────────────────────────────
  Widget _buildScrollableTable() {
    final cols = [
      _ColDef('Ticket ID',    'ticket_id',    120, false),
      _ColDef('Creator',      'username',     120, true),
      _ColDef('Category',     'category',     160, true),
      _ColDef('Subject',      'subject',      200, false),
      _ColDef('Institution',  'institution',  140, true),
      _ColDef('Type',         'tickettype',   120, true),
      _ColDef('Description',  'description',  220, false),
      _ColDef('Priority',     'priority',     90,  true),
      _ColDef('Assignee',     'assignee',     120, true),
      _ColDef('Endorser',     'endorser',     120, true),
      _ColDef('Approver',     'approver',     120, true),
      _ColDef('Status',       'status',       140, true),
      _ColDef('Created At',   'created_at',   160, true),
      _ColDef('Updated At',   'updated_at',   160, false),
      _ColDef('Cancelled By', 'cancelled_by', 120, true),
      _ColDef('Cancelled At', 'cancelled_at', 160, false),
    ];

    final totalWidth = cols.fold(0.0, (sum, c) => sum + c.width);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final page = _paginatedRaw;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            // Column headers
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                children: cols.map((col) {
                  final hasFilter = col.filterable &&
                      (_colFilters[col.key] ?? '').isNotEmpty;
                  return SizedBox(
                    width: col.width,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.label.toUpperCase(),
                              style: TextStyle(
                                color: hasFilter
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (col.filterable)
                            GestureDetector(
                              onTap: () => _showColumnFilterMenu(
                                  col.key, col.label),
                              child: Icon(
                                hasFilter
                                    ? Icons.filter_alt
                                    : Icons.filter_alt_outlined,
                                size: 14,
                                color: hasFilter
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Data rows
            Expanded(
              child: page.isEmpty
                  ? const Center(
                  child: Text('No tickets found',
                      style: TextStyle(
                          color: AppTheme.textSecondary)))
                  : ListView.builder(
                itemCount: page.length,
                itemBuilder: (_, i) {
                  final r = page[i];
                  final isEven = i % 2 == 0;
                  final ticket = _tickets.firstWhere(
                        (t) => t.id == r['ticket_id'],
                    orElse: () => Ticket(
                      id: r['ticket_id'] ?? '',
                      title: r['subject'] ?? '',
                      category:
                      _mapCategory(r['category'] ?? ''),
                      status: _mapStatus(r['status'] ?? ''),
                      priority: _mapPriority(r['priority']),
                      submitter: r['username'] ?? '',
                      submitterInitials: (r['username'] ?? 'U')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      createdAt: DateTime.tryParse(
                          r['created_at'] ?? '') ??
                          DateTime.now(),
                      description: r['description'] ?? '',
                    ),
                  );

                  return GestureDetector(
                    onTap: () => _openTicket(ticket),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isEven
                              ? Colors.transparent
                              : AppTheme.border
                              .withOpacity(0.15),
                          border: const Border(
                            bottom: BorderSide(
                                color: AppTheme.border,
                                width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: cols.map((col) {
                            final val =
                            (r[col.key] ?? '').toString();
                            return SizedBox(
                              width: col.width,
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10),
                                child: col.key == 'status'
                                    ? _statusChip(val)
                                    : col.key == 'priority'
                                    ? _priorityChip(val)
                                    : Text(
                                  val.isEmpty
                                      ? '—'
                                      : val,
                                  style: const TextStyle(
                                    color: AppTheme
                                        .textPrimary,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Column filter popup ───────────────────────────────────
  void _showColumnFilterMenu(String key, String label) {
    final options = _uniqueValues(key);
    if (options.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Filter by $label',
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 15)),
        content: SizedBox(
          width: 260,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  title: const Text('All (clear filter)',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13)),
                  leading: Icon(
                    (_colFilters[key] ?? '').isEmpty
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: AppTheme.accent,
                  ),
                  onTap: () {
                    setState(() {
                      _colFilters[key] = '';
                      _currentPage = 1;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(color: AppTheme.border),
                ...options.map((opt) => ListTile(
                  dense: true,
                  title: Text(opt,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13)),
                  leading: Icon(
                    _colFilters[key] == opt
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: AppTheme.accent,
                  ),
                  onTap: () {
                    setState(() {
                      _colFilters[key] = opt;
                      _currentPage = 1;
                    });
                    Navigator.pop(ctx);
                  },
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Chips ─────────────────────────────────────────────────
  Widget _statusChip(String status) {
    Color color;
    final s = status.toLowerCase();
    if (s.contains('resolved')) {
      color = AppTheme.statusResolved;
    } else if (s.contains('cancel')) {
      color = AppTheme.statusCancelled;
    } else if (s.contains('progress')) {
      color = AppTheme.statusProgress;
    } else {
      color = AppTheme.statusAssessment;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _priorityChip(String priority) {
    final p = int.tryParse(priority) ?? 0;
    final color = p == 1
        ? AppTheme.priority1
        : p == 2
        ? AppTheme.priority2
        : AppTheme.priority3;
    final label = p == 0 ? (priority.isEmpty ? '—' : priority) : 'P$p';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ── Pagination ────────────────────────────────────────────
  Widget _buildPagination() {
    final total = _totalPages;
    final current = _currentPage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text(
                () {
              final start = _filteredRaw.isEmpty
                  ? 0
                  : (current - 1) * _perPage + 1;
              final end =
              (current * _perPage).clamp(0, _filteredRaw.length);
              return 'Showing $start–$end of ${_filteredRaw.length}';
            }(),
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          _PageButton(
            icon: Icons.chevron_left,
            enabled: current > 1,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 4),
          ..._buildPagePills(current, total),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_right,
            enabled: current < total,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPagePills(int current, int total) {
    final List<int> pages = [];
    if (total <= 5) {
      pages.addAll(List.generate(total, (i) => i + 1));
    } else {
      int start = (current - 2).clamp(1, total - 4);
      int end = (start + 4).clamp(5, total);
      start = (end - 4).clamp(1, total);
      pages.addAll(List.generate(end - start + 1, (i) => start + i));
    }
    return pages.map((p) {
      final isActive = p == current;
      return GestureDetector(
        onTap: () => setState(() => _currentPage = p),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: isActive ? AppTheme.accent : AppTheme.border),
          ),
          child: Center(
            child: Text('$p',
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.normal,
                )),
          ),
        ),
      );
    }).toList();
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _ColDef {
  final String label;
  final String key;
  final double width;
  final bool filterable;
  const _ColDef(this.label, this.key, this.width, this.filterable);
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon,
            size: 18,
            color:
            enabled ? AppTheme.textSecondary : AppTheme.textMuted),
      ),
    );
  }
}