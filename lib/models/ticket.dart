enum TicketStatus { forAssessment, inProgress, resolved, cancelled }
enum TicketPriority { priority1, priority2, priority3 }
enum TicketCategory { customerPremise, software, storage, network, applications }

class Ticket {
  final String id;
  final String title;
  final TicketCategory category;
  final TicketStatus status;
  final TicketPriority priority;
  final String assignee;
  final String assigneeInitials;
  final DateTime createdAt;

  const Ticket({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.priority,
    required this.assignee,
    required this.assigneeInitials,
    required this.createdAt,
  });

  String get categoryLabel {
    switch (category) {
      case TicketCategory.customerPremise:
        return 'Customer Premise E.';
      case TicketCategory.software:
        return 'Software';
      case TicketCategory.storage:
        return 'Storage';
      case TicketCategory.network:
        return 'Network';
      case TicketCategory.applications:
        return 'Applications';
    }
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.forAssessment:
        return 'For Assessment';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.priority1:
        return 'Priority 1';
      case TicketPriority.priority2:
        return 'Priority 2';
      case TicketPriority.priority3:
        return 'Priority 3';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class ActivityItem {
  final String ticketId;
  final String message;
  final DateTime time;
  final ActivityType type;

  const ActivityItem({
    required this.ticketId,
    required this.message,
    required this.time,
    required this.type,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes} min ago';
  }
}

enum ActivityType { submitted, moved, resolved, cancelled, assigned }
