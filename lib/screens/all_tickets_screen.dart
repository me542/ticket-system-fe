import 'package:flutter/material.dart';
import '../core/services/api_file.dart';
import '../models/ticket.dart';
import '../widgets/ticket_row.dart';
import '../data/app_theme.dart';

class AllTicketsScreen extends StatefulWidget {
  const AllTicketsScreen({super.key});

  @override
  State<AllTicketsScreen> createState() => _AllTicketsScreenState();
}

class _AllTicketsScreenState extends State<AllTicketsScreen> {
  String _search = '';
  bool _loading = true;
  List<Ticket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _fetchAllTickets();
  }

  Future<void> _fetchAllTickets() async {
    setState(() => _loading = true);
    try {
      final data = await ApiTicket.getAllTickets();
      print('Raw API tickets: $data');

      _tickets = data.map<Ticket>((item) {
        final username = item['username'] ?? 'Unknown';
        final createdAt = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

        return Ticket(
          id: item['ticket_id'] ?? '',
          title: item['subject'] ?? '',
          category: _mapCategory(item['category'] ?? ''),
          status: _mapStatus(item['status'] ?? ''),
          priority: _mapPriority(item['priority']),
          submitter: username,
          submitterInitials: username.isNotEmpty ? username[0] : '?',
          createdAt: createdAt,
        );
      }).toList();

      print('Mapped tickets: $_tickets');
    } catch (e) {
      print('Error fetching tickets: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ✅ Map API status to enum
  TicketStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'forassessment':
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

  // ✅ Map API priority to enum
  TicketPriority _mapPriority(dynamic p) {
    final prio = int.tryParse(p.toString()) ?? 1;
    switch (prio) {
      case 1:
        return TicketPriority.priority1;
      case 2:
        return TicketPriority.priority2;
      case 3:
        return TicketPriority.priority3;
      default:
        return TicketPriority.priority1;
    }
  }

  // ✅ Map API category to enum
  TicketCategory _mapCategory(String cat) {
    final c = cat.toLowerCase().trim();
    if (c.contains('customer premise')) return TicketCategory.customerPremise;
    if (c.contains('software')) return TicketCategory.softwareInstallation;
    if (c.contains('storage')) return TicketCategory.storageServer;
    if (c.contains('network')) return TicketCategory.networkConnection;
    if (c.contains('database')) return TicketCategory.databaseUserAccounts;
    if (c.contains('applications')) return TicketCategory.applicationsAmazon;
    if (c.contains('endpoint')) return TicketCategory.endpointDesktop;

    print('Unknown category: $cat');
    return TicketCategory.customerPremise; // fallback
  }




  @override
  Widget build(BuildContext context) {
    final filteredTickets = _tickets.where((t) {
      return _search.isEmpty ||
          t.title.toLowerCase().contains(_search.toLowerCase()) ||
          t.id.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Header with search
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
                'All Tickets',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search tickets...',
                            hintStyle: TextStyle(color: AppTheme.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tickets table
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: const [
                        Expanded(flex: 4, child: _Header('TICKET')),
                        Expanded(flex: 2, child: _Header('STATUS')),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: _Header('PRIORITY')),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: _Header('SUBMITTER')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredTickets.isEmpty
                        ? const Center(child: Text('No tickets found'))
                        : ListView.builder(
                      itemCount: filteredTickets.length,
                      itemBuilder: (_, i) =>
                          TicketRow(ticket: filteredTickets[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  const _Header(this.label);

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




