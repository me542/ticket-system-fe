import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/ticket_provider.dart';
import '../data/app_theme.dart';
import '../widgets/ticket_row.dart';

class AllTicketsScreen extends StatefulWidget {
  const AllTicketsScreen({super.key});

  @override
  State<AllTicketsScreen> createState() => _AllTicketsScreenState();
}

class _AllTicketsScreenState extends State<AllTicketsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final tickets = provider.allTickets
        .where((t) =>
            _search.isEmpty ||
            t.title.toLowerCase().contains(_search.toLowerCase()) ||
            t.id.toLowerCase().contains(_search.toLowerCase()))
        .toList();

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
                      const Icon(Icons.search, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
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
                        Expanded(flex: 2, child: _Header('ASSIGNEE')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (_, i) => TicketRow(ticket: tickets[i]),
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
