import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/services/api_file.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../core/services/api_category.dart';
import '../core/services/api_edit_ticket.dart';
import '../data/light_theme.dart';
import '../models/ticket.dart';

class EditTicketSidebar extends StatefulWidget {
  final Ticket ticket;
  final Map<String, dynamic> ticketDetail;
  final VoidCallback onClose;
  final VoidCallback onUpdated;

  const EditTicketSidebar({
    super.key,
    required this.ticket,
    required this.ticketDetail,
    required this.onClose,
    required this.onUpdated,
  });

  @override
  State<EditTicketSidebar> createState() => _EditTicketSidebarState();
}

class _EditTicketSidebarState extends State<EditTicketSidebar> {
  // ── form state ────────────────────────────────���───────────────────────────
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _descCtrl;

  late int _priority;
  late String _ticketType;
  late String _organization;

  // ── category ──────────────────────────────────────────────────────────────
  Map<String, List<Map<String, String>>> _categoryMap = {};
  String? _category;
  String? _subCategory;
  bool _loadingCats = true;

  // ── endorser ──────────────────────────────────────────────────────────────
  String? _endorser;
  List<String> _endorsers = [];

  // ── file ──────────────────────────────────────────────────────────────────
  List<PlatformFile> _newFiles = [];
  int _totalFileSize = 0;

  static const int _maxTotalSize = 10 * 1024 * 1024;

