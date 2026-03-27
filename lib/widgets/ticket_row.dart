import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../data/app_theme.dart';

class TicketRow extends StatelessWidget {
  final Ticket ticket;

  const TicketRow({super.key, required this.ticket});

  Color get _statusColor {
    switch (ticket.status) {
      case TicketStatus.forAssessment:
        return AppTheme.statusAssessment;
      case TicketStatus.inProgress:
        return AppTheme.statusProgress;
      case TicketStatus.resolved:
        return AppTheme.statusResolved;
      case TicketStatus.cancelled:
        return AppTheme.statusCancelled;
    }
  }

  Color get _priorityColor {
    switch (ticket.priority) {
      case TicketPriority.priority1:
        return AppTheme.priority1;
      case TicketPriority.priority2:
        return AppTheme.priority2;
      case TicketPriority.priority3:
        return AppTheme.priority3;
    }
  }

  Color get _assigneeColor {
    if (ticket.assigneeInitials == 'S') return AppTheme.accent;
    if (ticket.assigneeInitials == 'JV') return const Color(0xFF059669);
    if (ticket.assigneeInitials == 'JB') return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Ticket ID + Title
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.id,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${ticket.categoryLabel} · ${ticket.timeAgo}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _statusColor.withOpacity(0.4), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Priority
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _priorityColor.withOpacity(0.4), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.priorityLabel,
                    style: TextStyle(
                      color: _priorityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Assignee
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _assigneeColor,
                  child: Text(
                    ticket.assigneeInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ticket.assignee,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
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
