import 'package:flutter/material.dart';
import '../core/services/api_file.dart';
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

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For', 'In', 'Resolved'];

  final List<Ticket> _tickets = [];
  final List<ActivityItem> _activities = [];

  /// Initialize category count for all updated TicketCategory values
  final Map<TicketCategory, int> _categoryCount = {
    for (var cat in TicketCategory.values) cat: 0,
  };

  Map<String, int> _statsCounts = {
    'total': 0,
    'forAssessment': 0,
    'inProgress': 0,
    'resolved': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

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

  Future<void> _loadTickets() async {
    final ticketData = await ApiTicket.getAllTickets();

    final tickets = ticketData.map((e) {
      // --- Status mapping ---
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

      // --- Category mapping using updated enum ---
      TicketCategory category = mapCategory(e['category'] ?? '');

      // --- Priority mapping ---
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
        submitterInitials: (e['username'] ?? 'U').substring(0, 1).toUpperCase(),
        createdAt: DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();

    // Compute stats
    final total = tickets.length;
    final forAssessment = tickets.where((t) => t.status == TicketStatus.forAssessment).length;
    final inProgress = tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolved = tickets.where((t) => t.status == TicketStatus.resolved).length;

    // Compute categories count dynamically
    final Map<TicketCategory, int> categoryCount = {};
    for (var cat in TicketCategory.values) {
      categoryCount[cat] = tickets.where((t) => t.category == cat).length;
    }

    setState(() {
      _tickets.clear();
      _tickets.addAll(tickets);
      _categoryCount.clear();
      _categoryCount.addAll(categoryCount);
      _statsCounts = {
        'total': total,
        'forAssessment': forAssessment,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = _tickets;
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
                    _buildMainContent(filteredTickets, maxCat),
                  ],
                ),
              ),
            ),
          ],
        ),

        /// 🔥 DARK OVERLAY
        if (_isSidebarOpen)
          GestureDetector(
            onTap: _closeSidebar,
            child: Container(color: Colors.black54),
          ),

        /// 🔥 RIGHT SIDEBAR
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: _isSidebarOpen ? 0 : -520,
          child: TicketSidebar(
            ticket: _selectedTicket,
            onClose: _closeSidebar,
          ),
        ),
      ],
    );
  }

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
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, size: 16, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Search tickets, users...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
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
            icon: const Icon(Icons.download_outlined, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const CreateTicketDialog(),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

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
                child: Text('No tickets found', style: TextStyle(color: AppTheme.textSecondary)),
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
            )
        ],
      ),
    );
  }



  Widget _buildTicketsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text('Recent Tickets', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('${_tickets.length} total', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const Spacer(),
          Row(
            children: _filters.map((f) {
              final isSelected = _selectedFilter == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  /// --- Updated Category Panel dynamically from TicketCategory enum ---
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
            final label = cat.toString().split('.').last; // temporary, can use categoryLabel helper if needed
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
              child: _CategoryBar(
                catLabel(cat),
                count,
                maxCat,
                color,
              ),
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

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Center(child: Text('No recent activity', style: TextStyle(color: AppTheme.textSecondary))),
    );
  }
}

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
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(count.toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
