import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_category.dart';
import '../core/services/api_insti_&_postition.dart';
import '../data/light_theme.dart';

// ── Data model ───────────────────────────────────────────────────────────────
class TicketTemplate {
  final String id;
  final String category;
  final String subcategory;
  final String description;

  TicketTemplate({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.description,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  Map<String, Map<String, dynamic>> _categoryMap = {};
  bool _loadingCats = true;

  final _descCtrl = TextEditingController();

  String? _formCategory;
  String? _formSubcategory;
  bool _saving = false;
  bool _isEditing = false;

  // ── Left-panel mode ────────────────────────────────────────────────────────
  String _leftMode = 'Template';

  // ── Modification sub-section: 'Institution' or 'Position' ─────────────────
  String _modSection = 'Institution';

  // ── Snapshot of which sub is being edited ─────────────────────────────────
  String? _editingCategory;
  String? _editingSubcategory;

  static const String addCategoryKey    = '__add_category__';
  static const String addSubcategoryKey = '__add_subcategory__';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  // ── LOAD CATEGORIES ────────────────────────────────────────────────────────
  Future<void> _loadCategories({bool preserveSelection = true}) async {
    setState(() => _loadingCats = true);

    final prevCategory    = preserveSelection ? _formCategory    : null;
    final prevSubcategory = preserveSelection ? _formSubcategory : null;

    final token = await ApiLogin.getToken() ?? '';
    final raw   = await ApiCategory.fetchCategories(token: token);

    final Map<String, Map<String, dynamic>> built = {};

    for (final item in raw) {
      final categoryName =
          item['name']?.toString() ?? item['Name']?.toString() ?? '';
      final categoryId =
          item['category_id']?.toString() ??
              item['CategoryID']?.toString()   ??
              item['ID']?.toString()           ?? '';

      final subsRaw =
          item['SubCategories']  ??
              item['sub_categories'] ??
              item['subcategories']  ??
              item['Subcategories']  ??
              [];

      List<Map<String, String>> subs = [];
      if (subsRaw is List) {
        subs = subsRaw.map((sub) {
          final s = Map<String, dynamic>.from(sub as Map);
          final subId =
              s['sub_category_id']?.toString() ??
                  s['SubCategoryID']?.toString()   ??
                  s['subcategory_id']?.toString()  ??
                  s['ID']?.toString()              ?? '';
          final subName  = s['name']?.toString()        ?? s['Name']?.toString()        ?? '';
          final subDesc  = s['description']?.toString() ?? s['Description']?.toString() ?? '';
          return {'name': subName, 'description': subDesc, 'subcategory_id': subId};
        }).toList();
      }

      if (categoryName.isNotEmpty) {
        built[categoryName] = {'category_id': categoryId, 'subs': subs};
      }
    }

    final cats = built.keys.toList();
    String? newCategory =
    (prevCategory != null && built.containsKey(prevCategory))
        ? prevCategory
        : (cats.isNotEmpty ? cats.first : null);

    List<Map<String, String>> subs = newCategory != null
        ? List<Map<String, String>>.from(built[newCategory]?['subs'] ?? [])
        : [];

    String? newSubcategory =
    (prevSubcategory != null && subs.any((s) => s['name'] == prevSubcategory))
        ? prevSubcategory
        : (subs.isNotEmpty ? subs.first['name'] : null);

    setState(() {
      _categoryMap      = built;
      _formCategory     = newCategory;
      _formSubcategory  = newSubcategory;
      _loadingCats      = false;
    });

    if (!_isEditing && newCategory != null && newSubcategory != null) {
      _descCtrl.text = _subDescription(newCategory, newSubcategory);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  List<String> _subNames(String? category) {
    if (category == null) return [];
    return (_categoryMap[category]?['subs'] as List? ?? [])
        .map((s) => (s as Map<String, String>)['name']!)
        .toList();
  }

  String _subDescription(String category, String subName) {
    final subs = List<Map<String, String>>.from(
        _categoryMap[category]?['subs'] ?? []);
    final match = subs.firstWhere(
          (s) => s['name'] == subName,
      orElse: () => {'name': '', 'description': '', 'subcategory_id': ''},
    );
    return match['description'] ?? '';
  }

  String _subId(String category, String subName) {
    final subs = List<Map<String, String>>.from(
        _categoryMap[category]?['subs'] ?? []);
    final match = subs.firstWhere(
          (s) => s['name'] == subName,
      orElse: () => {'name': '', 'description': '', 'subcategory_id': ''},
    );
    return match['subcategory_id'] ?? '';
  }

  // ── ADD CATEGORY ───────────────────────────────────────────────────────────
  Future<void> _addCategoryDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final token   = await ApiLogin.getToken() ?? '';
              final success = await ApiCategory.addCategory(name: name, token: token);
              if (success) {
                Navigator.pop(ctx);
                setState(() { _formCategory = name; _formSubcategory = null; });
                _snack('Category added');
                await _loadCategories();
              } else {
                _snack('Failed to add category', color: Colors.red);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  // ── ADD SUBCATEGORY ────────────────────────────────────────────────────────
  Future<void> _addSubcategoryDialog() async {
    final currentCategory = _formCategory;
    if (currentCategory == null) {
      _snack('Please select a category first', color: Colors.orange);
      return;
    }
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Subcategory to "$currentCategory"'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Subcategory name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final subName = nameCtrl.text.trim();
              if (subName.isEmpty) return;
              final token      = await ApiLogin.getToken() ?? '';
              final categoryId = int.tryParse(
                  _categoryMap[currentCategory]?['category_id'] ?? '');
              if (categoryId == null) {
                _snack('Invalid category id', color: Colors.red);
                return;
              }
              final success = await ApiCategory.addSubcategory(
                  categoryId: categoryId, name: subName, token: token);
              if (success) {
                Navigator.pop(ctx);
                setState(() => _formSubcategory = subName);
                _snack('Subcategory added');
                await _loadCategories();
                if (!_isEditing) _descCtrl.text = '';
              } else {
                _snack('Failed to add subcategory', color: Colors.red);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
  }

  // ── ENTER EDIT MODE ────────────────────────────────────────────────────────
  void _startEditing() {
    if (_formCategory == null || _formSubcategory == null) return;
    _editingCategory    = _formCategory;
    _editingSubcategory = _formSubcategory;
    _descCtrl.text = _subDescription(_formCategory!, _formSubcategory!);
    setState(() => _isEditing = true);
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final targetCategory = _editingCategory;
    final targetSub      = _editingSubcategory;

    if (targetCategory == null || targetSub == null) {
      _snack('No subcategory selected', color: Colors.redAccent);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Description cannot be empty', color: Colors.redAccent);
      return;
    }

    setState(() => _saving = true);
    try {
      final token = await ApiLogin.getToken() ?? '';
      final subId = _subId(targetCategory, targetSub);
      if (subId.isEmpty) {
        _snack('Could not find subcategory ID', color: Colors.red);
        setState(() => _saving = false);
        return;
      }
      final success = await ApiCategory.updateSubcategoryDescription(
        subcategoryId: int.parse(subId),
        description:   _descCtrl.text.trim(),
        token:         token,
      );
      if (success) {
        setState(() {
          _formCategory       = targetCategory;
          _formSubcategory    = targetSub;
          _saving             = false;
          _isEditing          = false;
          _editingCategory    = null;
          _editingSubcategory = null;
        });
        _snack('Saved description for "$targetSub"');
        await _loadCategories(preserveSelection: true);
      } else {
        _snack('Failed to save description', color: Colors.red);
        setState(() => _saving = false);
      }
    } catch (e) {
      setState(() => _saving = false);
      _snack('Error: $e', color: Colors.red);
    }
  }

  // ── EDIT / DELETE CATEGORY ────────────────────────────────────────────────
  Future<void> _editCategoryDialog() async {
    final current = _formCategory;
    if (current == null) return;
    final ctrl = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'New category name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              final token = await ApiLogin.getToken() ?? '';
              final id    = int.tryParse(_categoryMap[current]?['category_id'] ?? '');
              if (id == null) return;
              final success = await ApiCategory.updateCategory(
                  categoryId: id, newName: newName, token: token);
              if (success) {
                Navigator.pop(ctx);
                _snack('Category updated');
                await _loadCategories(preserveSelection: false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _deleteCategory() async {
    final current = _formCategory;
    if (current == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "$current"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token   = await ApiLogin.getToken() ?? '';
    final id      = int.tryParse(_categoryMap[current]?['category_id'] ?? '');
    if (id == null) return;
    final success = await ApiCategory.deleteCategory(categoryId: id, token: token);
    if (success) {
      _snack('Category deleted');
      await _loadCategories(preserveSelection: false);
    }
  }

  // ── EDIT / DELETE SUBCATEGORY ─────────────────────────────────────────────
  Future<void> _editSubcategoryDialog() async {
    final cat = _formCategory;
    final sub = _formSubcategory;
    if (cat == null || sub == null) return;
    final ctrl = TextEditingController(text: sub);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subcategory'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'New subcategory name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              final token = await ApiLogin.getToken() ?? '';
              final subId = int.tryParse(_subId(cat, sub));
              if (subId == null) return;
              final success = await ApiCategory.updateSubcategoryName(
                  subcategoryId: subId, name: newName, token: token);
              if (success) {
                Navigator.pop(ctx);
                _snack('Subcategory updated');
                await _loadCategories();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _deleteSubcategory() async {
    final cat = _formCategory;
    final sub = _formSubcategory;
    if (cat == null || sub == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content: Text('Delete "$sub"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await ApiLogin.getToken() ?? '';
    final subId = int.tryParse(_subId(cat, sub));
    if (subId == null) return;
    final success =
    await ApiCategory.deleteSubcategory(subcategoryId: subId, token: token);
    if (success) {
      _snack('Subcategory deleted');
      await _loadCategories();
    }
  }

  // ── CANCEL EDIT ────────────────────────────────────────────────────────────
  void _cancelEdit() {
    final cat = _editingCategory ?? _formCategory;
    final sub = _editingSubcategory ?? _formSubcategory;
    setState(() {
      _formCategory       = cat;
      _formSubcategory    = sub;
      _isEditing          = false;
      _editingCategory    = null;
      _editingSubcategory = null;
    });
    _descCtrl.text =
    (cat != null && sub != null) ? _subDescription(cat, sub) : '';
  }

  void _snack(String msg, {Color color = Colors.black87}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top bar ──────────────────────────────────────────────────────────
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
                'Configuration',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth < 700
                      ? 700
                      : constraints.maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 420, child: _buildLeftPanel()),
                      const VerticalDivider(width: 1, color: AppTheme.border),
                      Expanded(child: _buildRightPanel()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Mode dropdown ──────────────────────────────────────────────────────────
  Widget _modeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.surface,
      ),
      child: DropdownButton<String>(
        value: _leftMode,
        isExpanded: true,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'Template',     child: Text('Template')),
          DropdownMenuItem(value: 'Company Information', child: Text('Company Information')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _leftMode = value);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LEFT PANEL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _modeDropdown(),
          ),

          // ── Template mode ──────────────────────────────────────────────────
          if (_leftMode == 'Template') ...[
            _section('Template Details', [
              _formRow(
                label: 'Category *',
                child: _loadingCats
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                  children: [
                    Expanded(
                      child: _inlineDropdown(
                        value: _formCategory,
                        items: [..._categoryMap.keys, addCategoryKey],
                        hint: 'Select category',
                        onChanged: _isEditing
                            ? null
                            : (v) {
                          if (v == addCategoryKey) {
                            _addCategoryDialog();
                            return;
                          }
                          final subs     = _subNames(v);
                          final firstSub = subs.isNotEmpty ? subs.first : null;
                          setState(() {
                            _formCategory    = v;
                            _formSubcategory = firstSub;
                          });
                          _descCtrl.text =
                          (firstSub != null && v != null)
                              ? _subDescription(v, firstSub)
                              : '';
                        },
                      ),
                    ),
                    if (_formCategory != null && !_isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
                        tooltip: 'Rename category',
                        visualDensity: VisualDensity.compact,
                        onPressed: _editCategoryDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        tooltip: 'Delete category',
                        visualDensity: VisualDensity.compact,
                        onPressed: _deleteCategory,
                      ),
                    ],
                  ],
                ),
              ),
              _formRow(
                label: 'Subcategory',
                child: _loadingCats
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                  children: [
                    Expanded(
                      child: _inlineDropdown(
                        value: _formSubcategory,
                        items: [..._subNames(_formCategory), addSubcategoryKey],
                        hint: 'Select subcategory',
                        onChanged: _isEditing
                            ? null
                            : (v) {
                          if (v == addSubcategoryKey) {
                            _addSubcategoryDialog();
                            return;
                          }
                          setState(() => _formSubcategory = v);
                          if (v != null && _formCategory != null) {
                            _descCtrl.text =
                                _subDescription(_formCategory!, v);
                          }
                        },
                      ),
                    ),
                    if (_formSubcategory != null && !_isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
                        tooltip: 'Rename subcategory',
                        visualDensity: VisualDensity.compact,
                        onPressed: _editSubcategoryDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        tooltip: 'Delete subcategory',
                        visualDensity: VisualDensity.compact,
                        onPressed: _deleteSubcategory,
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ]

          // ── Modification mode ──────────────────────────────────────────────
          else if (_leftMode == 'Company Information') ...[
            _section('Company Information', [
              // Institution tile
              _modTile(
                icon: Icons.business,
                label: 'Institution',
                selected: _modSection == 'Institution',
                onTap: () => setState(() => _modSection = 'Institution'),
              ),
              const Divider(height: 1),
              // Position tile
              _modTile(
                icon: Icons.badge_outlined,
                label: 'Position',
                selected: _modSection == 'Position',
                onTap: () => setState(() => _modSection = 'Position'),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _modTile({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppTheme.sidebarBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppTheme.textPrimary : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? AppTheme.textPrimary
                    : const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RIGHT PANEL — switches based on _leftMode
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRightPanel() {
    if (_leftMode == 'Template') {
      return _buildDescriptionPanel();
    }
    // Modification mode — pass section key so the panel reloads when switching
    return _ModPanelContent(
      key: ValueKey(_modSection),
      isInstitution: _modSection == 'Institution',
      snack: _snack,
    );
  }

  // ── ORIGINAL right panel (Template description) ────────────────────────────
  Widget _buildDescriptionPanel() {
    final panelTitle = (_isEditing && _editingSubcategory != null)
        ? 'Description — $_editingSubcategory'
        : 'Description';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(panelTitle, [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _isEditing
                  ? TextField(
                controller: _descCtrl,
                minLines: 10,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText:
                  'Enter description for this subcategory...',
                  border: InputBorder.none,
                ),
              )
                  : Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                child: Text(
                  _descCtrl.text.isNotEmpty
                      ? _descCtrl.text
                      : 'Select a subcategory to view its description.',
                  style: TextStyle(
                    color: _descCtrl.text.isNotEmpty
                        ? AppTheme.textPrimary
                        : Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_isEditing) ...[
                    OutlinedButton(
                        onPressed: _cancelEdit,
                        child: const Text('Cancel')),
                    _saving
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed:
                      _formSubcategory != null ? _startEditing : null,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Description'),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── SECTION / FORM-ROW / DROPDOWN helpers ──────────────────────────────────
  Widget _section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...children,
      ],
    ),
  );

  Widget _formRow({required String label, required Widget child}) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(child: child),
      ],
    ),
  );

  Widget _inlineDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) =>
      DropdownButton<String>(
        value: items.contains(value) ? value : null,
        isExpanded: true,
        hint: Text(hint),
        disabledHint: value != null ? Text(value) : Text(hint),
        items: items.map((e) {
          final isAdd = e == addCategoryKey || e == addSubcategoryKey;
          return DropdownMenuItem(
            value: e,
            child: Text(
              isAdd ? '+ Add New' : e,
              style: TextStyle(
                color: isAdd ? Colors.green : AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  _ModPanelContent — loads institutions OR positions from the API
//  • isInstitution=true  → calls ApiInstitutionPosition.getInstitutions / create / update
//  • isInstitution=false → calls ApiInstitutionPosition.getPositions / create / update
// ══════════════════════════════════════════════════════════════════════════════
class _ModPanelContent extends StatefulWidget {
  const _ModPanelContent({
    super.key,
    required this.isInstitution,
    required this.snack,
  });

  final bool isInstitution;
  final void Function(String, {Color color}) snack;

  @override
  State<_ModPanelContent> createState() => _ModPanelContentState();
}

class _ModPanelContentState extends State<_ModPanelContent> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> _institutions = [];
  int? _selectedInstitutionId;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  String get _title => widget.isInstitution ? 'Institutions' : 'Positions';
  IconData get _icon =>
      widget.isInstitution ? Icons.business : Icons.badge_outlined;

  @override
  void initState() {
    super.initState();

    if (!widget.isInstitution) {
      _loadInstitutions();
    }

    _loadItems();
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    try {
      final data = await ApiInstitutionPosition.getInstitutions();

      setState(() {
        _institutions = data;

        if (_institutions.isNotEmpty) {
          _selectedInstitutionId =
              _institutions.first['institution_id'] ??
                  _institutions.first['id'];
        }
      });

      await _loadItems();
    } catch (_) {
      widget.snack(
        'Failed to load institutions',
        color: Colors.red,
      );
    }
  }

  // ── Load from API ──────────────────────────────────────────────────────────
  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final data = widget.isInstitution
          ? await ApiInstitutionPosition.getInstitutions()
          : await ApiInstitutionPosition.getPositions();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      widget.snack('Failed to load $_title', color: Colors.red);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var data = _items;

    if (!widget.isInstitution && _selectedInstitutionId != null) {
      data = data.where((e) {
        return e['institution_id'] == _selectedInstitutionId;
      }).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();

      data = data.where((e) {
        return (e['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(q);
      }).toList();
    }

    return data;
  }

  // ── Add dialog ─────────────────────────────────────────────────────────────
  Future<void> _showAddDialog() async {
    final ctrl = TextEditingController();

    if (widget.isInstitution) {
      // ── Add Institution ──────────────────────────────────────────────────
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Institution'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Institution name…'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                final success =
                await ApiInstitutionPosition.createInstitution(name: name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  widget.snack('Added "$name"');
                  await _loadItems();
                } else {
                  widget.snack('Failed to add "$name"', color: Colors.red);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } else {
      // ── Add Position — must pick an institution first ─────────────────────
      List<Map<String, dynamic>> institutions = [];
      int? selectedInstitutionId;

      try {
        institutions = await ApiInstitutionPosition.getInstitutions();
        institutions = institutions
            .where((i) => (i['status']?.toString() ?? 'active') == 'active')
            .toList();
      } catch (_) {
        widget.snack('Failed to load institutions', color: Colors.red);
        return;
      }

      if (institutions.isEmpty) {
        widget.snack('No active institutions found. Add one first.',
            color: Colors.orange);
        return;
      }

      selectedInstitutionId =
      (institutions.first['institution_id'] ?? institutions.first['id'])
      as int?;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: const Text('Add Position'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration:
                  const InputDecoration(hintText: 'Position name…'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedInstitutionId,
                  decoration:
                  const InputDecoration(labelText: 'Institution *'),
                  items: institutions.map((inst) {
                    final id = (inst['institution_id'] ?? inst['id']) as int?;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(inst['name']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setStateDialog(() => selectedInstitutionId = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty || selectedInstitutionId == null) return;
                  final success = await ApiInstitutionPosition.createPosition(
                      name: name, institutionId: selectedInstitutionId!);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    widget.snack('Added "$name"');
                    await _loadItems();
                  } else {
                    widget.snack('Failed to add "$name"', color: Colors.red);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
    }

    ctrl.dispose();
  }

  // ── Edit dialog — renames institution (no rename endpoint) or position name ──
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    // Institutions have no rename endpoint on the backend — only status update.
    // Show a message for institutions; allow rename only for positions.
    if (widget.isInstitution) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rename is not supported for institutions. Use disable/enable to change status.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final ctrl = TextEditingController(text: item['name']?.toString() ?? '');
    final id   = (item['position_id'] ?? item['id']) as int? ?? 0;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Position'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              // PUT /position-name/update/:id  — name only
              final success = await ApiInstitutionPosition.updatePositionName(
                  id: id, name: newName);
              if (context.mounted) Navigator.pop(ctx);
              if (success) {
                widget.snack('Renamed to "$newName"');
                await _loadItems();
              } else {
                widget.snack('Rename failed', color: Colors.red);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  // ── Toggle status (active ↔ inactive) ─────────────────────────────────────
  Future<void> _confirmToggle(Map<String, dynamic> item) async {
    final name      = item['name']?.toString() ?? '';
    final isActive  = (item['status']?.toString() ?? 'active') == 'active';
    final action    = isActive ? 'Disable' : 'Enable';
    final newStatus = isActive ? 'inactive' : 'active';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action item'),
        content: Text('$action "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.red : Colors.green),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true) return;

    bool success;
    if (widget.isInstitution) {
      // PUT /institution/update/:id — status only
      final id = (item['institution_id'] ?? item['id']) as int? ?? 0;
      success = await ApiInstitutionPosition.updateInstitutionStatus(
          id: id, status: newStatus);
    } else {
      // No status update route registered for positions yet —
      // using updatePositionName as a no-op rename to keep name unchanged,
      // until a position-status route is added to the backend.
      // TODO: add userRoutes.Put("/position/update/:id", controllers.UpdatePositionStatus)
      // then call ApiInstitutionPosition.updatePositionStatus(id, newStatus) here.
      widget.snack('Position status update not yet available', color: Colors.orange);
      return;
    }

    if (success) {
      widget.snack('${isActive ? 'Disabled' : 'Enabled'} "$name"');
      await _loadItems();
    } else {
      widget.snack('Action failed', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Row(
            children: [
              Icon(_icon, size: 20, color: AppTheme.textPrimary),
              const SizedBox(width: 8),
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Text(
                  '${_items.length} total',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Refresh',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _loading ? null : _loadItems,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.refresh, size: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Search ─────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search ${_title.toLowerCase()}…',
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              )
                  : null,
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (!widget.isInstitution) ...[
            DropdownButtonFormField<int>(
              value: _selectedInstitutionId,
              decoration: const InputDecoration(
                labelText: 'Institution',
                border: OutlineInputBorder(),
              ),
              items: _institutions.map((inst) {
                final id =
                (inst['institution_id'] ?? inst['id']) as int?;

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(inst['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInstitutionId = value;
                });
              },
            ),
            const SizedBox(height: 12),
          ],

          // ── Add button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                  'Add ${widget.isInstitution ? 'Institution' : 'Position'}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Scrollable List ────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(
              child: Text('No results.',
                  style: TextStyle(color: Colors.grey)),
            )
                : Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.border),
                itemBuilder: (context, index) {
                  final item     = filtered[index];
                  final name     = item['name']?.toString() ?? '';
                  final isActive =
                      (item['status']?.toString() ?? 'active') == 'active';

                  return ListTile(
                    dense: true,
                    title: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: Colors.blueGrey),
                          tooltip: 'Edit',
                          onPressed: () => _showEditDialog(item),
                        ),
                        IconButton(
                          icon: Icon(
                            isActive
                                ? Icons.block
                                : Icons.check_circle_outline,
                            size: 16,
                            color: isActive
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                          tooltip: isActive ? 'Disable' : 'Enable',
                          onPressed: () => _confirmToggle(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}