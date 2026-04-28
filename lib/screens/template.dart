import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_category.dart';
import '../data/light_theme.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class TicketTemplate {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final String description; // pre-filled but editable when filing

  TicketTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.description,
  });

  TicketTemplate copyWith({
    String? name,
    String? category,
    String? subcategory,
    String? description,
  }) =>
      TicketTemplate(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        subcategory: subcategory ?? this.subcategory,
        description: description ?? this.description,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  // ── template list state ───────────────────────────────────────────────────
  final List<TicketTemplate> _templates = [
    // Seed with sample data — replace with your API fetch
    TicketTemplate(
      id: '1',
      name: 'Password Reset',
      category: 'Account',
      subcategory: 'Access',
      description:
      'Issue type: Password Reset\nSteps:\n1. Cannot log in\n2. Forgot password\n\nExpected: Reset link sent to email\nActual: N/A',
    ),
    TicketTemplate(
      id: '2',
      name: 'Software Installation',
      category: 'Software',
      subcategory: 'Installation',
      description:
      'Issue type: Software Installation\nSoftware name:\nVersion:\n\nSteps to reproduce:\n1.\n\nExpected result:\nActual result:',
    ),
  ];

  String _search = '';
  TicketTemplate? _selected; // null = "Add New" mode

  // ── category state ────────────────────────────────────────────────────────
  Map<String, List<String>> _categoryMap = {};
  bool _loadingCats = true;

  // ── form controllers ──────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _formCategory;
  String? _formSubcategory;
  bool _saving = false;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── loaders ───────────────────────────────────────────────────────────────
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
      _formCategory = cats.isNotEmpty ? cats.first : null;
      final subs =
      _formCategory != null ? (built[_formCategory] ?? []) : <String>[];
      _formSubcategory = subs.isNotEmpty ? subs.first : null;
      _loadingCats = false;
    });
  }

  // ── select a template to edit ─────────────────────────────────────────────
  void _selectTemplate(TicketTemplate t) {
    setState(() {
      _selected = t;
      _nameCtrl.text = t.name;
      _descCtrl.text = t.description;
      _formCategory = _categoryMap.keys.contains(t.category)
          ? t.category
          : (_categoryMap.keys.isNotEmpty ? _categoryMap.keys.first : null);
      final subs = _categoryMap[_formCategory] ?? [];
      _formSubcategory = subs.contains(t.subcategory)
          ? t.subcategory
          : (subs.isNotEmpty ? subs.first : null);
    });
  }

  // ── clear form (add-new mode) ─────────────────────────────────────────────
  void _clearForm() {
    final cats = _categoryMap.keys.toList();
    setState(() {
      _selected = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _formCategory = cats.isNotEmpty ? cats.first : null;
      final subs = _formCategory != null
          ? (_categoryMap[_formCategory] ?? [])
          : <String>[];
      _formSubcategory = subs.isNotEmpty ? subs.first : null;
    });
  }

  // ── save / update ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_formCategory == null) {
      _snack('Please select a category', color: Colors.redAccent);
      return;
    }
    setState(() => _saving = true);

    // TODO: replace with your actual API call
    // e.g. await ApiTemplate.saveTemplate(...)
    await Future.delayed(const Duration(milliseconds: 500));

    final isEdit = _selected != null;
    final newTemplate = TicketTemplate(
      id: _selected?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      category: _formCategory ?? '',
      subcategory: _formSubcategory ?? '',
      description: _descCtrl.text.trim(),
    );

    setState(() {
      if (isEdit) {
        final idx = _templates.indexWhere((t) => t.id == _selected!.id);
        if (idx >= 0) _templates[idx] = newTemplate;
      } else {
        _templates.add(newTemplate);
      }
      _selected = newTemplate;
      _saving = false;
    });

    _snack(
      isEdit ? 'Template updated' : 'Template saved',
      color: AppTheme.statusResolved,
    );
  }

  // ── delete ────────────────────────────────────────────────────────────────
  Future<void> _delete(TicketTemplate t) async {
    final confirm = await _showDeleteConfirm(t.name);
    if (!confirm) return;

    // TODO: replace with your actual API call
    // e.g. await ApiTemplate.deleteTemplate(t.id)

    setState(() {
      _templates.removeWhere((x) => x.id == t.id);
      if (_selected?.id == t.id) _clearForm();
    });
    _snack('Template deleted', color: Colors.redAccent);
  }

  Future<bool> _showDeleteConfirm(String name) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Delete Template',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Delete "$name"? This cannot be undone.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _outlineBtn(
                          'Cancel', () => Navigator.pop(ctx, false))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
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
    return Column(
      children: [
        // ── Page Header — matches SettingsScreen ──────────────────────────
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppTheme.sidebarBg,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: const Row(
            children: [
              Text(
                'Templates',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Template Details
              SizedBox(width: 420, child: _buildDetailsPanel()),
              // Divider
              const VerticalDivider(width: 1, color: AppTheme.border),
              // RIGHT: Description
              Expanded(child: _buildDescriptionPanel()),
            ],
          ),
        ),
      ],
    );
  }

  // ── LEFT PANEL: Template Details ──────────────────────────────────────────
  Widget _buildDetailsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Template Details section — Settings-style card
          _section('Template Details', [
            _formRow(
              label: 'Category *',
              child: _loadingCats
                  ? _loadingRow()
                  : _inlineDropdown(
                value: _categoryMap.keys.contains(_formCategory)
                    ? _formCategory
                    : null,
                items: _categoryMap.keys.toList(),
                hint: 'Select category',
                onChanged: (v) {
                  if (v == null) return;
                  final subs = _categoryMap[v] ?? [];
                  setState(() {
                    _formCategory = v;
                    _formSubcategory =
                    subs.isNotEmpty ? subs.first : null;
                  });
                },
              ),
            ),
            _formRow(
              label: 'Subcategory',
              child: _loadingCats
                  ? _loadingRow()
                  : _inlineDropdown(
                value: (_categoryMap[_formCategory] ?? [])
                    .contains(_formSubcategory)
                    ? _formSubcategory
                    : null,
                items: _categoryMap[_formCategory] ?? [],
                hint: 'Select subcategory',
                onChanged: (v) =>
                    setState(() => _formSubcategory = v),
              ),
            ),
          ]),

        ],
      ),
    );
  }

  // ── RIGHT PANEL: Description ───────────────────────────────────────────────
  Widget _buildDescriptionPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          _section('Description', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pre-filled when filing — the person creating the ticket can still edit it.',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.sidebarBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      minLines: 10,
                      maxLines: null,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText:
                        'Write the default description here...\n\nExample:\nIssue type:\nSteps to reproduce:\n1.\n\nExpected result:\nActual result:',
                        hintStyle: TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Buttons
          Row(children: [
            _outlineBtn('Clear', _clearForm),
            const SizedBox(width: 8),
            _saving
                ? const SizedBox(
              width: 140,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent),
                ),
              ),
            )
                : ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _selected == null
                    ? 'Save Template'
                    : 'Update Template',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widget helpers — match Settings screen visual language
  // ─────────────────────────────────────────────────────────────────────────

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _formRow({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border:
        Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ),
        Expanded(child: child),
      ]),
    );
  }

  Widget _inlineInput({
    required TextEditingController controller,
    String hint = '',
  }) =>
      TextField(
        controller: controller,
        style:
        const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppTheme.textMuted, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );

  Widget _inlineDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButton<String>(
        value: items.contains(value) ? value : null,
        dropdownColor: AppTheme.surface,
        isExpanded: true,
        underline: const SizedBox(),
        iconEnabledColor: AppTheme.textSecondary,
        style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 13),
        hint: Text(hint,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 13)),
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13)),
        ))
            .toList(),
        onChanged: onChanged,
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
          style:
          TextStyle(color: AppTheme.textMuted, fontSize: 12)),
    ],
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
            style: const TextStyle(
                color: AppTheme.textSecondary)),
      );
}