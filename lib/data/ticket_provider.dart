import 'package:flutter/foundation.dart';
import '../models/ticket.dart';

class TicketProvider extends ChangeNotifier {
  final String currentUserName = 'Bakawan';
  final String currentUserRole = 'Admin';
  final String currentUserInitials = 'B';

  // ✅ EMPTY LIST (no hardcoded data)
  final List<Ticket> _tickets = [];

  final List<ActivityItem> _activities = [];

  List<Ticket> get allTickets => List.unmodifiable(_tickets);

  List<Ticket> get forAssessmentTickets =>
      _tickets.where((t) => t.status == TicketStatus.forAssessment).toList();

  List<Ticket> get inProgressTickets =>
      _tickets.where((t) => t.status == TicketStatus.inProgress).toList();

  List<Ticket> get resolvedTickets =>
      _tickets.where((t) => t.status == TicketStatus.resolved).toList();

  List<ActivityItem> get activities => List.unmodifiable(_activities);

  int get totalTickets => _tickets.length;
  int get forAssessmentCount => forAssessmentTickets.length;
  int get inProgressCount => inProgressTickets.length;
  int get resolvedCount => resolvedTickets.length;

  Map<TicketCategory, int> get categoryCount {
    final map = <TicketCategory, int>{};
    for (final t in _tickets) {
      map[t.category] = (map[t.category] ?? 0) + 1;
    }
    return map;
  }

  List<Ticket> filterTickets(String filter) {
    switch (filter) {
      case 'For':
        return forAssessmentTickets;
      case 'In':
        return inProgressTickets;
      case 'Resolved':
        return resolvedTickets;
      default:
        return allTickets;
    }
  }

  void addTicket(Ticket ticket) {
    _tickets.insert(0, ticket);

    // Optional: add activity log automatically
    _activities.insert(
      0,
      ActivityItem(
        ticketId: ticket.id,
        message: 'submitted',
        time: DateTime.now(),
        type: ActivityType.submitted,
      ),
    );

    notifyListeners();
  }
}