  // ── submit state ────────────────��─────────────────────────────────────────
  bool _submitting = false;
  bool _descManuallyEdited = false;
  bool _isProgrammaticallySettingDesc = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadUsers();
    _loadCategories();
    _descCtrl.addListener(_onDescChanged);
  }

  void _initializeForm() {
    _subjectCtrl = TextEditingController(
      text: widget.ticketDetail['subject'] ?? widget.ticket.title,
    );

    _descCtrl = TextEditingController(
      text: widget.ticketDetail['description'] ?? widget.ticket.description,
    );

    _priority = _parsePriority(
      widget.ticketDetail['priority'] ?? widget.ticket.priority.index,
    );

    _ticketType = widget.ticketDetail['ticket_type'] ??
        widget.ticketDetail['tickettype'] ??
        'Service Request';

    _organization = widget.ticketDetail['institution'] ??
        widget.ticketDetail['organization'] ??
        'Bakawan Data Analytics';

    _category = widget.ticketDetail['category'];
    _subCategory = widget.ticketDetail['subcategory'] ??
        widget.ticketDetail['sub_category'];

    _endorser = widget.ticketDetail['endorser'] ??
        widget.ticketDetail['endorser_name'] ??
        widget.ticketDetail['assigned_endorser'];
  }

  int _parsePriority(dynamic val) {
    if (val is int) return val.clamp(1, 4);
    if (val is String) {
      final map = {'low': 1, 'medium': 2, 'high': 3, 'critical': 4};
      return map[val.toLowerCase()] ?? 1;
    }
    return 1;
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.removeListener(_onDescChanged);
    _descCtrl.dispose();
    super.dispose();
  }

  void _onDescChanged() {}

  void _setDescFromTemplate(String text) {
    _isProgrammaticallySettingDesc = true;
    _descCtrl.text = text;
    _descCtrl.selection = TextSelection.collapsed(offset: text.length);
    _isProgrammaticallySettingDesc = false;
    _descManuallyEdited = false;
  }

  // ── loaders ───────────────────────────────────────────────────────────────
  Future<void> _loadUsers() async {
    final users = await ApiGetUser.fetchUsers();
    final currentUser = await ApiUserData.getUsername();

    if (!mounted) return;

    final endorserUsers = users.where((u) {
      final role = (u['role'] ?? '').toLowerCase();
      final username = (u['username'] ?? '').trim().toLowerCase();
      final isCurrentUser =
          username == (currentUser ?? '').trim().toLowerCase();
      return role == 'endorser' && !isCurrentUser;
    }).toList();

    final endorserNames = endorserUsers
        .map((u) => u['username'] ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() {
      _endorsers = endorserNames;
      if (_endorser == null && endorserNames.isNotEmpty) {
        _endorser = endorserNames.first;
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    final token = await ApiLogin.getToken() ?? '';
    final raw = await ApiCategory.fetchCategories(token: token);
    if (!mounted) return;

    final Map<String, List<Map<String, String>>> built = {};

    for (final cat in raw) {
      final name =
      ((cat['name'] ?? cat['Name']) as String? ?? '').trim();
      if (name.isEmpty) continue;

      final subsRaw = cat['SubCategories'] ??
          cat['sub_categories'] ??
          cat['subcategories'] ??
          cat['Subcategories'] ??
          <dynamic>[];

      final subs = (subsRaw as List<dynamic>).map((s) {
        final subName =
        ((s['name'] ?? s['Name']) as String? ?? '').trim();
        final subDesc =
        ((s['description'] ?? s['Description']) as String? ?? '')
            .trim();
        return {'name': subName, 'description': subDesc};
      }).where((s) => s['name']!.isNotEmpty).toList();

      built[name] = subs;
    }

    setState(() {
      _categoryMap = built;
      _loadingCats = false;
    });
  }

  List<String> _subNames(String? category) {
    if (category == null) return [];
    return (_categoryMap[category] ?? [])
        .map((s) => s['name']!)
        .toList();
  }

  String _subDescription(String category, String subName) {
    final subs = _categoryMap[category] ?? [];
    final match = subs.firstWhere(
          (s) => s['name'] == subName,
      orElse: () => {'name': '', 'description': ''},
    );
    return match['description'] ?? '';
  }

  void _onCategoryChanged(String? val) {
    if (val == null) return;
    final subs = _categoryMap[val] ?? [];
    final firstSub = subs.isNotEmpty ? subs.first : null;
    setState(() {
      _category = val;
      _subCategory = firstSub?['name'];
      _descManuallyEdited = false;
    });
    final desc = firstSub?['description'] ?? '';
    _setDescFromTemplate(desc);
  }

  void _onSubcategoryChanged(String? val) {
    if (val == null) return;
    setState(() {
      _subCategory = val;
      _descManuallyEdited = false;
    });
    if (_category != null) {
      final desc = _subDescription(_category!, val);
      _setDescFromTemplate(desc);
    }
  }

  // ── file picker ───────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx'
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    int incomingSize = result.files.fold(0, (sum, f) => sum + f.size);

    if ((_totalFileSize + incomingSize) > _maxTotalSize) {
      _snack(
        'Total attachment size exceeds 10 MB',
        color: Colors.redAccent,
      );
      return;
    }

    setState(() {
      _newFiles.addAll(result.files);
      _totalFileSize += incomingSize;
    });
  }

  // ── submit confirmation ────────────────────────────────────────────────────
  Future<bool> showUpdateConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Confirm Update',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close,
                            size: 18, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Are you sure you want to update this ticket?',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _outlineBtn(
                          'Cancel',
                              () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _primaryBtn(
                          'Update',
                              () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  // ── submit/update ─────────────────────────────────────────────────────────
  Future<void> _updateTicket() async {
    if (_subjectCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _category == null ||
        _subCategory == null ||
        _endorser == null) {
      _snack('Subject and description are required',
          color: Colors.redAccent);
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await ApiLogin.getToken();
      if (token == null || token.isEmpty) {
        _snack('Not authenticated. Please log in again.',
            color: Colors.redAccent);
        return;
      }

      final result = await TicketService.updateTicket(
        token: token,
        ticketId: widget.ticket.id,
        subject: _subjectCtrl.text.trim(),
        category: _category ?? '',
        subcategory: _subCategory ?? '',
        institution: _organization,
        description: _descCtrl.text.trim(),
        priority: _priority.toString(),
        endorser: _endorser ?? '',
        attachments: _newFiles,
      );

      if (result['success'] == true) {
        _snack('Ticket updated successfully ✓',
            color: AppTheme.statusResolved);
        widget.onUpdated();
      } else {
        _snack(
          result['message'] ?? 'Failed to update ticket',
          color: Colors.redAccent,
        );
      }
    } catch (e) {
      _snack('Update failed: $e', color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {Color color = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      child: Container(
        width: 1100,
        color: AppTheme.sidebarBg,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final srNumber = widget.ticketDetail['ticket_code'] ??
        widget.ticketDetail['sr_number'] ??
        widget.ticket.id;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Ticket',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 11,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      srNumber.toString(),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // ── body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────────── LEFT COLUMN ─────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.flag_outlined,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        _sectionLabel('PRIORITY'),
                      ]),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(4, (i) {
                          final val = i + 1;
                          final color = _priorityColor(val);
                          final selected = _priority == val;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _priority = val),
                              child: Container(
                                margin:
                                EdgeInsets.only(right: i < 3 ? 6 : 0),
                                padding:
                                const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? color.withOpacity(0.15)
                                      : AppTheme.sidebarBg,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: selected
                                        ? color
                                        : AppTheme.border,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'P$val',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? color
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── TICKET TYPE ──
                _fieldCard(
                  label: 'TICKET TYPE',
                  required: true,
                  child: _styledDropdown(
                    value: _ticketType,
                    items: const [
                      'Service Request',
                      'Change Request',
                      'Incident'
                    ],
                    onChanged: (v) => setState(() => _ticketType = v!),
                  ),
                ),
                const SizedBox(height: 10),

                // ── CATEGORY ──
                _fieldCard(
                  label: 'CATEGORY',
                  required: true,
                  child: _loadingCats
                      ? _loadingRow()
                      : _styledDropdown(
                    value: _categoryMap.keys.contains(_category)
                        ? _category
                        : null,
                    items: _categoryMap.keys.toList(),
                    hint: 'Select category',
                    onChanged: _onCategoryChanged,
                  ),
                ),
                const SizedBox(height: 10),

                // ── SUBCATEGORY ──
                _fieldCard(
                  label: 'SUBCATEGORY',
                  required: true,
                  child: _loadingCats
                      ? _loadingRow()
                      : _styledDropdown(
                    value: _subNames(_category).contains(_subCategory)
                        ? _subCategory
                        : _subNames(_category).isNotEmpty
                        ? _subNames(_category).first
                        : null,
                    items: _subNames(_category),
                    hint: 'Select subcategory',
                    onChanged: _onSubcategoryChanged,
                  ),
                ),
                const SizedBox(height: 10),

                // ── ENDORSER ──
                _fieldCard(
                  label: 'ENDORSER',
                  child: _endorsers.isEmpty
                      ? _loadingRow()
                      : _styledDropdown(
                    value: _endorsers.contains(_endorser)
                        ? _endorser
                        : _endorsers.isNotEmpty
                        ? _endorsers.first
                        : null,
                    items: _endorsers,
                    hint: 'Select endorser',
                    onChanged: (v) => setState(() => _endorser = v),
                  ),
                ),
                const SizedBox(height: 10),

                // ── ORGANIZATION ──
                _fieldCard(
                  label: 'RESOLVER POLL',
                  child: _styledDropdown(
                    value: _organization,
                    items: const ['Bakawan Data Analytics'],
                    onChanged: (v) => setState(() => _organization = v!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ───────────────── RIGHT COLUMN ────────────────
          SizedBox(
            width: 625,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subject ─
                _fieldCard(
                  label: 'SUBJECT',
                  required: true,
                  child: SizedBox(
                    height: 70,
                    child: _fieldInput(
                      controller: _subjectCtrl,
                      hint: 'Brief summary of the issue...',
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── DESCRIPTION ──────────────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notes,
                              size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          _sectionLabel('DESCRIPTION'),
                          const SizedBox(width: 6),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // ── Template hint chip ───────────────────────
                          if (_subCategory != null &&
                              _category != null &&
                              _subDescription(_category!, _subCategory!)
                                  .isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                final tmpl = _subDescription(
                                    _category!, _subCategory!);
                                _setDescFromTemplate(tmpl);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      color: AppTheme.accent
                                          .withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh,
                                        size: 11,
                                        color: AppTheme.accent
                                            .withOpacity(0.8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Restore template',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.accent
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Editable description field ───────────────────
                      TextField(
                        controller: _descCtrl,
                        minLines: 12,
                        maxLines: null,
                        onChanged: (_) {
                          if (!_isProgrammaticallySettingDesc) {
                            _descManuallyEdited = true;
                          }
                        },
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Describe the issue in detail...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── ATTACHMENT ───────────────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ATTACHMENT'),
                      const SizedBox(height: 10),
                      if (_newFiles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFilesPreview(),
                        ),
                      SizedBox(
                        height: _newFiles.isEmpty ? 200 : 120,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Max total attachment size: 10MB',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _pickFile,
                                child: const Text('Upload File'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── BUTTONS ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _outlineBtn('Cancel', widget.onClose)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _primaryBtn('Update', () async {
                        final confirm =
                        await showUpdateConfirmation(context);
                        if (confirm) _updateTicket();
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── file preview ──────────────────────────────────────────────────────────
  Widget _buildFilesPreview() {
    return Column(
      children: [
        ..._newFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;

          final isImage =
          ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.sidebarBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                if (isImage && file.bytes != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.memory(
                      file.bytes!,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isImage
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined,
                        color: isImage ? Colors.blue : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 2),

                            Text(
                              '${(file.size / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _totalFileSize -= file.size;
                            _newFiles.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 12,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Total: ${(_totalFileSize / (1024 * 1024)).toStringAsFixed(2)} MB / 10 MB',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widget helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );

  Widget _fieldCard({
    required String label,
    bool required = false,
    required Widget child,
  }) =>
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const SizedBox(width: 6),
              _sectionLabel(label),
              if (required) ...[
                const SizedBox(width: 3),
                const Text('*',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
            ]),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );

  Widget _fieldInput({
    required TextEditingController controller,
    String hint = '',
  }) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );

  Widget _styledDropdown({
    required String? value,
    required List<String> items,
    String? hint,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          dropdownColor: AppTheme.surface,
          isExpanded: true,
          underline: const SizedBox(),
          iconEnabledColor: AppTheme.textSecondary,
          style:
          const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          hint: hint != null
              ? Text(hint,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13))
              : null,
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      );

  Widget _loadingRow() => const Row(
    children: [
      SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppTheme.textMuted),
      ),
      SizedBox(width: 8),
      Text('Loading…',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
    ],
  );

  Widget _primaryBtn(String text, VoidCallback onPressed) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.accent,
      foregroundColor: Colors.white,
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle:
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    onPressed: _submitting ? null : onPressed,
    child: _submitting
        ? const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
          strokeWidth: 2, color: Colors.white),
    )
        : Text(text),
  );

  Widget _outlineBtn(String text, VoidCallback onPressed) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppTheme.border),
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 13),
    ),
    onPressed: _submitting ? null : onPressed,
    child: Text(text,
        style: const TextStyle(color: AppTheme.textSecondary)),
  );

  Color _priorityColor(int v) {
    switch (v) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
