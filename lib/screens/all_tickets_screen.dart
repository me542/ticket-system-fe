import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:universal_html/html.dart' as html;
import '../core/services/api_file.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../models/ticket.dart';
import '../widgets/status_sidebar.dart';
import '../data/light_theme.dart';

class AllTicketsScreen extends StatefulWidget {
  const AllTicketsScreen({super.key});

  @override
  State<AllTicketsScreen> createState() => _AllTicketsScreenState();
}

class _AllTicketsScreenState extends State<AllTicketsScreen> {
  // ── Current user / role ───────────────────────────────────
  String _currentUsername = '';
  String _currentUserRole  = '';
  bool   _userLoaded       = false;

  static const _privilegedRoles = {'admin', 'endorser', 'approver', 'resolver'};
  bool get _isPrivileged =>
      _privilegedRoles.contains(_currentUserRole.toLowerCase().trim());

  // ── Search ────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  // ── Status Filter ─────────────────────────────────────────
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For', 'In', 'Resolved', 'Cancelled'];

  // ── Column Filters ────────────────────────────────────────
  final Map<String, String> _colFilters = {
    'category':    '',
    'priority':    '',
    'assignee':    '',
    'endorser':    '',
    'approver':    '',
    'status':      '',
    'tickettype':  '',
    'institution': '',
    'username':    '',
  };

  // ── Date Range Filters (created_at + updated_at) ──────────
  final Map<String, DateTime?> _dateFrom = {
    'created_at': null,
    'updated_at': null,
  };
  final Map<String, DateTime?> _dateTo = {
    'created_at': null,
    'updated_at': null,
  };

  // ── Pagination ────────────────────────────────────────────
  int _currentPage = 1;
  static const int _perPage = 20;

  // ── Data ──────────────────────────────────────────────────
  bool _loading    = true;
  bool _isExporting = false;

  List<Map<String, dynamic>> _rawData = [];
  List<Ticket> _tickets = [];

  // ── Sidebar ───────────────────────────────────────────────
  Ticket? _selectedTicket;
  bool    _isSidebarOpen = false;

  void _openTicket(Ticket ticket) => setState(() {
    _selectedTicket = ticket;
    _isSidebarOpen  = true;
  });

  void _closeSidebar() => setState(() => _isSidebarOpen = false);

  // ── Role-filtered base list ───────────────────────────────
  List<Map<String, dynamic>> get _roleFilteredRaw {
    if (_isPrivileged) return _rawData;
    return _rawData
        .where((r) =>
    (r['username'] ?? '').toString().toLowerCase().trim() ==
        _currentUsername.toLowerCase().trim())
        .toList();
  }

