import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../core/services/api_user.dart';
import '../data/light_theme.dart';
import 'package:intl/intl.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // ── Data ──────────────────────────────────────────────────
  final List<Map<String, String>> _users = [];
  bool _loading = false;
  String _currentUserRole = '';

  // ── Search ────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  // ── Sort ──────────────────────────────────────────────────
  String _sortColumn = '';
  bool _isAscending = true;

  // ── Pagination ────────────────────────────────────────────
  int _currentPage = 1;
  static const int _perPage = 20;

  // ── Computed lists ────────────────────────────────────────
  List<Map<String, String>> get _filteredUsers {
    var list = List<Map<String, String>>.from(_users);

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((u) =>
      (u['username']   ?? '').toLowerCase().contains(q) ||
          (u['first_name'] ?? '').toLowerCase().contains(q) ||
          (u['last_name']  ?? '').toLowerCase().contains(q) ||
          (u['email']      ?? '').toLowerCase().contains(q) ||
          (u['role']       ?? '').toLowerCase().contains(q) ||
          (u['position']   ?? '').toLowerCase().contains(q) ||
          (u['institution']?? '').toLowerCase().contains(q)
      ).toList();
    }

    if (_sortColumn.isNotEmpty) {
      list.sort((a, b) {
        final av = (a[_sortColumn] ?? '').toLowerCase();
        final bv = (b[_sortColumn] ?? '').toLowerCase();
        return _isAscending ? av.compareTo(bv) : bv.compareTo(av);
      });
    }

    return list;
  }

  List<Map<String, String>> get _paginatedUsers {
    final all   = _filteredUsers;
    final start = (_currentPage - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredUsers.length / _perPage).ceil().clamp(1, 999);

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUsersAndRole();
    _searchController.addListener(() {
      setState(() {
        _search      = _searchController.text;
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> _loadUsersAndRole() async {
    setState(() => _loading = true);

    final token = await ApiLogin.getToken();
    if (token == null || token.isEmpty) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view users')),
        );
      }
      return;
    }

    final results = await Future.wait([
      ApiGetUser.fetchUsers(),
      ApiLogin.getRole(),
    ]);

    final fetchedUsers = results[0] as List<Map<String, String>>;
    final role         = results[1] as String;

    if (mounted) {
      setState(() {
        _users.clear();
        _users.addAll(fetchedUsers);
        _currentUserRole = role;
        _loading         = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final fetchedUsers = await ApiGetUser.fetchUsers();
    if (mounted) {
      setState(() {
        _users.clear();
        _users.addAll(fetchedUsers);
        _loading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  bool get _isAdmin => _currentUserRole.toLowerCase() == 'admin';

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _showAdminOnlyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access denied: Only admins can perform this action'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn  = column;
        _isAscending = true;
      }
      _currentPage = 1;
    });
  }

  // ── Toggle user ───────────────────────────────────────────
  Future<void> _confirmToggleUser(Map<String, String> u, int id) async {
    final isActive = u['status'] == 'active';
    final action   = isActive ? 'Disable' : 'Enable';
    final fullName = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '$action User',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        ),
        content: Text(
          'Are you sure you want to $action this user?\n\n'
              'User: $fullName\n'
              'Email: ${u['email'] ?? ''}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = isActive
          ? await ApiUser.disableUser(id: id)
          : await ApiUser.enableUser(id: id);

      if (mounted) {
        if (success) {
          _loadUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${isActive ? 'disabled' : 'enabled'} successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action failed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(child: _buildScrollableTable()),
                  _buildPagination(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 16),

          // ── Search ─────────────────────────────────────────
          Expanded(
            child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),

                    const Icon(Icons.search,
                        size: 16,
                        color: AppTheme.textSecondary),

                    const SizedBox(width: 8),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    if (_search.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                )
            ),
          ),
        ],
      ),
    );
  }

  // ── Table header ──────────────────────────────────────────
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        const Text(
          'List of Users',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _filteredUsers.length != _users.length
              ? '${_filteredUsers.length} of ${_users.length}'
              : '${_users.length} total',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ]),
    );
  }

  // ── Column definitions ────────────────────────────────────
  static const _cols = [
    _ColDef('Created',     'created_at',  210),
    _ColDef('Username',    'username',    150),
    _ColDef('First Name',  'first_name',  150),
    _ColDef('Last Name',   'last_name',   150),
    _ColDef('Email',       'email',       220),
    _ColDef('Role',        'role',        120),
    _ColDef('Position',    'position',    160),
    _ColDef('Institution', 'institution', 160),
    _ColDef('Status',      'status',      110),
    _ColDef('Actions',     '',            100),
  ];

  // ── Scrollable table ──────────────────────────────────────
  Widget _buildScrollableTable() {
    final page = _paginatedUsers;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth  = _cols.fold(0.0, (s, c) => s + c.width);
        final tableWidth = constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;

        final scale = constraints.maxWidth > minWidth
            ? constraints.maxWidth / minWidth
            : 1.0;
        final scaledCols = _cols
            .map((c) => _ColDef(c.label, c.key, c.width * scale))
            .toList();

        final hScrollController = ScrollController();

        return Scrollbar(
          controller: hScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: hScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // ── Column headers ──────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top:    BorderSide(color: AppTheme.border),
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Row(
                      children: scaledCols.map((col) {
                        final isSorted = _sortColumn == col.key && col.key.isNotEmpty;
                        return SizedBox(
                          width: col.width,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: col.key.isEmpty
                                ? Text(
                              col.label.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            )
                                : GestureDetector(
                              onTap: () => _onSort(col.key),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Row(children: [
                                  Expanded(
                                    child: Text(
                                      col.label.toUpperCase(),
                                      style: TextStyle(
                                        color: isSorted
                                            ? AppTheme.accent
                                            : AppTheme.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    isSorted
                                        ? (_isAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                        : Icons.unfold_more,
                                    size: 13,
                                    color: isSorted
                                        ? AppTheme.accent
                                        : AppTheme.textMuted,
                                  ),
                                ]),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Data rows ───────────────────────────────────
                  Expanded(
                    child: page.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 36, color: AppTheme.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            _search.isNotEmpty
                                ? 'No users match your search'
                                : 'No users found',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: page.length,
                      itemBuilder: (_, i) {
                        final u      = page[i];
                        final isEven = i % 2 == 0;
                        final id     = int.tryParse(u['id'] ?? '0') ?? 0;

                        return MouseRegion(
                          cursor: SystemMouseCursors.basic,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEven
                                  ? Colors.transparent
                                  : AppTheme.border.withOpacity(0.15),
                              border: const Border(
                                bottom: BorderSide(color: AppTheme.border, width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: scaledCols.map((col) {
                                return SizedBox(
                                  width: col.width,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: col.key == ''
                                        ? _actionsCell(u, id)
                                        : Text(
                                      col.key == 'created_at'
                                          ? _formatDate(u['created_at'] ?? '')
                                          : (u[col.key] ?? '').isEmpty
                                          ? '—'
                                          : u[col.key]!,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Actions cell ──────────────────────────────────────────
  Widget _actionsCell(Map<String, String> u, int id) {
    if (u['role'] == 'admin') return const SizedBox.shrink();
    return Row(
      children: [
        _ActionIcon(
          icon: Icons.edit_outlined,
          color: AppTheme.accent,
          tooltip: 'Edit user',
          onTap: _isAdmin ? () => _showEditUserDialog(u) : _showAdminOnlyWarning,
        ),
        const SizedBox(width: 4),
        _ActionIcon(
          icon: u['status'] == 'active' ? Icons.block : Icons.check_circle_outline,
          color: u['status'] == 'active' ? Colors.red : Colors.green,
          tooltip: u['status'] == 'active' ? 'Disable user' : 'Enable user',
          onTap: _isAdmin ? () => _confirmToggleUser(u, id) : _showAdminOnlyWarning,
        ),
      ],
    );
  }

  // ── Pagination ────────────────────────────────────────────
  Widget _buildPagination() {
    final total   = _totalPages;
    final current = _currentPage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
                  () {
                final start = _filteredUsers.isEmpty ? 0 : (current - 1) * _perPage + 1;
                final end   = (current * _perPage).clamp(0, _filteredUsers.length);
                return 'Showing $start–$end of ${_filteredUsers.length}';
              }(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PageButton(
                    icon: Icons.chevron_left,
                    enabled: current > 1,
                    onTap: () => setState(() => _currentPage--),
                  ),
                  const SizedBox(width: 4),

                  ..._buildPagePills(current, total),

                  const SizedBox(width: 4),
                  _PageButton(
                    icon: Icons.chevron_right,
                    enabled: current < total,
                    onTap: () => setState(() => _currentPage++),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPagePills(int current, int total) {
    final List<int> pages = [];
    if (total <= 5) {
      pages.addAll(List.generate(total, (i) => i + 1));
    } else {
      int start = (current - 2).clamp(1, total - 4);
      int end   = (start + 4).clamp(5, total);
      start     = (end - 4).clamp(1, total);
      pages.addAll(List.generate(end - start + 1, (i) => start + i));
    }
    return pages.map((p) {
      final isActive = p == current;
      return GestureDetector(
        onTap: () => setState(() => _currentPage = p),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border),
          ),
          child: Center(
            child: Text(
              '$p',
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Edit user dialog ──────────────────────────────────────
  void _showEditUserDialog(Map<String, String> user) {
    final firstNameController  = TextEditingController(text: user['first_name']);
    final lastNameController   = TextEditingController(text: user['last_name']);
    final emailController      = TextEditingController(text: user['email']);
    final passwordController   = TextEditingController();
    final institutionController= TextEditingController(text: user['institution']);

    String? selectedPosition = (user['position'] ?? '').isNotEmpty
        ? user['position']
        : null;

    String selectedRole =
    ['user', 'endorser', 'approver', 'resolver'].contains(user['role'])
        ? user['role']!
        : 'user';
    String selectedStatus = user['status'] == 'inactive' ? 'inactive' : 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Edit User',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(children: [

                // ── First Name | Last Name ─────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstNameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'First Name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lastNameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Last Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Email ──────────────────────────────────
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),

                // ── Password ───────────────────────────────
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Leave blank to keep current',
                  ),
                ),
                const SizedBox(height: 10),

                // ── Position (Autocomplete) ────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue val) {
                        if (val.text.isEmpty) return _kPositions;
                        return _kPositions.where((p) =>
                            p.toLowerCase().contains(val.text.toLowerCase()));
                      },
                      initialValue: TextEditingValue(
                        text: selectedPosition ?? '',
                      ),
                      onSelected: (String s) {
                        setStateDialog(() => selectedPosition = s);
                      },
                      fieldViewBuilder: (ctx, fieldCtrl, focus, onSubmit) {
                        return TextField(
                          controller: fieldCtrl,
                          focusNode: focus,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (v) {
                            setStateDialog(() => selectedPosition = v);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Position',
                            hintText: 'Search position…',
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (ctx, onSelected, options) => Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.surface,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (_, i) {
                                final opt = options.elementAt(i);
                                return InkWell(
                                  onTap: () => onSelected(opt),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Text(
                                      opt,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Institution (Autocomplete) ────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Institution',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue val) {
                        if (val.text.isEmpty) return _kInstitution;
                        return _kInstitution.where((i) =>
                            i.toLowerCase().contains(val.text.toLowerCase()));
                      },
                      initialValue: TextEditingValue(
                        text: institutionController.text,
                      ),
                      onSelected: (String s) {
                        institutionController.text = s;
                      },
                      fieldViewBuilder: (ctx, fieldCtrl, focus, onSubmit) {
                        fieldCtrl.text = institutionController.text;

                        return TextField(
                          controller: fieldCtrl,
                          focusNode: focus,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (v) {
                            institutionController.text = v;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Institution',
                            hintText: 'Search institution…',
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (ctx, onSelected, options) => Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.surface,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (_, i) {
                                final opt = options.elementAt(i);

                                return InkWell(
                                  onTap: () => onSelected(opt),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      opt,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Role ───────────────────────────────────
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'user',     child: Text('User')),
                    DropdownMenuItem(value: 'endorser', child: Text('Endorser')),
                    DropdownMenuItem(value: 'approver', child: Text('Approver')),
                    DropdownMenuItem(value: 'resolver', child: Text('Resolver')),
                  ],
                  onChanged: (v) { if (v != null) setStateDialog(() => selectedRole = v); },
                ),
                const SizedBox(height: 10),

                // ── Status ─────────────────────────────────
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active',   child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (v) { if (v != null) setStateDialog(() => selectedStatus = v); },
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final id = int.tryParse(user['id'] ?? '');
                if (id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid user ID')),
                  );
                  return;
                }

                final success = await ApiUser.updateUser(
                  id:          id,
                  firstName:   firstNameController.text.trim(),
                  lastName:    lastNameController.text.trim(),
                  email:       emailController.text.trim(),
                  password:    passwordController.text.trim().isNotEmpty
                      ? passwordController.text.trim()
                      : null,
                  role:        selectedRole,
                  position:    selectedPosition ?? '',
                  institution: institutionController.text.trim(),
                  status:      selectedStatus,
                );

                if (success) {
                  setState(() {
                    user['first_name']  = firstNameController.text.trim();
                    user['last_name']   = lastNameController.text.trim();
                    user['email']       = emailController.text.trim();
                    user['role']        = selectedRole;
                    user['position']    = selectedPosition ?? '';
                    user['institution'] = institutionController.text.trim();
                    user['status']      = selectedStatus;
                  });
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update user'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Position list
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kPositions = [
  'Analytics Engineer - OIC',
  'Application Analyst 2',
  'Application Developer',
  'Application Developer 1 - OIC',
  'Business Intelligence Analyst - OIC',
  'Business Intelligence Lead OIC',
  'Business Relationship Manager - OIC',
  'Chief Data Officer - OIC',
  'Chief Data Scientist - OIC',
  'Chief Operating Officer - OIC',
  'Cloud Engineer - OIC',
  'Cloud Operations Administrator - OIC',
  'Cloud Operations Support',
  'Compliance',
  'Compliance Officer',
  'Data Scientist OIC',
  'DDFA- OIC',
  'Developer',
  'Developer 1',
  'Developer 1 - OIC',
  'Developer 2 - OIC',
  'Finance Assistant',
  'Information Security Officer - OIC',
  'Junior Analytics Developer',
  'Junior Analytics Engineer',
  'Junior Data Engineer',
  'Machine Learning Engineer OIC',
  'Product Specialist',
  'Product Specialist 1',
  'Product Specialist 1 - OIC',
  'Product Specialist Head OIC',
  'Project Manager - OIC',
  'Quality Assurance Analyst',
  'Quality Assurance Analyst 1',
  'Quality Assurance Manager',
  'Report Specialist I',
  'Report Specialist II',
  'Report Specialist II - OIC',
  'Report Specialist III',
  'Report Specialist III - OIC',
  'Risk Management Officer - OIC',
  'Senior Finance Officer OIC',
];

const List<String> _kInstitution = [
  'MHI Healthcare Inc.',
  'CMIT',
  'FDSAP',
  'Bakawan Data Analytics',
  'EMPC',
  'CARD Bank',
  'CARD SME Bank',
  'CARD RBI',
  'CARD Inc.',
  'Padayon Microfinance',
  'Astro',
  'Laguna Fresh',
  'CARD MRI International Partnership Project Institution',
  'CARD MRI Holdings Company',
  'CARD MBA',
  'Bente Production',
  'Hijos Tours',
  'CARD Publishing House',
  'CARD Indogrosir Inc.',
  'LIKHA NI INAY',
  'OTTO KONEK',
  'CARD Pioneer Microinsurance Inc.',
  'CARD Mutually Reinforcing Institutions',
  'CARD Engagement Services Inc.',
  'CARD MRI Development Institute Inc.',
  'CARD-PCPD',
  'BotiCARD Pharmacy',
  'CaMIA (CARD MRI Insurance Agency)',
  'CARD MBA Pioneer',
];
// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ColDef {
  final String label;
  final String key;
  final double width;
  const _ColDef(this.label, this.key, this.width);
}

class _ActionIcon extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData     icon;
  final bool         enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
        ),
      ),
    );
  }
}