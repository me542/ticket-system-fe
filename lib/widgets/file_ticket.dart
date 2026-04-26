import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/services/api_file.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../core/services/api_category.dart';
import '../data/light_theme.dart';

final TextEditingController subjectController = TextEditingController();
final TextEditingController descriptionController = TextEditingController();

const String _kAddNew = '__ADD_NEW__';

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar widget — drop it into the same AnimatedPositioned stack you use
// for TicketSidebar in dashboard_screen.dart
//
// Usage in DashboardScreen:
//   bool _isCreateOpen = false;
//
//   AnimatedPositioned(
//     duration: const Duration(milliseconds: 300),
//     curve: Curves.easeInOut,
//     top: 0, bottom: 0,
//     right: _isCreateOpen ? 0 : -540,
//     child: CreateTicketSidebar(
//       onClose: () => setState(() => _isCreateOpen = false),
//       onCreated: () { _loadTickets(); setState(() => _isCreateOpen = false); },
//     ),
//   ),
// ─────────────────────────────────────────────────────────────────────────────
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
  Map<String, List<String>> _categoryMap = {};
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

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCategories();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── loaders ───────────────────────────────────────────────────────────────
  Future<void> _loadUsers() async {
    final users = await ApiGetUser.fetchUsers();
    if (!mounted) return;
    final endorsers = users
        .where((u) => (u['role'] ?? '').toLowerCase() == 'endorser')
        .map((u) => u['username'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      _endorsers = endorsers;
      if (endorsers.isNotEmpty) _endorser = endorsers.first;
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    final token = await ApiLogin.getToken() ?? '';
    final raw = await ApiCategory.fetchCategories(token: token);
    if (!mounted) return;

    final Map<String, List<String>> built = {};
    for (final cat in raw) {
      final name = (cat['name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final subs = (cat['subcategories'] as List<dynamic>? ?? [])
          .map((s) => (s['name'] as String? ?? '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
      built[name] = subs;
    }
    final cats = built.keys.toList();
    setState(() {
      _categoryMap = built;
      _category = cats.isNotEmpty ? cats.first : null;
      final subs = _category != null ? (built[_category] ?? []) : <String>[];
      _subCategory = subs.isNotEmpty ? subs.first : null;
      _loadingCats = false;
    });
  }

  void _onCategoryChanged(String? val) {
    if (val == null || val == _kAddNew) return;
    final subs = _categoryMap[val] ?? [];
    setState(() {
      _category = val;
      _subCategory = subs.isNotEmpty ? subs.first : null;
    });
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
    _descCtrl.clear();
    final cats = _categoryMap.keys.toList();
    setState(() {
      _priority = 1;
      _ticketType = 'Service Request';
      _organization = 'Bakawan Data Analytics';
      _category = cats.isNotEmpty ? cats.first : null;
      final subs =
      _category != null ? (_categoryMap[_category] ?? []) : <String>[];
      _subCategory = subs.isNotEmpty ? subs.first : null;
      _file = null;
      _fileBytes = null;
      if (_endorsers.isNotEmpty) _endorser = _endorsers.first;
    });
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
  // ADD CATEGORY SHEET
  // ─────────────────────────────────────────────────────────────────────────
  void _openAddCategorySheet() {
    final nameCtrl = TextEditingController();
    final List<TextEditingController> subCtrls = [TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.sidebarBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── drag handle ──
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add New Category',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                _sheetLabel('CATEGORY NAME *'),
                _sheetInput(nameCtrl, 'e.g. STORAGE'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SUBCATEGORIES',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11,
                            letterSpacing: 0.6, fontWeight: FontWeight.w600)),
                    _miniButton(
                      icon: Icons.add,
                      label: 'Add Row',
                      onTap: () =>
                          setSheet(() => subCtrls.add(TextEditingController())),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  subCtrls.length,
                      (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                          child: _sheetInput(
                              subCtrls[i], 'Subcategory ${i + 1}')),
                      if (subCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.redAccent, size: 18),
                          onPressed: () =>
                              setSheet(() => subCtrls.removeAt(i)),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _outlineBtn('Cancel', () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _primaryBtn('Save', () async {
                    final catName = nameCtrl.text.trim();
                    if (catName.isEmpty) {
                      _snack('Category name is required',
                          color: Colors.redAccent);
                      return;
                    }
                    final subs = subCtrls
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    final token = await ApiLogin.getToken() ?? '';
                    final ok =
                    await ApiCategory.addCategoryWithSubcategories(
                      name: catName,
                      subcategories: subs,
                      token: token,
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      await _loadCategories();
                      setState(() {
                        _category = catName;
                        _subCategory = subs.isNotEmpty ? subs.first : null;
                      });
                      _snack('Category added', color: AppTheme.statusResolved);
                    } else {
                      _snack('Failed to add category', color: Colors.redAccent);
                    }
                  }),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD SUBCATEGORY SHEET
  // ─────────────────────────────────────────────────────────────────────────
  void _openAddSubCategorySheet() {
    if (_category == null) {
      _snack('Please select a category first', color: Colors.orange);
      return;
    }
    final List<TextEditingController> subCtrls = [TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.sidebarBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Subcategory',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text('under  $_category',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SUBCATEGORIES',
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600)),
                    _miniButton(
                      icon: Icons.add,
                      label: 'Add Row',
                      onTap: () =>
                          setSheet(() => subCtrls.add(TextEditingController())),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  subCtrls.length,
                      (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                          child: _sheetInput(
                              subCtrls[i], 'Subcategory ${i + 1}')),
                      if (subCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.redAccent, size: 18),
                          onPressed: () =>
                              setSheet(() => subCtrls.removeAt(i)),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _outlineBtn('Cancel', () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _primaryBtn('Save', () async {
                    final newSubs = subCtrls
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (newSubs.isEmpty) {
                      _snack('Enter at least one subcategory',
                          color: Colors.orange);
                      return;
                    }
                    final token = await ApiLogin.getToken() ?? '';
                    final ok =
                    await ApiCategory.addCategoryWithSubcategories(
                      name: _category!,
                      subcategories: newSubs,
                      token: token,
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      await _loadCategories();
                      _snack('Subcategory added',
                          color: AppTheme.statusResolved);
                    } else {
                      _snack('Failed to add subcategory',
                          color: Colors.redAccent);
                    }
                  }),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      child: Container(
        width: 940,
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
                // ── subject ───────────────────────────────
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

                // ── ticket type + category ────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TICKET TYPE ──
                    Row(
                      children: [
                        Expanded(
                          child: _fieldCard(
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── CATEGORY ──
                    Row(
                      children: [
                        Expanded(
                          child: _fieldCard(
                            label: 'CATEGORY',
                            required: true,
                            trailing: _addChip('Add', _openAddCategorySheet),
                            child: _loadingCats
                                ? _loadingRow()
                                : _styledDropdownWithAddNew(
                              value: _categoryMap.keys.contains(_category)
                                  ? _category
                                  : null,
                              items: _categoryMap.keys.toList(),
                              addLabel: 'Add New Category',
                              hint: 'Select category',
                              onChanged: (v) {
                                if (v == _kAddNew) {
                                  _openAddCategorySheet();
                                } else {
                                  _onCategoryChanged(v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── SUBCATEGORY ──
                    Row(
                      children: [
                        Expanded(
                          child: _fieldCard(
                            label: 'SUBCATEGORY',
                            required: true,
                            trailing: _addChip('Add', _openAddSubCategorySheet),
                            child: _loadingCats
                                ? _loadingRow()
                                : _styledDropdownWithAddNew(
                              value: (_categoryMap[_category] ?? [])
                                  .contains(_subCategory)
                                  ? _subCategory
                                  : null,
                              items: _categoryMap[_category] ?? [],
                              addLabel: 'Add New Subcategory',
                              hint: 'Select subcategory',
                              onChanged: (v) {
                                if (v == _kAddNew) {
                                  _openAddSubCategorySheet();
                                } else {
                                  setState(() => _subCategory = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── ENDORSER ──
                    Row(
                      children: [
                        Expanded(
                          child: _fieldCard(
                            label: 'ENDORSER',
                            child: _endorsers.isEmpty
                                ? _loadingRow()
                                : _styledDropdown(
                              value: _endorsers.contains(_endorser)
                                  ? _endorser
                                  : null,
                              items: _endorsers,
                              hint: 'Select endorser',
                              onChanged: (v) =>
                                  setState(() => _endorser = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── organization ──────────────────────────
                _fieldCard(
                  label: 'ORGANIZATION',
                  child: _styledDropdown(
                    value: _organization,
                    items: const [
                      'Bakawan Data Analytics'
                    ],
                    onChanged: (v) => setState(() => _organization = v!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ───────────────── RIGHT COLUMN ────────────────
          SizedBox(
            width: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── priority ─────────────────────────────
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
                              onTap: () =>
                                  setState(() => _priority = val),
                              child: Container(
                                margin: EdgeInsets.only(
                                    right: i < 3 ? 6 : 0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 9),
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

                // ── description ──────────────────────────
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
                        ],
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _descCtrl,
                        minLines: 12,
                        maxLines: null,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Describe the issue...',
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

                // ── attachment ───────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ATTACHMENT'),

                      const SizedBox(height: 10),

                      // ✅ SHOW FILE PREVIEW IF EXISTS
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
                              Text(
                                'Max file size: 25MB',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
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

                // ── buttons ──────────────────────────────
                Row(
                  children: [
                    Expanded(child: _outlineBtn('Clear', _reset)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _primaryBtn('Submit', _submit)),
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
    final isImage = ['jpg', 'jpeg', 'png'].contains(_file!.extension);
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(
                isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                    Border.all(color: Colors.redAccent.withOpacity(0.5)),
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
  // Widget helpers — all match status_sidebar visual language
  // ─────────────────────────────────────────────────────────────────────────

  /// Card wrapper identical to sidebar's _card()
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

  /// Card with icon header — wraps _card
  Widget _fieldCard({
    required String label,
    bool required = false,
    Widget? trailing,
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
                    style:
                    TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
              if (trailing != null) ...[
                const Spacer(),
                trailing,
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

  /// Plain text input matching sidebar's dark surface
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

  /// Dropdown that matches the dark sidebar surface — no extra container
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
          border: Border.all(
            color: AppTheme.border, // 👈 outline color
          ),
        ),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          dropdownColor: AppTheme.surface,
          isExpanded: true,
          underline: const SizedBox(),
          iconEnabledColor: AppTheme.textSecondary,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
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


  /// Dropdown with "+ Add New" sentinel as last item
  Widget _styledDropdownWithAddNew({
    required String? value,
    required List<String> items,
    required String addLabel,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.border,
          ),
        ),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          dropdownColor: AppTheme.surface,
          isExpanded: true,
          underline: const SizedBox(),
          iconEnabledColor: AppTheme.textSecondary,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          hint: Text(hint,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13)),
          items: [
            ...items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13)),
            )),
            DropdownMenuItem(
              value: _kAddNew,
              child: Row(children: [
                Icon(Icons.add_circle_outline,
                    size: 14, color: AppTheme.accent),
                const SizedBox(width: 6),
                Text(addLabel,
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontStyle: FontStyle.italic,
                        fontSize: 12)),
              ]),
            ),
          ],
          onChanged: onChanged,
        ),
      );


  /// Small green "+ Add" chip used next to field labels
  Widget _addChip(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border:
        Border.all(color: AppTheme.accent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 11, color: AppTheme.accent),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  /// Loading shimmer row
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
          style: TextStyle(
              color: AppTheme.textMuted, fontSize: 12)),
    ],
  );

  /// Sheet-specific input (slightly taller, uses AppTheme surface)
  Widget _sheetInput(TextEditingController ctrl, String hint) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: TextField(
      controller: ctrl,
      style:
      const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppTheme.textMuted, fontSize: 13),
        border: InputBorder.none,
        isDense: true,
      ),
    ),
  );

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700)),
  );

  Widget _miniButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13, color: AppTheme.accent),
        label: Text(label,
            style:
            TextStyle(fontSize: 11, color: AppTheme.accent)),
        style: TextButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      );

  Widget _primaryBtn(String text, VoidCallback onPressed) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(text),
      );

  Widget _outlineBtn(String text, VoidCallback onPressed) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(color: AppTheme.textSecondary)),
      );

  Color _priorityColor(int v) {
    switch (v) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.green;
      default: return Colors.grey;
    }
  }
}