import 'package:flutter/material.dart';
import '../core/services/api_file.dart';
import '../core/services/api_export.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../data/light_theme.dart';
import '../models/ticket.dart';
import '../widgets/file_ticket.dart';
import '../widgets/stats_card.dart';
import 'package:ticket_system/widgets/ticket_row.dart';
import '../widgets/status_sidebar.dart';
import 'dart:ui';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  DateTime? _lastSeenActivityTime;

  bool get _hasNewActivity {
    if (_activities.isEmpty) return false;
    if (_lastSeenActivityTime == null) return true;
    return _activities.first.time.isAfter(_lastSeenActivityTime!);
  }

  List<ActivityItem> get _visibleActivities {
    if (_isPrivileged) return _activities;
    return _activities
        .where((a) =>
    a.actor.toLowerCase().trim() ==
        _currentUsername.toLowerCase().trim())
        .toList();
  }

  // ── Current user ─────────────────────────────────────────
  String _currentUsername = '';
  String _currentUserRole  = '';
  bool   _userLoaded       = false;

  static const _privilegedRoles = {'admin', 'endorser', 'approver', 'resolver'};

  bool get _isPrivileged =>
      _privilegedRoles.contains(_currentUserRole.toLowerCase().trim());

  // ── Sidebar ──────────────────────────────────────────────
  Ticket? _selectedTicket;
  bool _isSidebarOpen = false;
  bool _isCreateOpen  = false;

  void _openTicket(Ticket ticket) => setState(() {
    _selectedTicket = ticket;
    _isSidebarOpen  = true;
  });

  void _closeSidebar() => setState(() => _isSidebarOpen = false);

  // ── Notification Overlay ──────────────────────────────────
  final LayerLink    _notificationLink    = LayerLink();
  OverlayEntry?      _notificationOverlay;

  void _toggleNotificationPanel() => _notificationOverlay != null
      ? _closeNotificationPanel()
      : _showNotificationPanel();

  void _showNotificationPanel() {
    final overlay = Overlay.of(context);

    _lastSeenActivityTime = _activities.isNotEmpty
        ? _activities.first.time
        : DateTime.now();

    _notificationOverlay = OverlayEntry(
      builder: (ctx) => Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeNotificationPanel,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
          ),
        ),
        Positioned(
          top: 55,
          right: 24,
          child: CompositedTransformFollower(
            link: _notificationLink,
            showWhenUnlinked: false,
            offset: const Offset(-120, 60),
            child: Material(
              color: Colors.transparent,
              child: _NotificationDropdown(
                activities: _visibleActivities,
                getColor: _activityColor,
                getLabel: _actionLabel,
              ),
            ),
          ),
        ),
      ]),
    );
    overlay.insert(_notificationOverlay!);
  }

  void _closeNotificationPanel() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  String _actionLabel(ActivityType type) {
    switch (type) {
      case ActivityType.submitted: return 'submitted';
      case ActivityType.moved:     return 'moved to In Progress';
      case ActivityType.resolved:  return 'resolved';
      case ActivityType.cancelled: return 'cancelled';
      case ActivityType.assigned:  return 'assigned';
    }
  }

  // ── Filter & Search ───────────────────────────────────────
  String _selectedFilter = 'All';

  /// Filter pills — the "For X" labels must match exactly what the API returns.
  final List<String> _filters = [
    'All',
    'For Assessment',
    'For Endorsement',
    'For Approval',
    'For Assignment',
    'In Progress',
    'Resolved',
    'Cancelled',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isExporting = false;

  // ── Data ─────────────────────────────────────────────────
  final List<Ticket>       _allTickets  = [];
  final List<ActivityItem> _activities  = [];
  final Map<String, int>   _categoryCount = {};

  // ── Role-filtered ticket list ─────────────────────────────
  List<Ticket> get _roleFilteredTickets {
    if (_isPrivileged) return _allTickets;
    return _allTickets
        .where((t) =>
    t.submitter.toLowerCase().trim() ==
        _currentUsername.toLowerCase().trim())
        .toList();
  }

  // ── Status + search filter ────────────────────────────────
  List<Ticket> get _filteredTickets {
    List<Ticket> list;

    if (_selectedFilter == 'All') {
      list = List.from(_roleFilteredTickets);
    } else if (_selectedFilter == 'In Progress') {
      list = _roleFilteredTickets
          .where((t) => t.status == TicketStatus.inProgress)
          .toList();
    } else if (_selectedFilter == 'Resolved') {
      list = _roleFilteredTickets
          .where((t) => t.status == TicketStatus.resolved)
          .toList();
    } else if (_selectedFilter == 'Cancelled') {
      list = _roleFilteredTickets
          .where((t) => t.status == TicketStatus.cancelled)
          .toList();
    } else {
      // "For Assessment" / "For Endorsement" / "For Approval" / "For Assignment"
      // Match the rawStatus directly (case-insensitive)
      final filterNorm = _selectedFilter.toLowerCase().replaceAll(' ', '');
      list = _roleFilteredTickets.where((t) {
        final raw = t.rawStatus.toLowerCase().replaceAll(' ', '');
        return raw == filterNorm;
      }).toList();
    }

    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((t) =>
    t.title.toLowerCase().contains(q) ||
        t.id.toLowerCase().contains(q) ||
        t.submitter.toLowerCase().contains(q))
        .toList();
  }

  // ── Stats derived from role-filtered list ─────────────────
  Map<String, int> get _visibleStats {
    final visible = _roleFilteredTickets;

    int countRaw(String norm) => visible.where((t) {
      return t.rawStatus.toLowerCase().replaceAll(' ', '') == norm;
    }).length;

    final forTotal = countRaw('forassessment')
        + countRaw('forendorsement')
        + countRaw('forapproval')
        + countRaw('forassignment');

    return {
      'total':          visible.length,
      'forTotal':       forTotal,
      'forAssessment':  countRaw('forassessment'),
      'forEndorsement': countRaw('forendorsement'),
      'forApproval':    countRaw('forapproval'),
      'forAssignment':  countRaw('forassignment'),
      'inProgress':     visible.where((t) => t.status == TicketStatus.inProgress).length,
      'resolved':       visible.where((t) => t.status == TicketStatus.resolved).length,
    };
  }

  // ── Category counts ───────────────────────────────────────
  Map<String, int> get _visibleCategoryCount {
    final Map<String, int> counts = {};
    for (final t in _roleFilteredTickets) {
      counts[t.categoryName] = (counts[t.categoryName] ?? 0) + 1;
    }
    return counts;
  }

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _searchController.dispose();
    super.dispose();
  }

  // ── Load current user ─────────────────────────────────────
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

      if (mounted) {
        setState(() {
          _currentUsername = username.toLowerCase().trim();
          _currentUserRole = role.toLowerCase().trim();
          _userLoaded      = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _userLoaded = true);
    }

    await _loadTickets();
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.submitted: return AppTheme.accent;
      case ActivityType.moved:     return AppTheme.statusProgress;
      case ActivityType.resolved:  return AppTheme.statusResolved;
      case ActivityType.cancelled: return AppTheme.statusCancelled;
      case ActivityType.assigned:  return const Color(0xFF8B5CF6);
    }
  }

  // ── Load tickets ──────────────────────────────────────────
  Future<void> _loadTickets() async {
    final ticketData = await ApiTicket.getAllTickets();

    final tickets = ticketData.map((e) {
      final rawSt = (e['status'] ?? '').toString().trim();

      final rawPriority = e['priority'];
      int priorityValue;
      if (rawPriority is int) {
        priorityValue = rawPriority;
      } else if (rawPriority is String) {
        priorityValue =
            int.tryParse(rawPriority.replaceAll(RegExp(r'[^0-9]'), '')) ?? 3;
      } else {
        priorityValue = 3;
      }

      final priority = switch (priorityValue) {
        1 => TicketPriority.priority1,
        2 => TicketPriority.priority2,
        3 => TicketPriority.priority3,
        4 => TicketPriority.priority4,
        _ => TicketPriority.priority3,
      };

      return Ticket(
        id:                e['ticket_id'] ?? '',
        title:             e['subject'] ?? '',
        categoryName:      e['category'] ?? 'Uncategorized',
        status:            mapStatus(rawSt),  // enum for logic
        rawStatus:         rawSt,             // real label for display
        priority:          priority,
        submitter:         e['username'] ?? 'Unknown',
        submitterInitials: (e['username'] ?? 'U').substring(0, 1).toUpperCase(),
        createdAt:         DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now(),
        description:       e['description'] ?? '',
      );
    }).toList();

    // ── Activity feed ─────────────────────────────────────
    final activities = <ActivityItem>[];
    for (final t in tickets) {
      activities.add(ActivityItem(
        ticketId:    t.id,
        ticketTitle: t.title,
        actor:       t.submitter,
        message:     '${t.submitter} submitted ${t.id}',
        time:        t.createdAt,
        type:        ActivityType.submitted,
      ));

      if (t.status == TicketStatus.inProgress ||
          t.status == TicketStatus.resolved   ||
          t.status == TicketStatus.cancelled) {
        final actType = t.status == TicketStatus.inProgress
            ? ActivityType.moved
            : t.status == TicketStatus.resolved
            ? ActivityType.resolved
            : ActivityType.cancelled;
        final actionWord = t.status == TicketStatus.inProgress
            ? 'moved to In Progress'
            : t.status == TicketStatus.resolved
            ? 'resolved'
            : 'cancelled';
        activities.add(ActivityItem(
          ticketId:    t.id,
          ticketTitle: t.title,
          actor:       t.submitter,
          message:     '${t.submitter} $actionWord ${t.id}',
          time:        t.createdAt.add(const Duration(hours: 1)),
          type:        actType,
        ));
      }
    }

    activities.sort((a, b) => b.time.compareTo(a.time));

    final Map<String, int> catCount = {};
    for (final t in tickets) {
      catCount[t.categoryName] = (catCount[t.categoryName] ?? 0) + 1;
    }

    if (!mounted) return;
    setState(() {
      _allTickets   ..clear()..addAll(tickets);
      _activities   ..clear()..addAll(activities.take(20));
      _categoryCount..clear()..addAll(catCount);
    });
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

    final filtered  = _filteredTickets;
    final catCounts = _visibleCategoryCount;
    final maxCat    = catCounts.values.isEmpty
        ? 0
        : catCounts.values.reduce((a, b) => a > b ? a : b);

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isPrivileged) _buildUserBanner(),
                    if (!_isPrivileged) const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildMainContent(filtered, catCounts, maxCat),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (_isSidebarOpen || _isCreateOpen)
          GestureDetector(
            onTap: () => setState(() {
              _isSidebarOpen = false;
              _isCreateOpen  = false;
            }),
            child: Container(color: Colors.black54),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0, bottom: 0,
          right: _isSidebarOpen ? 0 : -1250,
          child: TicketSidebar(
            ticket: _selectedTicket,
            onClose: _closeSidebar,
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0, bottom: 0,
          right: _isCreateOpen ? 0 : -1250,
          child: CreateTicketSidebar(
            onClose: () => setState(() => _isCreateOpen = false),
            onCreated: () {
              _loadTickets();
              setState(() => _isCreateOpen = false);
            },
          ),
        ),
      ],
    );
  }

  // ── User-mode banner ─────────────────────────────────────
  Widget _buildUserBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(Icons.person_outline, size: 15, color: AppTheme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              children: [
                const TextSpan(text: 'Viewing as '),
                TextSpan(
                  text: _currentUsername,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' — you can only see tickets you submitted.'),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          Widget content = Row(
            mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

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

              // Search box
              if (isNarrow)
                SizedBox(
                  width: 260,
                  height: 36,
                  child: _buildSearchBox(),
                )
              else
                Expanded(
                  child: _buildSearchBox(),
                ),

              const SizedBox(width: 16),

              CompositedTransformTarget(
                link: _notificationLink,
                child: Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppTheme.textSecondary),
                    onPressed: _toggleNotificationPanel,
                    tooltip: 'Recent Activity',
                  ),
                  if (_hasNewActivity)
                    const Positioned(
                      right: 8, top: 8,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: AppTheme.statusCancelled,
                      ),
                    ),
                ]),
              ),

              if (_isPrivileged)
                IconButton(
                  icon: _isExporting
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textSecondary))
                      : const Icon(Icons.download_outlined,
                      color: AppTheme.textSecondary),
                  tooltip: 'Export tickets to Excel',
                  onPressed: _isExporting ? null : _handleExport,
                ),

              const SizedBox(width: 8),

              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _isSidebarOpen = false;
                  _isCreateOpen  = true;
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }

// Extract search box into its own method
  Widget _buildSearchBox() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.search, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Search tickets, users...',
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          GestureDetector(
            onTap: () => _searchController.clear(),
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.close,
                  size: 14, color: AppTheme.textSecondary),
            ),
          ),
      ]),
    );
  }

  // ── Export handler ────────────────────────────────────────
  Future<void> _handleExport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Export Tickets',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Download all tickets as an Excel file?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isExporting = true);
    try {
      await ApiExport.downloadTicketsExcel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Export completed successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
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

  // ── Role accent color ─────────────────────────────────────
  Color get _roleColor {
    switch (_currentUserRole.toLowerCase().trim()) {
      case 'admin':    return Colors.black;
      case 'endorser': return Colors.black;
      case 'approver': return Colors.black;
      case 'resolver': return Colors.black;
      default:         return Colors.black;
    }
  }

  // ── Stats row — keeps original 4-card layout ──────────────
  Widget _buildStatsRow() {
    final s = _visibleStats;
    return Row(children: [
      Expanded(child: StatsCard(
        title: 'Total Tickets',
        count: s['total'] ?? 0,
        subtitle: _isPrivileged ? 'All time records' : 'Your tickets',
        accentColor: AppTheme.accent,
      )),
      const SizedBox(width: 16),
      Expanded(child: StatsCard(
        title: 'For Review',
        count: s['forTotal'] ?? 0,
        subtitle: 'status',
        accentColor: AppTheme.statusAssessment,
      )),
      const SizedBox(width: 16),
      Expanded(child: StatsCard(
        title: 'In Progress',
        count: s['inProgress'] ?? 0,
        subtitle: 'being worked on',
        accentColor: AppTheme.statusProgress,
      )),
      const SizedBox(width: 16),
      Expanded(child: StatsCard(
        title: 'Resolved',
        count: s['resolved'] ?? 0,
        subtitle: 'completed',
        accentColor: AppTheme.statusResolved,
      )),
    ]);
  }

  // ── Main content ──────────────────────────────────────────
  Widget _buildMainContent(
      List<Ticket> tickets,
      Map<String, int> catCounts,
      int maxCat,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTicketsTable(tickets)),
        const SizedBox(width: 20),
        SizedBox(
          width: 260,
          child: Column(children: [
            _buildCategoryPanel(catCounts, maxCat),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ]),
        ),
      ],
    );
  }

  // ── Tickets table ─────────────────────────────────────────
  Widget _buildTicketsTable(List<Ticket> tickets) {
    final visible = tickets.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketsHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(children: const [
              Expanded(flex: 4, child: _TableHeader('TICKET')),
              Expanded(flex: 2, child: _TableHeader('STATUS')),
              SizedBox(width: 12),
              Expanded(flex: 2, child: _TableHeader('PRIORITY')),
              SizedBox(width: 12),
              Expanded(flex: 2, child: _TableHeader('SUBMITTER')),
            ]),
          ),
          visible.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_outlined, size: 36, color: AppTheme.textMuted),
                const SizedBox(height: 10),
                Text(
                  _isPrivileged
                      ? 'No tickets found'
                      : 'You have not submitted any tickets yet.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          )
              : SizedBox(
            height: 300, // adjust height as needed
            child: SingleChildScrollView(
              child: Column(
                children: visible.map<Widget>((t) {
                  return GestureDetector(
                    onTap: () => _openTicket(t),
                    child: TicketRow(ticket: t),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tickets header ────────────────────────────────────────
  Widget _buildTicketsHeader() {
    final total   = _roleFilteredTickets.length;
    final showing = _filteredTickets.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        const Text(
          'Recent Tickets',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Text(
          _searchQuery.isNotEmpty || _selectedFilter != 'All'
              ? '$showing of $total'
              : '$total total',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const Spacer(),
        // ── Scrollable filter pills ───────────────────────
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              dropdownColor: AppTheme.surface,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: AppTheme.textSecondary),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
              ),
              items: _filters.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFilter = value);
                }
              },
            ),
          ),
        ),


      ]),
    );
  }

  // ── Category panel ────────────────────────────────────────
  Widget _buildCategoryPanel(Map<String, int> counts, int maxCat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By Category',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (counts.isEmpty)
            const Text('No data',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12))
          else
            ...counts.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryBar(
                  e.key, e.value, maxCat, _getCategoryColor(e.key)),
            )),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('network'))     return AppTheme.catNetwork;
    if (c.contains('software'))    return AppTheme.catSoftware;
    if (c.contains('storage'))     return AppTheme.catStorage;
    if (c.contains('database'))    return AppTheme.catDatabase;
    if (c.contains('endpoint'))    return AppTheme.catEndpoint;
    if (c.contains('server'))      return AppTheme.catStorage;
    if (c.contains('application')) return AppTheme.catApplications;
    return AppTheme.accent;
  }

  // ── Recent activity ───────────────────────────────────────
  Widget _buildRecentActivity() {
    final items = _isPrivileged
        ? _activities
        : _activities
        .where((a) =>
    a.actor.toLowerCase().trim() ==
        _currentUsername.toLowerCase().trim())
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Text('${items.length}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          items.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No recent activity',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
          )
              : Column(
            children: items
                .take(4)
                .map((item) => _ActivityTile(
                item: item, color: _activityColor(item.type)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets — unchanged from original
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationDropdown extends StatelessWidget {
  final List<ActivityItem> activities;
  final Color Function(ActivityType) getColor;
  final String Function(ActivityType) getLabel;

  const _NotificationDropdown({
    required this.activities,
    required this.getColor,
    required this.getLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: activities.isEmpty
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('No recent activity',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Recent Activity',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          ...activities.take(10).map((item) {
            final color = getColor(item.type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            children: [
                              TextSpan(
                                  text: item.actor,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(text: ' ${getLabel(item.type)}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.ticketId} · ${item.ticketTitle}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(item.timeAgo,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  const _TableHeader(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color color;
  const _CategoryBar(this.label, this.count, this.max, this.color);

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : count / max;
    return Row(children: [
      SizedBox(
        width: 90,
        child: Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Stack(children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2))),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 20,
        child: Text(count.toString(),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.right),
      ),
    ]);
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final Color color;
  const _ActivityTile({required this.item, required this.color});

  String get _actionLabel {
    switch (item.type) {
      case ActivityType.submitted: return 'submitted';
      case ActivityType.moved:     return 'moved to In Progress';
      case ActivityType.resolved:  return 'resolved';
      case ActivityType.cancelled: return 'cancelled';
      case ActivityType.assigned:  return 'assigned';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    children: [
                      TextSpan(
                          text: item.actor,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' $_actionLabel'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('${item.ticketId} · ${item.ticketTitle}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.timeAgo,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}