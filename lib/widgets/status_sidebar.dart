import 'package:flutter/material.dart';
import '../data/app_theme.dart';
import '../models/ticket.dart';

class TicketSidebar extends StatefulWidget {
  final Ticket? ticket;
  final VoidCallback onClose;

  const TicketSidebar({
    super.key,
    required this.ticket,
    required this.onClose,
  });

  @override
  State<TicketSidebar> createState() => _TicketSidebarState();
}

class _TicketSidebarState extends State<TicketSidebar> {
  String? assignedResolver; // 🔥 LOCAL STATE (Stage 3)

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    if (ticket == null) return const SizedBox();

    return Material(
      elevation: 20,
      child: Container(
        width: 520,
        color: AppTheme.sidebarBg,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ticket Detail",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// TITLE
              Text(
                ticket.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              /// STATUS + PRIORITY
              Row(
                children: [
                  _chip(ticket.status.name, AppTheme.statusAssessment),
                  const SizedBox(width: 8),
                  _chip(ticket.priority.name, AppTheme.statusProgress),
                ],
              ),

              const SizedBox(height: 16),

              /// DETAILS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Wrap(
                  spacing: 30,
                  runSpacing: 5,
                  children: [
                    SizedBox(
                      width: 480,
                      child: _row("Category", ticket.category.name),
                    ),
                    SizedBox(
                      width: 480,
                      child: _row("Submitter", ticket.submitter),
                    ),
                    SizedBox(
                      width: 480,
                      child: _row("Created", ticket.createdAt.toString()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// TICKET TRACE
              _ticketTrace(ticket),

              const SizedBox(height: 16),

              /// APPROVAL CHAIN
              _approvalChain(ticket),

              const SizedBox(height: 16),

              /// REPLY
              const Text("Reply", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: "Write a reply...",
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Post Reply"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CHIPS
  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  /// ROW DETAIL
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  /// TICKET TRACE / WORKFLOW
  Widget _ticketTrace(Ticket ticket) {
    final steps = [
      "Submitter",
      "Endorser",
      "Approver",
      "Assigned",
      "In Progress",
      "Resolved"
    ];

    int activeStep = 0;
    switch (ticket.status.name.toLowerCase()) {
      case "endorsement":
        activeStep = 1;
        break;
      case "approval":
        activeStep = 2;
        break;
      case "assigned":
        activeStep = 3;
        break;
      case "inprogress":
        activeStep = 4;
        break;
      case "resolved":
        activeStep = 5;
        break;
      default:
        activeStep = 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= activeStep;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                  isActive ? Colors.green : Colors.grey.shade800,
                  child: isActive
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 16)
                      : Text(
                    "${index + 1}",
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    height: 2,
                    color: index < activeStep
                        ? Colors.green
                        : Colors.grey.shade700,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// APPROVAL CHAIN (WITH STAGE 3)
  Widget _approvalChain(Ticket ticket) {
    bool isStage1Active = ticket.status.name == "Endorsement";
    bool isStage3Active = ticket.status.name == "Approved";

    bool isAssigned = assignedResolver != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF268A15).withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ===== STAGE 1 =====
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Text("RL",
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("R. Lozano",
                        style: TextStyle(color: Colors.white)),
                    Text(
                      "Stage 1 — Endorser",
                      style:
                      TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Text("Reviewing",
                  style: TextStyle(color: Colors.green)),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade800),

          /// ===== STAGE 3 =====
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isStage3Active
                    ? Colors.purple
                    : Colors.grey.shade800,
                child: Icon(
                  isAssigned ? Icons.person : Icons.build,
                  color: isStage3Active
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAssigned
                          ? assignedResolver!
                          : "Unassigned Resolver",
                      style: TextStyle(
                        color: isStage3Active
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    const Text(
                      "Stage 3 — Resolution",
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                isAssigned ? "Assigned" : "Open",
                style: TextStyle(
                  color:
                  isAssigned ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ASSIGN BUTTON
          if (isStage3Active)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAssigned
                    ? null
                    : () {
                  setState(() {
                    assignedResolver = "You";
                  });
                },
                icon: const Icon(Icons.person_add),
                label: Text(
                  isAssigned
                      ? "Already Assigned"
                      : "Assign to Me",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isAssigned ? Colors.grey : Colors.purple,
                ),
              ),
            ),

          const SizedBox(height: 20),

          /// ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isStage1Active ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("✔ Endorse"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isStage1Active ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("✖ Reject"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
