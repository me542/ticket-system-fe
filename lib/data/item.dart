enum ActivityType { submitted, moved, resolved, cancelled, assigned }

class ActivityItem {
  final String ticketId;
  final String message;
  final String timeAgo;
  final ActivityType type;

  ActivityItem({
    required this.ticketId,
    required this.message,
    required this.timeAgo,
    required this.type,
  });
}
