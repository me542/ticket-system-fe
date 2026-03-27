import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/ticket_provider.dart';
import '../data/app_theme.dart';
import '../models/ticket.dart';
import '../widgets/file_ticket.dart';
import '../widgets/stats_card.dart';
import '../widgets/ticket_row.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'For', 'In', 'Resolved'];

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final filteredTickets = provider.filterTickets(_selectedFilter);
    final categoryCount = provider.categoryCount;
    final maxCat = categoryCount.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        // Top bar
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
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusCancelled,
                        shape: BoxShape.circle,
                      ),
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
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const CreateTicketDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards row
                Row(
                  children: [
                    StatsCard(
                      title: 'Total Tickets',
                      count: provider.totalTickets,
                      subtitle: 'All time records',
                      accentColor: AppTheme.accent,
                    ),
                    const SizedBox(width: 16),
                    StatsCard(
                      title: 'For Assessment',
                      count: provider.forAssessmentCount,
                      subtitle: 'awaiting review',
                      accentColor: AppTheme.statusAssessment,
                    ),
                    const SizedBox(width: 16),
                    StatsCard(
                      title: 'In Progress',
                      count: provider.inProgressCount,
                      subtitle: 'being worked',
                      accentColor: AppTheme.statusProgress,
                    ),
                    const SizedBox(width: 16),
                    StatsCard(
                      title: 'Resolved',
                      count: provider.resolvedCount,
                      subtitle: 'completed',
                      accentColor: AppTheme.statusResolved,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Main content row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Tickets table
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Row(
                                children: [
                                  const Text(
                                    'Recent Tickets',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${provider.totalTickets} total',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  // Filter buttons
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
                                            border: Border.all(
                                              color: isSelected ? AppTheme.accent : AppTheme.border,
                                            ),
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
                            ),

                            // Table header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Row(
                                children: const [
                                  Expanded(flex: 4, child: _TableHeader('TICKET')),
                                  Expanded(flex: 2, child: _TableHeader('STATUS')),
                                  SizedBox(width: 12),
                                  Expanded(flex: 2, child: _TableHeader('PRIORITY')),
                                  SizedBox(width: 12),
                                  Expanded(flex: 2, child: _TableHeader('ASSIGNEE')),
                                ],
                              ),
                            ),

                            // Ticket rows
                            ...filteredTickets
                                .take(8)
                                .map((t) => TicketRow(ticket: t)),

                            if (filteredTickets.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    'No tickets found',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Right panel
                    SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          // By Category
                          Container(
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
                                _CategoryBar('Customer Prem.', categoryCount[TicketCategory.customerPremise] ?? 0, maxCat, AppTheme.catCustomer),
                                const SizedBox(height: 10),
                                _CategoryBar('Software', categoryCount[TicketCategory.software] ?? 0, maxCat, AppTheme.catSoftware),
                                const SizedBox(height: 10),
                                _CategoryBar('Storage', categoryCount[TicketCategory.storage] ?? 0, maxCat, AppTheme.catStorage),
                                const SizedBox(height: 10),
                                _CategoryBar('Network', categoryCount[TicketCategory.network] ?? 0, maxCat, AppTheme.catNetwork),
                                const SizedBox(height: 10),
                                _CategoryBar('Applications', categoryCount[TicketCategory.applications] ?? 0, maxCat, AppTheme.catApplications),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Recent Activity
                          Container(
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
                                  'Recent Activity',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ...provider.activities.map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: _activityColor(a.type),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '${a.ticketId} ',
                                                    style: const TextStyle(
                                                      color: AppTheme.accent,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: a.message,
                                                    style: const TextStyle(
                                                      color: AppTheme.textPrimary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              a.timeAgo,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            count.toString(),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
