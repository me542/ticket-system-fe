import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/services/api_file.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../core/services/api_category.dart';
import '../data/light_theme.dart';

class CreateTicketSidebar extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onCreated;

  const CreateTicketSidebar({
    super.key,
    required this.onClose,
    this.onCreated,
  });

  @override
  State<CreateTicketSidebar> createState() => _CreateTicketSidebarState();
}

class _CreateTicketSidebarState extends State<CreateTicketSidebar> {
  // ── form state ────────────────────────────────────────────────────────────
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int _priority = 1;
  String _ticketType = 'Service Request';
  String _organization = 'Bakawan Data Analytics';

  // ── category ──────────────────────────────────────────────────────────────
  // Now stores subcategory name → description, not just name list
  // Structure: { categoryName: { 'subs': [{ 'name': '', 'description': '' }] } }
  Map<String, List<Map<String, String>>> _categoryMap = {};
  String? _category;
  String? _subCategory;
  bool _loadingCats = true;

  // ── endorser ──────────────────────────────────────────────────────────────
  String? _endorser;
  List<String> _endorsers = [];

  // ── file ──────────────────────────────────────────────────────────────────
  PlatformFile? _file;
  Uint8List? _fileBytes;

  // ── submit state ──────────────────────────────────────────────────────────
  bool _submitting = false;

