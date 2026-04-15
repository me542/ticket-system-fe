import 'package:flutter/material.dart';
import '../core/services/api_file.dart';
import '../core/services/api_export.dart';
import '../data/app_theme.dart';
import '../models/ticket.dart';
import '../widgets/file_ticket.dart';
import '../widgets/stats_card.dart';
import 'package:ticket_system/widgets/ticket_row.dart';
import '../widgets/status_sidebar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── Sidebar ──────────────────────────────────────────────
  Ticket? _selectedTicket;
  bool _isSidebarOpen = false;

  void _openTicket(Ticket ticket) {
    setState(() {
      _selectedTicket = ticket;
      _isSidebarOpen = true;
    });
  }

  void _closeSidebar() {
    setState(() {
      _isSidebarOpen = false;
    });
  }

  // ── Filter & Search ──────────────────────────────────────
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For', 'In', 'Resolved', 'Cancelled'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isExporting = false;

  // ── Data ─────────────────────────────────────────────────
  final List<Ticket> _tickets = [];
  final List<ActivityItem> _activities = [];

  final Map<TicketCategory, int> _categoryCount = {
    for (var cat in TicketCategory.values) cat: 0,
  };

  Map<String, int> _statsCounts = {
    'total': 0,
    'forAssessment': 0,
    'inProgress': 0,
    'resolved': 0,
  };

  // ── Computed filtered list ────────────────────────────────
  List<Ticket> get _filteredTickets {
    List<Ticket> list;
    switch (_selectedFilter) {
      case 'For':
        list = _tickets
            .where((t) => t.status == TicketStatus.forAssessment)
            .toList();
        break;
      case 'In':
        list = _tickets
            .where((t) => t.status == TicketStatus.inProgress)
            .toList();
        break;
      case 'Resolved':
        list =
            _tickets.where((t) => t.status == TicketStatus.resolved).toList();
        break;
      case 'Cancelled':
        list =
            _tickets.where((t) => t.status == TicketStatus.cancelled).toList();
        break;
      default:
        list = List.from(_tickets);
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

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadTickets();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.submitted:
        return AppTheme.accent;
      case ActivityType.moved:
        return AppTheme.statusProgress;
      case ActivityType.resolved:
        return AppTheme.statusResolved;
      case ActivityType.cancelled:
        return AppTheme.statusCancelled;
      case ActivityType.assigned:
        return const Color(0xFF8B5CF6);
    }
  }

  // ── Load tickets ──────────────────────────────────────────
  Future<void> _loadTickets() async {
    final ticketData = await ApiTicket.getAllTickets();

    final tickets = ticketData.map((e) {
      // Status mapping
      TicketStatus status;
      switch ((e['status'] ?? '').toLowerCase()) {
        case 'forassessment':
        case 'for assessment':
          status = TicketStatus.forAssessment;
          break;
        case 'inprogress':
        case 'in progress':
          status = TicketStatus.inProgress;
          break;
        case 'resolved':
          status = TicketStatus.resolved;
          break;
        case 'cancelled':
          status = TicketStatus.cancelled;
          break;
        default:
          status = TicketStatus.forAssessment;
      }

      // Category mapping
      TicketCategory category = mapCategory(e['category'] ?? '');

      // Priority mapping
      TicketPriority priority;
      switch (e['priority'] ?? 0) {
        case 1:
          priority = TicketPriority.priority1;
          break;
        case 2:
          priority = TicketPriority.priority2;
          break;
        case 3:
          priority = TicketPriority.priority3;
          break;
        default:
          priority = TicketPriority.priority3;
      }

      return Ticket(
        id: e['ticket_id'] ?? '',
        title: e['subject'] ?? '',
        category: category,
        status: status,
        priority: priority,
        submitter: e['username'] ?? 'Unknown',
        submitterInitials:
        (e['username'] ?? 'U').substring(0, 1).toUpperCase(),
        createdAt: DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now(),
        description: e['description'] ?? '',
      );
    }).toList();

    // ── Derive activity items from tickets ──────────────────
    final activities = <ActivityItem>[];

    for (final t in tickets) {
      // Submitted event for every ticket
      activities.add(ActivityItem(
        ticketId: t.id,
        ticketTitle: t.title,
        actor: t.submitter,
        message: '${t.submitter} submitted ${t.id}',
        time: t.createdAt,
        type: ActivityType.submitted,
      ));

      // Status-based follow-up event
      if (t.status == TicketStatus.inProgress ||
          t.status == TicketStatus.resolved ||
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
          ticketId: t.id,
          ticketTitle: t.title,
          actor: t.submitter,
          message: '${t.submitter} $actionWord ${t.id}',
          time: t.createdAt.add(const Duration(hours: 1)),
          type: actType,
        ));
      }
    }

    // Sort newest first, keep top 20
    activities.sort((a, b) => b.time.compareTo(a.time));
    final recentActivities = activities.take(20).toList();

    // Compute stats
    final total = tickets.length;
    final forAssessment =
        tickets.where((t) => t.status == TicketStatus.forAssessment).length;
    final inProgress =
        tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolved =
        tickets.where((t) => t.status == TicketStatus.resolved).length;

    // Compute category counts
    final Map<TicketCategory, int> categoryCount = {};
    for (var cat in TicketCategory.values) {
      categoryCount[cat] = tickets.where((t) => t.category == cat).length;
    }

    setState(() {
      _tickets
        ..clear()
        ..addAll(tickets);
      _activities
        ..clear()
        ..addAll(recentActivities);
      _categoryCount
        ..clear()
        ..addAll(categoryCount);
      _statsCounts = {
        'total': total,
        'forAssessment': forAssessment,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTickets;
    final maxCat = _categoryCount.values.isEmpty
        ? 0
        : _categoryCount.values.reduce((a, b) => a > b ? a : b);

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
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildMainContent(filtered, maxCat),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Dark overlay
        if (_isSidebarOpen)
          GestureDetector(
            onTap: _closeSidebar,
            child: Container(color: Colors.black54),
          ),

        // Right sidebar
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
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),

          // ── Search bar ───────────────────────────────────
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
                        hintText: 'Search tickets, users...',
                        hintStyle: TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
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
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.textSecondary),
                onPressed: () {},
              ),
              const Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: AppTheme.statusCancelled,
                ),
              ),
            ],
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.textSecondary),
            )
                : const Icon(Icons.download_outlined,
                color: AppTheme.textSecondary),
            tooltip: 'Export tickets to Excel',
            onPressed: _isExporting
                ? null
                : () async {
              setState(() => _isExporting = true);
              try {
                await ApiExport.downloadTicketsExcel();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isExporting = false);
              }
            },
          ),
          const SizedBox(width: 8),

          // ── New Ticket button ────────────────────────────
          ElevatedButton.icon(
            onPressed: () async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const CreateTicketDialog(),
              );
              _loadTickets();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        StatsCard(
          title: 'Total Tickets',
          count: _statsCounts['total'] ?? 0,
          subtitle: 'All time records',
          accentColor: AppTheme.accent,
        ),
        const SizedBox(width: 16),
        StatsCard(
          title: 'For Assessment',
          count: _statsCounts['forAssessment'] ?? 0,
          subtitle: 'awaiting review',
          accentColor: AppTheme.statusAssessment,
        ),
        const SizedBox(width: 16),
        StatsCard(
          title: 'In Progress',
          count: _statsCounts['inProgress'] ?? 0,
          subtitle: 'being worked',
          accentColor: AppTheme.statusProgress,
        ),
        const SizedBox(width: 16),
        StatsCard(
          title: 'Resolved',
          count: _statsCounts['resolved'] ?? 0,
          subtitle: 'completed',
          accentColor: AppTheme.statusResolved,
        ),
      ],
    );
  }

  // ── Main content ──────────────────────────────────────────
  Widget _buildMainContent(List<Ticket> tickets, int maxCat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTicketsTable(tickets)),
        const SizedBox(width: 20),
        SizedBox(
          width: 260,
          child: Column(
            children: [
              _buildCategoryPanel(maxCat),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tickets table ─────────────────────────────────────────
  Widget _buildTicketsTable(List<Ticket> tickets) {
    final recentTickets = tickets.take(8).toList();

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
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TableHeader('TICKET')),
                Expanded(flex: 2, child: _TableHeader('STATUS')),
                SizedBox(width: 12),
                Expanded(flex: 2, child: _TableHeader('PRIORITY')),
                SizedBox(width: 12),
                Expanded(flex: 2, child: _TableHeader('SUBMITTER')),
              ],
            ),
          ),
          if (recentTickets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No tickets found',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            Column(
              children: recentTickets.take(6).map<Widget>((t) {
                return GestureDetector(
                  onTap: () => _openTicket(t),
                  child: TicketRow(ticket: t),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ── Tickets header with filter buttons ────────────────────
  Widget _buildTicketsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text('Recent Tickets',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? '${_filteredTickets.length} of ${_tickets.length}'
                : '${_tickets.length} total',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: _filters.map((f) {
              final isSelected = _selectedFilter == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
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
                        color:
                        isSelected ? AppTheme.accent : AppTheme.border),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Category panel ────────────────────────────────────────
  Widget _buildCategoryPanel(int maxCat) {
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
          ...TicketCategory.values.map((cat) {
            final count = _categoryCount[cat] ?? 0;
            Color color;
            switch (cat) {
              case TicketCategory.customerPremise:
                color = AppTheme.catCustomer;
                break;
              case TicketCategory.softwareInstallation:
                color = AppTheme.catSoftware;
                break;
              case TicketCategory.storageServer:
                color = AppTheme.catStorage;
                break;
              case TicketCategory.networkConnection:
                color = AppTheme.catNetwork;
                break;
              case TicketCategory.databaseUserAccounts:
                color = AppTheme.catDatabase;
                break;
              case TicketCategory.applicationsAmazon:
                color = AppTheme.catApplications;
                break;
              case TicketCategory.endpointDesktop:
                color = AppTheme.catEndpoint;
                break;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryBar(catLabel(cat), count, maxCat, color),
            );
          }).toList(),
        ],
      ),
    );
  }

  String catLabel(TicketCategory cat) {
    switch (cat) {
      case TicketCategory.customerPremise:
        return 'Customer Prem.';
      case TicketCategory.softwareInstallation:
        return 'Software';
      case TicketCategory.storageServer:
        return 'Storage';
      case TicketCategory.networkConnection:
        return 'Network';
      case TicketCategory.databaseUserAccounts:
        return 'Database';
      case TicketCategory.applicationsAmazon:
        return 'Applications';
      case TicketCategory.endpointDesktop:
        return 'Endpoint';
    }
  }

  // ── Recent activity ───────────────────────────────────────
  Widget _buildRecentActivity() {
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
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_activities.isNotEmpty)
                Text(
                  '${_activities.length}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...(_activities.take(4).map((item) => _ActivityTile(
              item: item,
              color: _activityColor(item.type),
            ))),
        ],
      ),
    );
  }
}

// ── Table header cell ─────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final String label;
  const _TableHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Category progress bar ─────────────────────────────────────
class _CategoryBar extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color color;

  const _CategoryBar(this.label, this.count, this.max, this.color);

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : count / max;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
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
                        color: color,
                        borderRadius: BorderRadius.circular(2))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(count.toString(),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

// ── Activity tile ─────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final Color color;

  const _ActivityTile({required this.item, required this.color});

  String get _actionLabel {
    switch (item.type) {
      case ActivityType.submitted:
        return 'submitted';
      case ActivityType.moved:
        return 'moved to In Progress';
      case ActivityType.resolved:
        return 'resolved';
      case ActivityType.cancelled:
        return 'cancelled';
      case ActivityType.assigned:
        return 'assigned';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actor + action
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: item.actor,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' $_actionLabel'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Ticket ID + title
                Text(
                  '${item.ticketId} · ${item.ticketTitle}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Time ago
                Text(
                  item.timeAgo,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}