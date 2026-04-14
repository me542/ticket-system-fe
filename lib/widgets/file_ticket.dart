import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/services/api_file.dart';
import '../core/services/api_user_data.dart'; //

final TextEditingController subjectController = TextEditingController();
final TextEditingController descriptionController = TextEditingController();

class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  int selectedPriority = 1;
  String selectedTicketType = "Service Request";
  String selectedOrganization = "Bakawan Data Analytics";
  String selectedCategory = "IT Related - Customer Premise E.";

  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;

  // ✅ UPDATED (dynamic users)
  String? selectedRequester;
  List<String> requesterOptions = [];

  @override
  void initState() {
    super.initState();
    _loadUsers(); // ✅ load from API
  }

  Future<void> _loadUsers() async {
    final users = await ApiGetUser.fetchUsers();

    if (users.isNotEmpty) {
      // ✅ FILTER ONLY ENDORSER ROLE
      final endorsers = users.where((u) =>
      (u['role'] ?? '').toLowerCase() == 'endorser').toList();

      setState(() {
        requesterOptions =
            endorsers.map((u) => u['username'] ?? '').toList();

        // ✅ safe default
        if (requesterOptions.isNotEmpty) {
          selectedRequester = requesterOptions.first;
        }
      });
    }
  }


  void _resetFields() {
    subjectController.clear();
    descriptionController.clear();
    setState(() {
      selectedPriority = 1;
      selectedTicketType = "Service Request";
      selectedCategory = "IT Related - Customer Premise E.";
      selectedOrganization = "Bakawan Data Analytics";
      _selectedFile = null;
      _fileBytes = null;
      if (requesterOptions.isNotEmpty) {
        selectedRequester = requesterOptions.first;
      }
    });
  }

  Color _getPriorityColor(int value) {
    switch (value) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 25 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File too large. Max 25MB allowed")),
        );
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileBytes = file.bytes;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileBytes = null;
    });
  }

  Future<void> _submitTicket() async {
    if (subjectController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Subject and description are required")),
      );
      return;
    }

    final ticketCode = await ApiTicket.createTicket(
      subject: subjectController.text,
      tickettype: selectedTicketType,
      category: selectedCategory,
      organization: selectedOrganization,
      priority: selectedPriority,
      description: descriptionController.text,
      file: _selectedFile,
      endorser: selectedRequester ?? '', // ✅ only one endorser parameter
    );

    if (ticketCode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text("Ticket created successfully: $ticketCode")),
      );
      _resetFields();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create ticket")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1117),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D27),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create New Ticket",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),

              _label("SUBJECT *"),
              _input("Brief summary...",
                  controller: subjectController),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _dropdownCustom(
                      "TICKET TYPE *",
                      selectedTicketType,
                      ["Service Request", "Change Request", "Incident"],
                          (val) =>
                          setState(() => selectedTicketType = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dropdownCustom(
                      "CATEGORY *",
                      selectedCategory,
                      [
                        "IT Related - Customer Premise E.",
                        "IT Related - Software - Installation",
                        "IT Related - Storage - Server",
                        "IT Related - Network - Connection",
                        "IT Related - Database - User Accounts",
                        "IT Related - Applications - Amazon",
                        "IT Related - Endpoint - Desktop",
                      ],
                          (val) =>
                          setState(() => selectedCategory = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: requesterOptions.isEmpty
                        ? const Center(
                        child: CircularProgressIndicator())
                        : _dropdownCustom(
                      "Endoser",
                      selectedRequester,
                      requesterOptions,
                          (val) => setState(
                              () => selectedRequester = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dropdownCustom(
                      "ORGANIZATION",
                      selectedOrganization,
                      ["Bakawan Data Analytics", "FDSAP", "CMIT"],
                          (val) => setState(
                              () => selectedOrganization = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _label("PRIORITY *"),
              Row(
                children: List.generate(4, (index) {
                  int value = index + 1;
                  final color = _getPriorityColor(value);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedPriority = value),
                      child: Container(
                        margin:
                        const EdgeInsets.only(right: 6),
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedPriority == value
                              ? color.withOpacity(0.15)
                              : const Color(0xFF1A1F2E),
                          borderRadius:
                          BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedPriority == value
                                ? color
                                : const Color(0xFF2A3142),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(
                                  right: 6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              "Priority $value",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w500,
                                color:
                                selectedPriority == value
                                    ? color
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),

              _label("DESCRIPTION"),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: _boxDecoration(),
                child: TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: null,
                  style:
                  const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Describe the issue...",
                    hintStyle:
                    TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _label("UPLOAD FILE"),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF2A3142)),
                    borderRadius:
                    BorderRadius.circular(10),
                    color: const Color(0xFF1A1F2E),
                  ),
                  child: _selectedFile != null
                      ? Row(
                    children: [
                      const SizedBox(width: 8),
                      if (_fileBytes != null &&
                          (_selectedFile!
                              .extension ==
                              'jpg' ||
                              _selectedFile!
                                  .extension ==
                                  'png' ||
                              _selectedFile!
                                  .extension ==
                                  'jpeg'))
                        Padding(
                          padding:
                          const EdgeInsets.all(8.0),
                          child: Image.memory(
                            _fileBytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Padding(
                          padding:
                          EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.insert_drive_file,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: const TextStyle(
                              color: Colors.white),
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red),
                        onPressed: _removeFile,
                      ),
                    ],
                  )
                      : const Center(
                    child: Text(
                      "Click anywhere to upload file (jpg, png, pdf, doc) max 5MB",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  _outlineButton("Cancel", () {
                    _resetFields();
                    Navigator.pop(context);
                  }),
                  _primaryButton("Submit", _submitTicket),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            color: Colors.grey, fontSize: 12)),
  );

  Widget _input(String hint,
      {TextEditingController? controller}) =>
      Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12),
        decoration: _boxDecoration(),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      );

  Widget _dropdownCustom(String label, String? value,
      List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12),
          decoration: _boxDecoration(),
          child: DropdownButton<String>(
            value: value,
            dropdownColor:
            const Color(0xFF1A1F2E),
            isExpanded: true,
            underline: const SizedBox(),
            iconEnabledColor: Colors.white,
            items: items
                .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e,
                  style: const TextStyle(
                      color: Colors.white)),
            ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: const Color(0xFF1A1F2E),
    borderRadius: BorderRadius.circular(10),
    border:
    Border.all(color: const Color(0xFF2A3142)),
  );

  Widget _primaryButton(
      String text, VoidCallback onPressed) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          const Color(0xFF268A15),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(text),
      );

  Widget _outlineButton(
      String text, VoidCallback onPressed) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: const BorderSide(
                color: Color(0xFF2A3142))),
        onPressed: onPressed,
        child: Text(text,
            style:
            const TextStyle(color: Colors.white)),
      );
}