  // ── tracks whether user has manually edited the description ───────────────
  // If true, switching subcategory won't overwrite their typed content.
  bool _descManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCategories();
    _descCtrl.addListener(_onDescChanged);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.removeListener(_onDescChanged);
    _descCtrl.dispose();
    super.dispose();
  }

  // Called whenever user types in the description field.
  // Once they type something themselves, stop auto-filling from templates.
  void _onDescChanged() {
    // We only flag as manually edited during active user input,
    // not when we programmatically set the text.
    // We use _isProgrammaticallySettingDesc to distinguish the two.
  }

  bool _isProgrammaticallySettingDesc = false;

  /// Set description text from a template without flagging it as manual edit.
  void _setDescFromTemplate(String text) {
    _isProgrammaticallySettingDesc = true;
    _descCtrl.text = text;
    // Move cursor to end
    _descCtrl.selection = TextSelection.collapsed(offset: text.length);
    _isProgrammaticallySettingDesc = false;
    _descManuallyEdited = false;
  }

  // ── loaders ───────────────────────────────────────────────────────────────
  Future<void> _loadUsers() async {
    final users = await ApiGetUser.fetchUsers();
    if (!mounted) return;

    debugPrint('>>> _loadUsers total users: ${users.length}');
    for (final u in users) {
      debugPrint('>>>   user: ${u['username']} | role: "${u['role']}"');
    }

    // Filter endorsers — role field is now always a non-null String
    final endorserUsers = users
        .where((u) => (u['role'] ?? '').toLowerCase() == 'endorser')
        .toList();

    debugPrint('>>> endorsers found: ${endorserUsers.length}');

    // Show full_name in dropdown; fall back to username
    final endorserNames = endorserUsers
        .map((u) {
      final display = u['username'] ?? '';
      return display;
    })
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() {
      _endorsers = endorserNames;
      if (endorserNames.isNotEmpty) _endorser = endorserNames.first;
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    final token = await ApiLogin.getToken() ?? '';
    final raw = await ApiCategory.fetchCategories(token: token);
    if (!mounted) return;

    // ── Build map: categoryName → list of { name, description } ──────────
    final Map<String, List<Map<String, String>>> built = {};

    for (final cat in raw) {
      final name =
      ((cat['name'] ?? cat['Name']) as String? ?? '').trim();
      if (name.isEmpty) continue;

      // Handle all common key casings from the backend
      final subsRaw =
          cat['SubCategories'] ??
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

    final cats = built.keys.toList();
    final firstCat = cats.isNotEmpty ? cats.first : null;
    final firstSub =
    firstCat != null && built[firstCat]!.isNotEmpty
        ? built[firstCat]!.first
        : null;

    setState(() {
      _categoryMap = built;
      _category = firstCat;
      _subCategory = firstSub?['name'];
      _loadingCats = false;
    });

    // Pre-fill description with first subcategory's template
    if (firstSub != null && (firstSub['description'] ?? '').isNotEmpty) {
      _setDescFromTemplate(firstSub['description']!);
    }
  }

  // ── subcategory names for a given category ────────────────────────────────
  List<String> _subNames(String? category) {
    if (category == null) return [];
    return (_categoryMap[category] ?? [])
        .map((s) => s['name']!)
        .toList();
  }

  // ── get template description for a subcategory ────────────────────────────
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
    // Pre-fill description from template
    final desc = firstSub?['description'] ?? '';
    _setDescFromTemplate(desc);
  }

  void _onSubcategoryChanged(String? val) {
    if (val == null) return;
    setState(() {
      _subCategory = val;
      _descManuallyEdited = false;
    });
    // Pre-fill description from this subcategory's template
    if (_category != null) {
      final desc = _subDescription(_category!, val);
      _setDescFromTemplate(desc);
    }
  }

  // ── file picker ───────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      if (f.size > 25 * 1024 * 1024) {
        _snack('File too large. Max 25 MB', color: Colors.redAccent);
        return;
      }
      setState(() {
        _file = f;
        _fileBytes = f.bytes;
      });
    }
  }

  // ── submit confirmation ────────────────────────────────────────────────────
  Future<bool> showSubmitConfirmation(BuildContext context) async {
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
                          'Confirm Submission',
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
                    'Are you sure you want to submit this ticket?',
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
                          'Submit',
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

  // ── submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _snack('Subject and description are required', color: Colors.redAccent);
      return;
    }
    setState(() => _submitting = true);
    try {
      final ticketCode = await ApiTicket.createTicket(
        subject: _subjectCtrl.text.trim(),
        tickettype: _ticketType,
        category: _category ?? '',
        subcategory: _subCategory ?? '',
        organization: _organization,
        priority: _priority,
        description: _descCtrl.text.trim(),
        file: _file,
        endorser: _endorser ?? '',
      );
      if (ticketCode != null) {
        _snack('Ticket $ticketCode created successfully',
            color: AppTheme.statusResolved);
        _reset();
        widget.onCreated?.call();
        widget.onClose();
      } else {
        _snack('Failed to create ticket', color: Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    _subjectCtrl.clear();
    final cats = _categoryMap.keys.toList();
    final firstCat = cats.isNotEmpty ? cats.first : null;
    final firstSub =
    firstCat != null && (_categoryMap[firstCat] ?? []).isNotEmpty
        ? _categoryMap[firstCat]!.first
        : null;

    setState(() {
      _priority = 1;
      _ticketType = 'Service Request';
      _organization = 'Bakawan Data Analytics';
      _category = firstCat;
      _subCategory = firstSub?['name'];
      _file = null;
      _fileBytes = null;
      _descManuallyEdited = false;
      if (_endorsers.isNotEmpty) _endorser = _endorsers.first;
    });

    // Restore template description
    _setDescFromTemplate(firstSub?['description'] ?? '');
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

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      child: Container(
        width: 1250,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline,
              color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'New Ticket',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _reset();
              widget.onClose();
            },
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
                        : null,
                    items: _endorsers,
                    hint: 'Select endorser',
                    onChanged: (v) => setState(() => _endorser = v),
                  ),
                ),
                const SizedBox(height: 10),

                // ── ORGANIZATION ──
                _fieldCard(
                  label: 'ORGANIZATION',
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
                // ── PRIORITY ──
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
                                // Let user restore template if they want
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
                                      color:
                                      AppTheme.accent.withOpacity(0.3)),
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
                      // Pre-filled with template, fully editable by user
                      TextField(
                        controller: _descCtrl,
                        minLines: 12,
                        maxLines: null,
                        onChanged: (_) {
                          // Mark as manually edited so switching sub
                          // doesn't silently wipe their work
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
                      if (_file != null && _fileBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFilePreview(),
                        ),
                      SizedBox(
                        height: _file == null ? 200 : 120,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Max file size: 25MB',
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
                    Expanded(child: _outlineBtn('Clear', _reset)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _primaryBtn('Submit', () async {
                        final confirm =
                        await showSubmitConfirmation(context);
                        if (confirm) _submit();
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
  Widget _buildFilePreview() {
    final isImage =
    ['jpg', 'jpeg', 'png'].contains(_file!.extension);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sidebarBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          if (isImage && _fileBytes != null)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.memory(_fileBytes!,
                  width: double.infinity, height: 140, fit: BoxFit.cover),
            ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(
                isImage
                    ? Icons.image_outlined
                    : Icons.insert_drive_file_outlined,
                color: isImage ? Colors.blue : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _file!.name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _file = null;
                  _fileBytes = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 12, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text('Remove',
                          style: TextStyle(
                              fontSize: 11, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
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
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle:
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    onPressed: onPressed,
    child: Text(text),
  );

  Widget _outlineBtn(String text, VoidCallback onPressed) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppTheme.border),
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 13),
    ),
    onPressed: onPressed,
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