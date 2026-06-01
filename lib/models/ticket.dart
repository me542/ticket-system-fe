enum TicketStatus { forAssessment, inProgress, resolved, cancelled, closed }
enum TicketPriority { priority1, priority2, priority3, priority4 }

class Ticket {
  final String id;
  final String title;
  final String categoryName;
  final String subcategoryName;

  final TicketStatus status;

  /// The exact status string from the API, e.g. "For Endorsement", "For Approval".
  /// Use this for display — never rely on [statusLabel] when you need the real sub-status.
  final String rawStatus;

  final TicketPriority priority;
  final String submitter;
  final String submitterInitials;
  final DateTime createdAt;
  final String description;
  final String resolver;

  const Ticket({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.subcategoryName,
    required this.status,
    required this.rawStatus,
    required this.priority,
    required this.submitter,
    required this.submitterInitials,
    required this.createdAt,
    required this.description,
    required this.resolver,
  });

  String get categoryLabel => categoryName;

  /// Returns the real status label:
  /// - For "For X" tickets → shows the exact API string (e.g. "For Endorsement")
  /// - For other statuses  → falls back to the enum label
  String get statusLabel {
    final raw = rawStatus.trim();
    if (raw.isNotEmpty) return raw;
    switch (status) {
      case TicketStatus.forAssessment: return 'For Assessment';
      case TicketStatus.inProgress:   return 'In Progress';
      case TicketStatus.resolved:     return 'Resolved';
      case TicketStatus.cancelled:    return 'Cancelled';
      case TicketStatus.closed:       return 'Closed';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.priority1: return 'Priority 1';
      case TicketPriority.priority2: return 'Priority 2';
      case TicketPriority.priority3: return 'Priority 3';
      case TicketPriority.priority4: return 'Priority 4';
    }
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final rawSt = (json['status'] ?? '').toString().trim();
    return Ticket(
      id:                json['id'].toString(),
      title:             json['title'] ?? '',
      categoryName:      json['category'] ?? '',
      subcategoryName:      json['subcategory'] ?? '',
      status:            mapStatus(rawSt),
      rawStatus:         rawSt,
      priority:          mapPriority((json['priority'] ?? '').toString()),
      submitter:         json['submitter'] ?? '',
      submitterInitials: json['submitterInitials'] ?? '',
      createdAt:         DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      description:       json['description'] ?? '',
      resolver:          json['resolver'] ?? '',
    );
  }
}

class ActivityItem {
  final String ticketId;
  final String ticketTitle;
  final String actor;
  final String message;
  final DateTime time;
  final ActivityType type;

  const ActivityItem({
    required this.ticketId,
    required this.ticketTitle,
    required this.actor,
    required this.message,
    required this.time,
    required this.type,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// ── Added `closed` activity type ──────────────────────────────────────────────
enum ActivityType { submitted, moved, resolved, cancelled, assigned, closed }


// ─────────────────────────────────────────────
// MAPPERS
// ─────────────────────────────────────────────

TicketStatus mapStatus(String status) {
  final s = status.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  if (s == 'closed')              return TicketStatus.closed;
  if (s.startsWith('for'))        return TicketStatus.forAssessment;
  if (s == 'inprogress')          return TicketStatus.inProgress;
  if (s.contains('resolved'))     return TicketStatus.resolved;
  if (s.contains('cancel'))       return TicketStatus.cancelled;
  return TicketStatus.forAssessment;
}

TicketPriority mapPriority(String priority) {
  final p = priority.toLowerCase();
  if (p.contains('1')) return TicketPriority.priority1;
  if (p.contains('2')) return TicketPriority.priority2;
  if (p.contains('3')) return TicketPriority.priority3;
  if (p.contains('4')) return TicketPriority.priority4;
  return TicketPriority.priority4;
}