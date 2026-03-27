import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  int selectedPriority = 1;
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes; // for web preview

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
      withData: true, // important for web!
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _fileBytes = _selectedFile!.bytes; // store bytes for preview
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1117),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
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
              _input("Brief summary of the issue or request..."),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dropdown("TICKET TYPE *", "Change Request")),
                  const SizedBox(width: 8),
                  Expanded(child: _dropdown("CATEGORY *", "Select...")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputWithLabel("REQUESTER", "Search user or email...")),
                  const SizedBox(width: 8),
                  Expanded(child: _inputWithLabel("ORGANIZATION", "BAKAWAN Data Analytics")),
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
                      onTap: () => setState(() => selectedPriority = value),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedPriority == value ? color.withOpacity(0.15) : const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selectedPriority == value ? color : const Color(0xFF2A3142)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            Text(
                              "Priority $value",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selectedPriority == value ? color : Colors.grey),
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
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Describe the issue...",
                    hintStyle: TextStyle(color: Colors.grey),
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
                    border: Border.all(color: const Color(0xFF2A3142)),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF1A1F2E),
                  ),
                  child: _selectedFile != null
                      ? Row(
                    children: [
                      const SizedBox(width: 8),
                      if (_fileBytes != null && (_selectedFile!.extension == 'jpg' || _selectedFile!.extension == 'png' || _selectedFile!.extension == 'jpeg'))
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(
                            _fileBytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.insert_drive_file, color: Colors.white, size: 40),
                        ),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                      : const Center(
                    child: Text(
                      "Click anywhere to upload file (jpg, png, pdf, doc) max 25MB",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _outlineButton("Cancel", () => Navigator.pop(context)),
                  _primaryButton("Submit", () {}),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  );

  Widget _input(String hint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: _boxDecoration(),
    child: TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.grey), border: InputBorder.none),
    ),
  );

  Widget _inputWithLabel(String label, String hint) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label(label), _input(hint)]);

  Widget _dropdown(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _boxDecoration(),
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1F2E),
          isExpanded: true,
          underline: const SizedBox(),
          items: [value].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: (_) {},
        ),
      ),
    ],
  );

  BoxDecoration _boxDecoration() => BoxDecoration(color: const Color(0xFF1A1F2E), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A3142)));

  Widget _primaryButton(String text, VoidCallback onPressed) => ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF268A15), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)), onPressed: onPressed, child: Text(text));

  Widget _outlineButton(String text, VoidCallback onPressed) => OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2A3142))), onPressed: onPressed, child: Text(text, style: const TextStyle(color: Colors.white)));
}
