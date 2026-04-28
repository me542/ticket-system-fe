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
  Map<String, List<Map<String, String>>> _categoryMap = {};
  bool _loadingCats = true;

  final _descCtrl = TextEditingController();

  String? _formCategory;
  String? _formSubcategory;
  bool _saving = false;

  bool _isEditing = false;
  TicketTemplate? _savedTemplate;

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
  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);

    final prevCategory = _formCategory;
    final prevSubcategory = _formSubcategory;

    final token = await ApiLogin.getToken() ?? '';
    final raw = await ApiCategory.fetchCategories(token: token);

    final Map<String, List<Map<String, String>>> built = {};

    for (final item in raw) {
      final categoryName = item['name']?.toString() ?? '';

      List<Map<String, String>> subs = [];

      if (item['subcategories'] is List) {
        subs = (item['subcategories'] as List)
            .map((sub) {
          if (sub is Map) {
            return {
              'name': sub['name']?.toString() ?? '',
              'description': sub['description']?.toString() ?? '',
              'subcategory_id': sub['subcategory_id']?.toString() ?? '',
            };
          }
          return {
            'name': sub.toString(),
            'description': '',
            'subcategory_id': '',
          };
        })
            .where((e) => e['name']!.isNotEmpty)
            .toList();
      }

      if (categoryName.isNotEmpty) {
        built[categoryName] = subs;
      }
    }

    final cats = built.keys.toList();

    String? newCategory =
    (prevCategory != null && built.containsKey(prevCategory))
        ? prevCategory
        : (cats.isNotEmpty ? cats.first : null);

    List<Map<String, String>> subs =
    newCategory != null ? built[newCategory] ?? [] : [];

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

    if (newCategory != null && newSubcategory != null && !_isEditing) {
      _descCtrl.text = _subDescription(newCategory, newSubcategory);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  List<String> _subNames(String? category) {
    if (category == null) return [];
    return (_categoryMap[category] ?? []).map((s) => s['name']!).toList();
  }

  String _subDescription(String category, String subName) {
    final subs = _categoryMap[category] ?? [];
    final match = subs.firstWhere(
          (s) => s['name'] == subName,
      orElse: () => {'name': '', 'description': '', 'subcategory_id': ''},
    );
    return match['description'] ?? '';
  }

  String _subId(String category, String subName) {
    final subs = _categoryMap[category] ?? [];
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
              debugPrint('>>> addCategory name: "$name"');
              if (name.isEmpty) return;

              final token = await ApiLogin.getToken() ?? '';
              debugPrint('>>> addCategory token empty: ${token.isEmpty}');

              final success = await ApiCategory.addCategory(
                name: name,
                token: token,
              );


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
    // ✅ Capture category at dialog open time — not inside builder
    final currentCategory = _formCategory;

    if (currentCategory == null) {
      _snack('Please select a category first', color: Colors.orange);
      return;
    }

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Subcategory to "$currentCategory"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration:
              const InputDecoration(hintText: 'Subcategory name'),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint('>>> ADD SUBCATEGORY BUTTON PRESSED');
              debugPrint('>>> currentCategory: "$currentCategory"');

              final subName = nameCtrl.text.trim();
              final subDesc = descCtrl.text.trim();

              debugPrint('>>> subName: "$subName"');
              debugPrint('>>> subDesc: "$subDesc"');

              if (subName.isEmpty) {
                debugPrint('>>> EARLY RETURN — subName is empty');
                return;
              }

              final token = await ApiLogin.getToken() ?? '';
              debugPrint('>>> token empty: ${token.isEmpty}');

              // ✅ Only send the NEW subcategory
              final categoryId = int.tryParse(
                _categoryMap[currentCategory]?[0]['subcategory_id'] ?? '',
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
                if (!_isEditing) {
                  _descCtrl.text = subDesc;
                }
              } else {
                _snack('Failed to add subcategory', color: Colors.red);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    // ✅ Dispose after dialog closes
    nameCtrl.dispose();
    descCtrl.dispose();
  }

  // ── ENTER EDIT MODE ────────────────────────────────────────────────────────
  void _startEditing() {
    if (_savedTemplate != null) {
      _descCtrl.text = _savedTemplate!.description;
      setState(() {
        _formCategory = _savedTemplate!.category;
        _formSubcategory = _savedTemplate!.subcategory;
        _isEditing = true;
      });
    } else {
      setState(() => _isEditing = true);
    }
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_formCategory == null) {
      _snack('Please select a category', color: Colors.redAccent);
      return;
    }

    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please enter a description', color: Colors.redAccent);
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await ApiLogin.getToken() ?? '';

      final success = await ApiCategory.saveTemplate(
        category: _formCategory!,
        subcategory: _formSubcategory ?? '',
        description: _descCtrl.text.trim(), // ✅ THIS is what was NOT going to DB
        token: token,
      );

      if (success) {
        final template = TicketTemplate(
          id: _savedTemplate?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          category: _formCategory!,
          subcategory: _formSubcategory ?? '',
          description: _descCtrl.text.trim(),
        );

        setState(() {
          _savedTemplate = template;
          _saving = false;
          _isEditing = false;
        });

        _snack('Template saved to database');
      } else {
        _snack('Failed to save template', color: Colors.red);
        setState(() => _saving = false);
      }
    } catch (e) {
      setState(() => _saving = false);
      _snack('Error: $e', color: Colors.red);
    }
  }


  // ── CANCEL EDIT ────────────────────────────────────────────────────────────
  void _cancelEdit() {
    if (_savedTemplate != null) {
      _descCtrl.text = _savedTemplate!.description;
      setState(() {
        _formCategory = _savedTemplate!.category;
        _formSubcategory = _savedTemplate!.subcategory;
        _isEditing = false;
      });
    } else {
      _clearForm();
      setState(() => _isEditing = false);
    }
  }

  void _clearForm() {
    final cats = _categoryMap.keys.toList();
    final firstCat = cats.isNotEmpty ? cats.first : null;
    final firstSub =
    firstCat != null ? _subNames(firstCat).firstOrNull : null;

    setState(() {
      _savedTemplate = null;
      _formCategory = firstCat;
      _formSubcategory = firstSub;
      _isEditing = false;
    });

    _descCtrl.text =
    (firstCat != null && firstSub != null)
        ? _subDescription(firstCat, firstSub)
        : '';
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
    final subDesc = (_formCategory != null && _formSubcategory != null)
        ? _subDescription(_formCategory!, _formSubcategory!)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _section('Template Details', [

            // ── Category — always interactive ──────────────────────────
            _formRow(
              label: 'Category *',
              child: _loadingCats
                  ? const CircularProgressIndicator()
                  : _inlineDropdown(
                value: _formCategory,
                items: [..._categoryMap.keys, addCategoryKey],
                hint: 'Select category',
                onChanged: (v) {
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
                  if (firstSub != null &&
                      v != null &&
                      !_isEditing) {
                    _descCtrl.text =
                        _subDescription(v, firstSub);
                  }
                },
              ),
            ),

            // ── Subcategory — always interactive ───────────────────────
            _formRow(
              label: 'Subcategory',
              child: _loadingCats
                  ? const CircularProgressIndicator()
                  : _inlineDropdown(
                value: _formSubcategory,
                items: [
                  ..._subNames(_formCategory),
                  addSubcategoryKey,
                ],
                hint: 'Select subcategory',
                onChanged: (v) {
                  if (v == addSubcategoryKey) {
                    _addSubcategoryDialog();
                    return;
                  }
                  setState(() => _formSubcategory = v);
                  if (v != null &&
                      _formCategory != null &&
                      !_isEditing) {
                    _descCtrl.text =
                        _subDescription(_formCategory!, v);
                  }
                },
              ),
            ),

            // ── Subcategory description info chip ──────────────────────
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
          ]),
        ],
      ),
    );
  }

  // ── RIGHT PANEL ────────────────────────────────────────────────────────────
  Widget _buildDescriptionPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Description', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _isEditing
                  ? TextField(
                controller: _descCtrl,
                minLines: 10,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Template description...',
                  border: InputBorder.none,
                ),
              )
                  : Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                child: Text(
                  _descCtrl.text.isNotEmpty
                      ? _descCtrl.text
                      : 'Select a subcategory to see its description.',
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
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Template'),
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
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButton<String>(
        value: items.contains(value) ? value : null,
        isExpanded: true,
        hint: Text(hint),
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