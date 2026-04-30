import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_category.dart';
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

  // ── Snapshot of which sub is being edited ─────────────────────────────────
  // Prevents the dropdowns or _loadCategories from silently changing the
  // save target mid-edit.
  String? _editingCategory;
  String? _editingSubcategory;

  static const String addCategoryKey = '__add_category__';
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

    final prevCategory = preserveSelection ? _formCategory : null;
    final prevSubcategory = preserveSelection ? _formSubcategory : null;

    final token = await ApiLogin.getToken() ?? '';
    final raw = await ApiCategory.fetchCategories(token: token);

    debugPrint('>>> raw categories count: ${raw.length}');
    if (raw.isNotEmpty) {
      debugPrint('>>> first item keys: ${raw.first.keys.toList()}');
    }

    final Map<String, Map<String, dynamic>> built = {};

    for (final item in raw) {
      final categoryName =
          item['name']?.toString() ??
              item['Name']?.toString() ??
              '';

      final categoryId =
          item['category_id']?.toString() ??
              item['CategoryID']?.toString() ??
              item['ID']?.toString() ??
              '';

      final subsRaw =
          item['SubCategories'] ??
              item['sub_categories'] ??
              item['subcategories'] ??
              item['Subcategories'] ??
              [];

      List<Map<String, String>> subs = [];

      if (subsRaw is List) {
        subs = subsRaw.map((sub) {
          final s = Map<String, dynamic>.from(sub as Map);
          final subId =
              s['sub_category_id']?.toString() ??
                  s['SubCategoryID']?.toString() ??
                  s['subcategory_id']?.toString() ??
                  s['ID']?.toString() ??
                  '';
          final subName =
              s['name']?.toString() ?? s['Name']?.toString() ?? '';
          final subDesc =
              s['description']?.toString() ??
                  s['Description']?.toString() ??
                  '';
          debugPrint('>>>   sub id=$subId name=$subName desc=$subDesc');
          return {
            'name': subName,
            'description': subDesc,
            'subcategory_id': subId,
          };
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

    List<Map<String, String>> subs =
    newCategory != null
        ? List<Map<String, String>>.from(
      built[newCategory]?['subs'] ?? [],
    )
        : [];

    String? newSubcategory =
    (prevSubcategory != null &&
        subs.any((s) => s['name'] == prevSubcategory))
        ? prevSubcategory
        : (subs.isNotEmpty ? subs.first['name'] : null);

    setState(() {
      _categoryMap = built;
      _formCategory = newCategory;
      _formSubcategory = newSubcategory;
      _loadingCats = false;
    });

    // ── KEY FIX: never overwrite _descCtrl while the user is editing ──────
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
      _categoryMap[category]?['subs'] ?? [],
    );
    final match = subs.firstWhere(
          (s) => s['name'] == subName,
      orElse: () => {'name': '', 'description': '', 'subcategory_id': ''},
    );
    return match['description'] ?? '';
  }

  String _subId(String category, String subName) {
    final subs = List<Map<String, String>>.from(
      _categoryMap[category]?['subs'] ?? [],
    );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final token = await ApiLogin.getToken() ?? '';
              final success =
              await ApiCategory.addCategory(name: name, token: token);
              if (success) {
                Navigator.pop(ctx);
                setState(() {
                  _formCategory = name;
                  _formSubcategory = null;
                });
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final subName = nameCtrl.text.trim();
              if (subName.isEmpty) return;
              final token = await ApiLogin.getToken() ?? '';
              final categoryId = int.tryParse(
                _categoryMap[currentCategory]?['category_id'] ?? '',
              );
              if (categoryId == null) {
                _snack('Invalid category id', color: Colors.red);
                return;
              }
              final success = await ApiCategory.addSubcategory(
                categoryId: categoryId,
                name: subName,
                token: token,
              );
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

    // Snapshot the current target so Save always hits the right row
    _editingCategory = _formCategory;
    _editingSubcategory = _formSubcategory;

    // Load the DB description for THIS subcategory into the field
    _descCtrl.text = _subDescription(_formCategory!, _formSubcategory!);

    setState(() => _isEditing = true);
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    // Always save to the snapshotted sub, not whatever dropdown says now
    final targetCategory = _editingCategory;
    final targetSub = _editingSubcategory;

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

      debugPrint(
          '>>> SAVE: category=$targetCategory sub=$targetSub id=$subId');

      if (subId.isEmpty) {
        _snack('Could not find subcategory ID', color: Colors.red);
        setState(() => _saving = false);
        return;
      }

      final success = await ApiCategory.updateSubcategoryDescription(
        subcategoryId: int.parse(subId),
        description: _descCtrl.text.trim(),
        token: token,
      );

      if (success) {
        // Stay on the saved subcategory after reload
        setState(() {
          _formCategory = targetCategory;
          _formSubcategory = targetSub;
          _saving = false;
          _isEditing = false;
          _editingCategory = null;
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

  // ── CANCEL EDIT ────────────────────────────────────────────────────────────
  void _cancelEdit() {
    final cat = _editingCategory ?? _formCategory;
    final sub = _editingSubcategory ?? _formSubcategory;

    setState(() {
      _formCategory = cat;
      _formSubcategory = sub;
      _isEditing = false;
      _editingCategory = null;
      _editingSubcategory = null;
    });

    _descCtrl.text =
    (cat != null && sub != null) ? _subDescription(cat, sub) : '';
  }

  void _snack(String msg, {Color color = Colors.black87}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 420, child: _buildDetailsPanel()),
              const VerticalDivider(width: 1, color: AppTheme.border),
              Expanded(child: _buildDescriptionPanel()),
            ],
          ),
        ),
      ],
    );
  }

  // ── LEFT PANEL ─────────────────────────────────────────────────────────────
  Widget _buildDetailsPanel() {
    final subDesc = (!_isEditing &&
        _formCategory != null &&
        _formSubcategory != null)
        ? _subDescription(_formCategory!, _formSubcategory!)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _section('Template Details', [

            // ── Category ──────────────────────────────────────────────
            _formRow(
              label: 'Category *',
              child: _loadingCats
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : _inlineDropdown(
                value: _formCategory,
                items: [..._categoryMap.keys, addCategoryKey],
                hint: 'Select category',
                // Lock while editing so target can't drift
                onChanged: _isEditing
                    ? null
                    : (v) {
                  if (v == addCategoryKey) {
                    _addCategoryDialog();
                    return;
                  }
                  final subs = _subNames(v);
                  final firstSub =
                  subs.isNotEmpty ? subs.first : null;
                  setState(() {
                    _formCategory = v;
                    _formSubcategory = firstSub;
                  });
                  _descCtrl.text = (firstSub != null && v != null)
                      ? _subDescription(v, firstSub)
                      : '';
                },
              ),
            ),

            // ── Subcategory ───────────────────────────────────────────
            _formRow(
              label: 'Subcategory',
              child: _loadingCats
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : _inlineDropdown(
                value: _formSubcategory,
                items: [
                  ..._subNames(_formCategory),
                  addSubcategoryKey,
                ],
                hint: 'Select subcategory',
                // Lock while editing so target can't drift
                onChanged: _isEditing
                    ? null
                    : (v) {
                  if (v == addSubcategoryKey) {
                    _addSubcategoryDialog();
                    return;
                  }
                  setState(() => _formSubcategory = v);
                  if (v != null && _formCategory != null) {
                    // Show this sub's DB description
                    _descCtrl.text =
                        _subDescription(_formCategory!, v);
                  }
                },
              ),
            ),

            // ── Existing description chip (view mode only) ─────────────
            if (subDesc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subDesc,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Editing indicator ─────────────────────────────────────
            if (_isEditing && _editingSubcategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Editing: "$_editingSubcategory"',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  // ── RIGHT PANEL ────────────────────────────────────────────────────────────
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
                  hintText: 'Enter description for this subcategory...',
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

          Row(
            children: [
              if (_isEditing) ...[
                OutlinedButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                _saving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
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
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
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