  // ── Full filter chain ─────────────────────────────────────
  List<Map<String, dynamic>> get _filteredRaw {
    var list = List<Map<String, dynamic>>.from(_roleFilteredRaw);

    // Date range filters (created_at + updated_at)
    for (final col in ['created_at', 'updated_at']) {
      final from = _dateFrom[col];
      final to   = _dateTo[col];
      if (from != null || to != null) {
        list = list.where((r) {
          final dt = DateTime.tryParse(r[col] ?? '');
          if (dt == null) return false;
          final afterStart = from == null || !dt.isBefore(from);
          final beforeEnd  = to   == null || !dt.isAfter(to);
          return afterStart && beforeEnd;
        }).toList();
      }
    }

    // Status tab
    if (_selectedFilter != 'All') {
      const map = {
        'For':       'for',
        'In':        'in',
        'Resolved':  'resolved',
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
      (r['ticket_id']  ?? '').toString().toLowerCase().contains(q) ||
          (r['subject']    ?? '').toString().toLowerCase().contains(q) ||
          (r['username']   ?? '').toString().toLowerCase().contains(q))
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
    final all   = _filteredRaw;
    final start = (_currentPage - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredRaw.length / _perPage).ceil().clamp(1, 999);

  List<String> _uniqueValues(String col) {
    final vals = _roleFilteredRaw
        .map((r) => (r[col] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return vals;
  }

  // ── Date filter helpers ───────────────────────────────────
  bool _hasDateFilter(String col) =>
      _dateFrom[col] != null || _dateTo[col] != null;

  String _dateFilterLabel(String col) {
    final f = _dateFrom[col];
    final t = _dateTo[col];
    String fmt(DateTime dt) =>
        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    if (f != null && t != null) return '${fmt(f)} → ${fmt(t)}';
    if (f != null) return '≥ ${fmt(f)}';
    if (t != null) return '≤ ${fmt(t)}';
    return '';
  }

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _searchController.addListener(() {
      setState(() {
        _search      = _searchController.text;
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Load user ─────────────────────────────────────────────
  Future<void> _loadCurrentUser() async {
    try {
      final savedUsername = await ApiLogin.getUsername();
      final users         = await ApiGetUser.fetchUsers();

      String role     = '';
      String username = savedUsername ?? '';

      if (savedUsername != null && savedUsername.isNotEmpty) {
        final match = users.firstWhere(
              (u) => (u['username'] ?? '').toLowerCase() ==
              savedUsername.toLowerCase(),
          orElse: () => {},
        );
        role = (match['role'] ?? '').toString();
      }
      if (role.isEmpty && users.isNotEmpty) {
        role = users.first['role'] ?? '';
      }

      debugPrint('🔐 all-tickets user: "$username"  role: "$role"');

      if (mounted) {
        setState(() {
          _currentUsername = username.toLowerCase().trim();
          _currentUserRole = role.toLowerCase().trim();
          _userLoaded      = true;
        });
      }
    } catch (e) {
      debugPrint('Could not load user: $e');
      if (mounted) setState(() => _userLoaded = true);
    }

    await _fetchAllTickets();
  }

  // ── Fetch all tickets ─────────────────────────────────────
  Future<void> _fetchAllTickets() async {
    setState(() => _loading = true);
    try {
      final data = await ApiTicket.getAllTickets();
      _rawData = data;
      _tickets = data.map<Ticket>((item) {
        final username = item['username'] ?? 'Unknown';
        return Ticket(
          id:                item['ticket_id'] ?? '',
          title:             item['subject'] ?? '',
          categoryName:      item['category'] ?? '',
          status:            _mapStatus(item['status'] ?? ''),
          priority:          _mapPriority(item['priority']),
          submitter:         username,
          submitterInitials: username.isNotEmpty ? username[0].toUpperCase() : '?',
          createdAt:         DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          description:       item['description'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Export filtered data ──────────────────────────────────
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
        'Cancelled By', 'Cancelled At', 'Started At',
        'Resolved At', 'Resolution Minutes',
      ];

      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value      = TextCellValue(headers[col]);
        cell.cellStyle  = headerStyle;
      }

      for (var i = 0; i < rows.length; i++) {
        final r    = rows[i];
        final vals = [
          r['ticket_id']          ?? '',
          r['username']           ?? '',
          r['category']           ?? '',
          r['subject']            ?? '',
          r['institution']        ?? '',
          r['tickettype']         ?? '',
          r['description']        ?? '',
          r['priority']?.toString() ?? '',
          r['assignee']           ?? '',
          r['endorser']           ?? '',
          r['approver']           ?? '',
          r['status']             ?? '',
          r['created_at']         ?? '',
          r['updated_at']         ?? '',
          r['cancelled_by']       ?? '',
          r['cancelled_at']       ?? '',
          r['started_at']         ?? '',
          r['resolved_at']        ?? '',
          r['resolution_minutes'] ?? '',
        ];

        for (var col = 0; col < vals.length; col++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1));
          cell.value = TextCellValue(vals[col].toString());
          if (i % 2 == 1) cell.cellStyle = evenStyle;
        }
      }

      const widths = [
        16.0, 14.0, 22.0, 30.0, 20.0, 14.0, 40.0, 10.0,
        14.0, 14.0, 14.0, 14.0, 20.0, 20.0, 14.0, 20.0,
        20.0, 20.0, 20.0,
      ];
      for (var i = 0; i < widths.length; i++) {
        sheet.setColumnWidth(i, widths[i]);
      }

      final bytes    = excel.encode();
      if (bytes == null) throw Exception('Failed to encode');
      final fileName =
          'tickets_${_selectedFilter.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
            const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
      case 'inprogress':    return TicketStatus.inProgress;
      case 'resolved':      return TicketStatus.resolved;
      case 'cancelled':     return TicketStatus.cancelled;
      default:              return TicketStatus.forAssessment;
    }
  }

  TicketPriority _mapPriority(dynamic p) {
    switch (int.tryParse(p.toString()) ?? 1) {
      case 2:  return TicketPriority.priority2;
      case 3:  return TicketPriority.priority3;
      default: return TicketPriority.priority1;
    }
  }

  // ── Role accent color ─────────────────────────────────────
  Color get _roleColor {
    switch (_currentUserRole) {
      case 'admin':    return Colors.white;
      case 'endorser': return Colors.white;
      case 'approver': return Colors.white;
      case 'resolver': return Colors.white;
      default:         return Colors.white;
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_userLoaded) {
      return const Scaffold(
        backgroundColor: AppTheme.sidebarBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(),
            if (!_isPrivileged) _buildUserBanner(),
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

        // ── Sidebar overlay ─────────────────────────────────
        if (_isSidebarOpen)
          GestureDetector(
            onTap: _closeSidebar,
            child: Container(color: Colors.black54),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0, bottom: 0,
          right: _isSidebarOpen ? 0 : -1040,
          child: TicketSidebar(
            ticket: _selectedTicket,
            onClose: _closeSidebar,
          ),
        ),
      ],
    );
  }

  // ── User-restricted info banner ───────────────────────────
  Widget _buildUserBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
      color: AppTheme.accent.withOpacity(0.07),
      child: Row(children: [
        Icon(Icons.lock_outline, size: 13, color: AppTheme.accent),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
            children: [
              const TextSpan(text: 'Showing only tickets submitted by '),
              TextSpan(
                text: _currentUsername,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${_roleFilteredRaw.length} ticket${_roleFilteredRaw.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ]),
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar() {
    final hasFilters = _selectedFilter != 'All' ||
        _colFilters.values.any((v) => v.isNotEmpty) ||
        _search.isNotEmpty ||
        _dateFrom.values.any((v) => v != null) ||
        _dateTo.values.any((v) => v != null);

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

          // ── Role chip ──────────────────────────────────────
          if (_currentUserRole.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: _roleColor.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                      color: _roleColor, shape: BoxShape.circle),
                ),
                Text(
                  _currentUserRole.toUpperCase(),
                  style: TextStyle(
                      color: _roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6),
                ),
              ]),
            ),
          ],

          const SizedBox(width: 16),

          // ── Search ─────────────────────────────────────────
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
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
              ]),
            ),
          ),

          const SizedBox(width: 12),

          // ── Export button (privileged only) ────────────────
          if (_isPrivileged)
            Tooltip(
              message: hasFilters
                  ? 'Download filtered tickets (${_filteredRaw.length})'
                  : 'Download all tickets (${_rawData.length})',
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportExcel,
                icon: _isExporting
                    ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
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

  // ── Table header ──────────────────────────────────────────
  Widget _buildTableHeader() {
    final visibleTotal = _roleFilteredRaw.length;
    final filtered     = _filteredRaw.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        const Text('Tickets',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Text(
          filtered != visibleTotal
              ? '$filtered of $visibleTotal'
              : '$visibleTotal total',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 8),

        // Active filter chips (column filters + date range filters)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Column filter chips
                ..._colFilters.entries
                    .where((e) => e.value.isNotEmpty)
                    .map((e) => _filterChip(
                  label: '${e.key}: ${e.value}',
                  onRemove: () => setState(() {
                    _colFilters[e.key] = '';
                    _currentPage = 1;
                  }),
                )),

                // Date range filter chips
                ..._dateFrom.keys
                    .where((col) => _hasDateFilter(col))
                    .map((col) => _filterChip(
                  label: '${col == 'created_at' ? 'Created' : 'Updated'}: ${_dateFilterLabel(col)}',
                  onRemove: () => setState(() {
                    _dateFrom[col] = null;
                    _dateTo[col]   = null;
                    _currentPage   = 1;
                  }),
                )),
              ],
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
                _currentPage    = 1;
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
      ]),
    );
  }

  Widget _filterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: AppTheme.accent),
          ),
        ],
      ),
    );
  }

  // ── Scrollable table ──────────────────────────────────────
  Widget _buildScrollableTable() {
    final cols = [
      _ColDef('Ticket ID',          'ticket_id',          120, false),
      _ColDef('Creator',            'username',           120, true),
      _ColDef('Category',           'category',           160, true),
      _ColDef('Subject',            'subject',            200, false),
      _ColDef('Institution',        'institution',        140, true),
      _ColDef('Type',               'tickettype',         120, true),
      _ColDef('Description',        'description',        220, false),
      _ColDef('Priority',           'priority',           90,  true),
      _ColDef('Assignee',           'assignee',           120, true),
      _ColDef('Endorser',           'endorser',           120, true),
      _ColDef('Approver',           'approver',           120, true),
      _ColDef('Status',             'status',             140, true),
      _ColDef('Created At',         'created_at',         160, true),
      _ColDef('Updated At',         'updated_at',         160, true),
      _ColDef('Cancelled By',       'cancelled_by',       120, true),
      _ColDef('Cancelled At',       'cancelled_at',       160, false),
      _ColDef('Started At',         'started_at',         160, false),
      _ColDef('Resolved At',        'resolved_at',        160, false),
      _ColDef('Resolution Minutes', 'resolution_minutes', 160, false),
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
            // ── Column headers ──────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                children: cols.map((col) {
                  final isDateCol =
                      col.key == 'created_at' || col.key == 'updated_at';
                  final hasFilter = isDateCol
                      ? _hasDateFilter(col.key)
                      : col.filterable &&
                      (_colFilters[col.key] ?? '').isNotEmpty;

                  return SizedBox(
                    width: col.width,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(children: [
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
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Data rows ───────────────────────────────────
            Expanded(
              child: page.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 36, color: AppTheme.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      _isPrivileged
                          ? 'No tickets found'
                          : 'You have not submitted any tickets yet.',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: page.length,
                itemBuilder: (_, i) {
                  final r      = page[i];
                  final isEven = i % 2 == 0;
                  final ticket = _tickets.firstWhere(
                        (t) => t.id == r['ticket_id'],
                    orElse: () => Ticket(
                      id:                r['ticket_id'] ?? '',
                      title:             r['subject'] ?? '',
                      categoryName:      r['category'] ?? '',
                      status:            _mapStatus(r['status'] ?? ''),
                      priority:          _mapPriority(r['priority']),
                      submitter:         r['username'] ?? '',
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
                              : AppTheme.border.withOpacity(0.15),
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
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 12,
                                    vertical: 10),
                                child: col.key == 'status'
                                    ? _statusChip(val)
                                    : col.key == 'priority'
                                    ? _priorityChip(val)
                                    : Text(
                                  val.isEmpty ? '—' : val,
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
  void _showColumnFilterMenu(String key, String label) async {
    // ── Date columns → custom range picker ──────────────────
    if (key == 'created_at' || key == 'updated_at') {
      final result = await showDateRangePickerDialog(
        context: context,
        title: label,
        initialFrom: _dateFrom[key],
        initialTo:   _dateTo[key],
      );
      if (result != null) {
        setState(() {
          _dateFrom[key] = result.from;
          _dateTo[key]   = result.to;
          _currentPage   = 1;
        });
      }
      return;
    }

    // ── Generic column filter ────────────────────────────────
    final options = _uniqueValues(key);
    if (options.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
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
                      _currentPage     = 1;
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
                      _currentPage     = 1;
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
    if (s.contains('resolved'))       color = AppTheme.statusResolved;
    else if (s.contains('cancel'))    color = AppTheme.statusCancelled;
    else if (s.contains('progress'))  color = AppTheme.statusProgress;
    else                              color = AppTheme.statusAssessment;

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
    final p     = int.tryParse(priority) ?? 0;
    final color = p == 1
        ? AppTheme.priority1
        : p == 2
        ? AppTheme.priority2
        : AppTheme.priority3;
    final label =
    p == 0 ? (priority.isEmpty ? '—' : priority) : 'P$p';
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
    final total   = _totalPages;
    final current = _currentPage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        Text(
              () {
            final start =
            _filteredRaw.isEmpty ? 0 : (current - 1) * _perPage + 1;
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
      ]),
    );
  }

  List<Widget> _buildPagePills(int current, int total) {
    final List<int> pages = [];
    if (total <= 5) {
      pages.addAll(List.generate(total, (i) => i + 1));
    } else {
      int start = (current - 2).clamp(1, total - 4);
      int end   = (start + 4).clamp(5, total);
      start     = (end - 4).clamp(1, total);
      pages.addAll(List.generate(end - start + 1, (i) => start + i));
    }
    return pages.map((p) {
      final isActive = p == current;
      return GestureDetector(
        onTap: () => setState(() => _currentPage = p),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: isActive ? AppTheme.accent : AppTheme.border),
          ),
          child: Center(
            child: Text('$p',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.normal,
                )),
          ),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Range Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DateRangeResult {
  final DateTime? from;
  final DateTime? to;
  const _DateRangeResult({this.from, this.to});
}

Future<_DateRangeResult?> showDateRangePickerDialog({
  required BuildContext context,
  required String title,
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  return showDialog<_DateRangeResult>(
    context: context,
    builder: (_) => _DateRangePickerDialog(
      title: title,
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
}

enum _RangeMode { relative, absolute }

class _DateRangePickerDialog extends StatefulWidget {
  final String title;
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const _DateRangePickerDialog({
    required this.title,
    this.initialFrom,
    this.initialTo,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  _RangeMode _mode = _RangeMode.absolute;

  DateTime? _startDate;
  DateTime? _endDate;
  bool      _selectingStart = true;

  late DateTime _leftMonth;
  late DateTime _rightMonth;

  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl   = TextEditingController();

  int    _relValue = 1;
  String _relUnit  = 'hours';

  static const _relUnits = ['minutes', 'hours', 'days', 'weeks'];
  static const _relPresets = [
    {'label': '5 minutes',  'value': 5,   'unit': 'minutes'},
    {'label': '30 minutes', 'value': 30,  'unit': 'minutes'},
    {'label': '1 hour',     'value': 1,   'unit': 'hours'},
    {'label': '3 hours',    'value': 3,   'unit': 'hours'},
    {'label': '12 hours',   'value': 12,  'unit': 'hours'},
    {'label': '1 day',      'value': 1,   'unit': 'days'},
    {'label': '3 days',     'value': 3,   'unit': 'days'},
    {'label': '7 days',     'value': 7,   'unit': 'days'},
    {'label': '30 days',    'value': 30,  'unit': 'days'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate  = widget.initialFrom;
    _endDate    = widget.initialTo;
    _leftMonth  = DateTime(now.year, now.month - 1);
    _rightMonth = DateTime(now.year, now.month);

    if (_startDate != null) _startTimeCtrl.text = _fmtTime(_startDate!);
    if (_endDate   != null) _endTimeCtrl.text   = _fmtTime(_endDate!);
  }

  @override
  void dispose() {
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime? dt) => dt == null
      ? ''
      : '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';

  void _prevMonth() => setState(() {
    _leftMonth  = DateTime(_leftMonth.year,  _leftMonth.month  - 1);
    _rightMonth = DateTime(_rightMonth.year, _rightMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _leftMonth  = DateTime(_leftMonth.year,  _leftMonth.month  + 1);
    _rightMonth = DateTime(_rightMonth.year, _rightMonth.month + 1);
  });

  void _onDayTap(DateTime day) {
    setState(() {
      if (_selectingStart) {
        _startDate      = day;
        _endDate        = null;
        _selectingStart = false;
      } else {
        if (day.isBefore(_startDate!)) {
          _endDate   = _startDate;
          _startDate = day;
        } else {
          _endDate = day;
        }
        _selectingStart = true;
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_startDate == null || _endDate == null) return false;
    return day.isAfter(_startDate!) && day.isBefore(_endDate!);
  }

  bool _isStart(DateTime day) =>
      _startDate != null &&
          day.year == _startDate!.year &&
          day.month == _startDate!.month &&
          day.day == _startDate!.day;

  bool _isEnd(DateTime day) =>
      _endDate != null &&
          day.year == _endDate!.year &&
          day.month == _endDate!.month &&
          day.day == _endDate!.day;

  bool _isFuture(DateTime day) =>
      day.isAfter(DateTime.now());

  (int, int, int)? _parseTime(String text) {
    final parts = text.split(':');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = int.tryParse(parts[2]);
    if (h == null || m == null || s == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59 || s < 0 || s > 59) return null;
    return (h, m, s);
  }

  void _applyRelative() {
    final now = DateTime.now();
    final Duration dur;
    switch (_relUnit) {
      case 'minutes': dur = Duration(minutes: _relValue); break;
      case 'hours':   dur = Duration(hours: _relValue);   break;
      case 'days':    dur = Duration(days: _relValue);    break;
      case 'weeks':   dur = Duration(days: _relValue * 7); break;
      default:        dur = Duration(hours: _relValue);
    }
    Navigator.of(context).pop(_DateRangeResult(
      from: now.subtract(dur),
      to:   now,
    ));
  }

  void _applyAbsolute() {
    if (_startDate == null) return;
    DateTime from = _startDate!;
    DateTime to   = _endDate ?? _startDate!;

    final st = _parseTime(_startTimeCtrl.text);
    final et = _parseTime(_endTimeCtrl.text);

    if (st != null) {
      from = DateTime(from.year, from.month, from.day, st.$1, st.$2, st.$3);
    }
    if (et != null) {
      to = DateTime(to.year, to.month, to.day, et.$1, et.$2, et.$3);
    } else {
      to = DateTime(to.year, to.month, to.day, 23, 59, 59);
    }

    Navigator.of(context).pop(_DateRangeResult(from: from, to: to));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2D3E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(),
            _buildModeTabs(),
            if (_mode == _RangeMode.absolute) _buildAbsoluteBody(),
            if (_mode == _RangeMode.relative)  _buildRelativeBody(),
            _buildDialogFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      child: Row(children: [
        Text(
          'Filter by ${widget.title}',
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, color: Color(0xFF8BA3BC), size: 18),
        ),
      ]),
    );
  }

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        _modeTab('Relative range', _RangeMode.relative),
        const SizedBox(width: 8),
        _modeTab('Absolute range', _RangeMode.absolute),
      ]),
    );
  }

  Widget _modeTab(String label, _RangeMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF268A15).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF268A15)
                : const Color(0xFF1E3A5F),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF268A15)
                : const Color(0xFF8BA3BC),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Relative body ─────────────────────────────────────────
  Widget _buildRelativeBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick presets',
              style: TextStyle(color: Color(0xFF8BA3BC), fontSize: 12)),
          const SizedBox(height: 0),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _relPresets.map((p) {
              final sel =
                  _relValue == p['value'] && _relUnit == p['unit'];
              return GestureDetector(
                onTap: () => setState(() {
                  _relValue = p['value'] as int;
                  _relUnit  = p['unit'] as String;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF268A15).withOpacity(0.2)
                        : const Color(0xFF131E2B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF268A15)
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                  child: Text(
                    p['label'] as String,
                    style: TextStyle(
                      color: sel
                          ? const Color(0xFF268A15)
                          : const Color(0xFF8BA3BC),
                      fontSize: 12,
                      fontWeight:
                      sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Custom',
              style: TextStyle(color: Color(0xFF8BA3BC), fontSize: 12)),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Last',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 12),
            Container(
              width: 70,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1520),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) setState(() => _relValue = n);
                },
                controller:
                TextEditingController(text: '$_relValue'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1520),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3A5F)),
              ),
              child: DropdownButton<String>(
                value: _relUnit,
                dropdownColor: const Color(0xFF0F1923),
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF8BA3BC), size: 16),
                items: _relUnits
                    .map((u) => DropdownMenuItem(
                    value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _relUnit = v);
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Absolute body ─────────────────────────────────────────
  Widget _buildAbsoluteBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Dual calendars
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.chevron_left,
                      color: Color(0xFF8BA3BC), size: 20),
                ),
              ),
              Expanded(child: _buildCalendar(_leftMonth)),
              Expanded(child: _buildCalendar(_rightMonth)),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.chevron_right,
                      color: Color(0xFF8BA3BC), size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Date + time inputs row
          Row(children: [
            Expanded(child: _buildDateTimeFields(
              dateLabel: 'Start date',
              timeLabel: 'Start time',
              dateValue: _fmtDate(_startDate),
              timeCtrl: _startTimeCtrl,
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildDateTimeFields(
              dateLabel: 'End date',
              timeLabel: 'End time',
              dateValue: _fmtDate(_endDate),
              timeCtrl: _endTimeCtrl,
            )),
          ]),

          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Range must be between today and the past 90 days. Use 24 hour format.',
              style: TextStyle(color: Color(0xFF4D6A82), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(DateTime month) {
    final days = _buildDayGrid(month);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_monthName(month.month)} ${month.year}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: const TextStyle(
                      color: Color(0xFF4D6A82),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ))
              .toList(),
        ),
        const SizedBox(height: 4),
        ...days.map((week) => Row(
          children: week.map((day) {
            if (day == null) {
              return const Expanded(child: SizedBox(height: 32));
            }
            final isStart  = _isStart(day);
            final isEnd    = _isEnd(day);
            final inRange  = _isInRange(day);
            final isFuture = _isFuture(day);
            final isToday  = day.year == DateTime.now().year &&
                day.month == DateTime.now().month &&
                day.day == DateTime.now().day;

            Color? bg;
            Color textColor = isFuture
                ? const Color(0xFF2E4A63)
                : Colors.white;
            BorderRadius? radius;

            if (isStart || isEnd) {
              bg        = const Color(0xFF268A15);
              textColor = Colors.white;
              radius    = BorderRadius.circular(20);
            } else if (inRange) {
              bg        = const Color(0xFF268A15).withOpacity(0.18);
              textColor = const Color(0xFF268A15);
            }

            return Expanded(
              child: GestureDetector(
                onTap: isFuture ? null : () => _onDayTap(day),
                child: MouseRegion(
                  cursor: isFuture
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: Container(
                    height: 32,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                        color: bg, borderRadius: radius),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: isStart || isEnd
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isToday && !isStart && !isEnd)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF268A15),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildDateTimeFields({
    required String dateLabel,
    required String timeLabel,
    required String dateValue,
    required TextEditingController timeCtrl,
  }) {
    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1520),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: Text(
              dateValue.isEmpty ? 'YYYY/MM/DD' : dateValue,
              style: TextStyle(
                color: dateValue.isEmpty
                    ? const Color(0xFF2E4A63)
                    : Colors.white,
                fontSize: 13,
                fontStyle: dateValue.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      )),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timeLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1520),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: TextField(
              controller: timeCtrl,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9:]')),
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                hintText: 'hh:mm:ss',
                hintStyle: TextStyle(
                    color: Color(0xFF2E4A63),
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      )),
    ]);
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildDialogFooter() {
    final canApply = _mode == _RangeMode.relative || _startDate != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      child: Row(children: [
        TextButton(
          onPressed: () {
            if (_mode == _RangeMode.absolute) {
              setState(() {
                _startDate      = null;
                _endDate        = null;
                _selectingStart = true;
                _startTimeCtrl.clear();
                _endTimeCtrl.clear();
              });
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8BA3BC),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Clear',
              style: TextStyle(fontSize: 13)),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8BA3BC),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel',
              style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: canApply
              ? (_mode == _RangeMode.relative
              ? _applyRelative
              : _applyAbsolute)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF268A15),
            foregroundColor: Colors.white,
            disabledBackgroundColor:
            const Color(0xFF268A15).withOpacity(0.3),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Text('Apply'),
        ),
      ]),
    );
  }

  // ── Calendar helpers ──────────────────────────────────────
  String _monthName(int m) => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][m];

  List<List<DateTime?>> _buildDayGrid(DateTime month) {
    final firstDay    = DateTime(month.year, month.month, 1);
    final lastDay     = DateTime(month.year, month.month + 1, 0);
    final startOffset = firstDay.weekday % 7;

    final List<DateTime?> flat = [
      ...List<DateTime?>.filled(startOffset, null),
      for (var d = 1; d <= lastDay.day; d++)
        DateTime(month.year, month.month, d),
    ];
    while (flat.length % 7 != 0) flat.add(null);

    return List.generate(
      flat.length ~/ 7,
          (i) => flat.sublist(i * 7, i * 7 + 7),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ColDef {
  final String label;
  final String key;
  final double width;
  final bool   filterable;
  const _ColDef(this.label, this.key, this.width, this.filterable);
}

class _PageButton extends StatelessWidget {
  final IconData     icon;
  final bool         enabled;
  final VoidCallback onTap;
  const _PageButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
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