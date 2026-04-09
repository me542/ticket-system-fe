enum TicketStatus { forAssessment, inProgress, resolved, cancelled }
enum TicketPriority { priority1, priority2, priority3 }

/// Updated TicketCategory to include all IT-related categories
enum TicketCategory {
  customerPremise,        // IT Related - Customer Premise E.
  softwareInstallation,   // IT Related - Software - Installation
  storageServer,          // IT Related - Storage - Server
  networkConnection,      // IT Related - Network - Connection
  databaseUserAccounts,   // IT Related - Database - User Accounts
  applicationsAmazon,     // IT Related - Applications - Amazon
  endpointDesktop         // IT Related - Endpoint - Desktop
}


class Ticket {
  final String id;
  final String title;
  final TicketCategory category;
  final TicketStatus status;
  final TicketPriority priority;
  final String submitter;
  final String submitterInitials;
  final DateTime createdAt;
  final String description;

  const Ticket({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.priority,
    required this.submitter,
    required this.submitterInitials,
    required this.createdAt,
    required this.description,
  });

  /// Human-readable labels for category
  String get categoryLabel {
    switch (category) {
      case TicketCategory.customerPremise:
        return 'IT Related - Customer Premise E.';
      case TicketCategory.softwareInstallation:
        return 'IT Related - Software - Installation';
      case TicketCategory.storageServer:
        return 'IT Related - Storage - Server';
      case TicketCategory.networkConnection:
        return 'IT Related - Network - Connection';
      case TicketCategory.databaseUserAccounts:
        return 'IT Related - Database - User Accounts';
      case TicketCategory.applicationsAmazon:
        return 'IT Related - Applications - Amazon';
      case TicketCategory.endpointDesktop:
        return 'IT Related - Endpoint - Desktop';
    }
  }


  /// Human-readable labels for status
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

  /// Human-readable labels for priority
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

  /// Show relative time

}

/// Activity items for ticket timeline
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

/// Helper function to map API category string to enum
TicketCategory mapCategory(String cat) {
  final c = cat.toLowerCase();
  if (c.contains('customer premise')) return TicketCategory.customerPremise;
  if (c.contains('software')) return TicketCategory.softwareInstallation;
  if (c.contains('storage')) return TicketCategory.storageServer;
  if (c.contains('network')) return TicketCategory.networkConnection;
  if (c.contains('database')) return TicketCategory.databaseUserAccounts;
  if (c.contains('applications')) return TicketCategory.applicationsAmazon;
  if (c.contains('endpoint')) return TicketCategory.endpointDesktop;

  return TicketCategory.customerPremise;
}





