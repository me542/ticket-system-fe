import 'package:flutter/material.dart';

class TicketFormPage extends StatefulWidget {
  const TicketFormPage({super.key});

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController requesterController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? ticketType;
  String? category;
  String assignTo = "Auto-assign";
  String? organization = "BAKAWAN";
  String? severity;

  int priority = 1;

  final List<String> ticketTypes = [
    "Incident",
    "Service Request",
    "Change Request",
    "Problem",
  ];

  final List<String> categories = [
    "Customer Premise",
    "Software Installation",
    "Server",
  ];

  final List<String> severities = [
    "Low",
    "Affects a User",
    "Affects Multiple Users",
    "Critical",
  ];

  final List<String> organizations = [
    "BAKAWAN",
    "CMIT",
    "FDS",
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0f0f0f),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create New Ticket",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey[800]),
              const SizedBox(height: 8),

              // SUBJECT
              _label("SUBJECT *"),
              _input(subjectController, "Brief summary of the issue...", height: 40),

              const SizedBox(height: 8),

              // ROW 1
              Row(
                children: [
                  Expanded(
                    child: _dropdown("TICKET TYPE *", ticketType, ticketTypes,
                            (val) => setState(() => ticketType = val)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _dropdown("CATEGORY *", category, categories,
                            (val) => setState(() => category = val)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ROW 2
              Row(
                children: [
                  Expanded(
                    child: _input(requesterController, "Search user or email...",
                        label: "REQUESTER", height: 40),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _readonly("ASSIGN TO", assignTo),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ROW 3
              Row(
                children: [
                  Expanded(
                    child: _dropdown("ORGANIZATION", organization, organizations,
                            (val) => setState(() => organization = val)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _dropdown("SEVERITY", severity, severities,
                            (val) => setState(() => severity = val)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // PRIORITY
              _label("PRIORITY *"),
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (index) {
                  int p = index + 1;
                  Color color;
                  switch (p) {
                    case 1:
                      color = Colors.red;
                      break;
                    case 2:
                      color = Colors.orange;
                      break;
                    case 3:
                      color = Colors.yellow;
                      break;
                    case 4:
                      color = Colors.green;
                      break;
                    default:
                      color = Colors.grey;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => priority = p),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: priority == p
                              ? color.withOpacity(0.2)
                              : const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: priority == p ? color : Colors.grey.shade700,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.circle,
                                size: 8,
                                color: priority == p ? color : Colors.grey),
                            const SizedBox(height: 5),
                            Text(
                              "Priority $p",
                              style: TextStyle(
                                color: priority == p ? color : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 8),

              // DESCRIPTION
              _label("DESCRIPTION"),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration("Describe the issue — steps to reproduce..."),
              ),

              const SizedBox(height: 8),

              // UPLOAD BOX
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey.shade700,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_file, color: Colors.grey),
                      SizedBox(height: 5),
                      Text(
                        "Click to upload or drag & drop",
                        style: TextStyle(color: Colors.blue),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Screenshots, logs, config files up to 25MB",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3b82f6),
                    ),
                    onPressed: _submit,
                    child: const Text("Submit Ticket"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 LABEL
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }

  // 🔹 INPUT
  Widget _input(TextEditingController controller, String hint,
      {String? label, double height = 35}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _label(label),
        if (label != null) const SizedBox(height: 5),
        SizedBox(
          height: height,
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(hint),
          ),
        ),
      ],
    );
  }

  // 🔹 DROPDOWN
  Widget _dropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text("Select..."),
          dropdownColor: const Color(0xFF1A1F2E),
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(""),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // 🔹 READ ONLY FIELD
  Widget _readonly(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // 🔹 INPUT STYLE
  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1A1F2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  // 🔥 SUBMIT
  void _submit() {
    print({
      "subject": subjectController.text,
      "ticketType": ticketType,
      "category": category,
      "organization": organization,
      "severity": severity,
      "priority": priority,
      "description": descriptionController.text,
    });

    Navigator.pop(context);
  }
}
