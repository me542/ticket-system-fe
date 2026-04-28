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
  final List<Map<String, String>> users = [];
  bool isLoading = false;
  String _currentUserRole = '';
  String _sortColumn = '';
  bool _isAscending = true;


  @override
  void initState() {
    super.initState();
    _loadUsersAndRole();
  }


  Widget _buildSortableHeader(String key, String title, int flex) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _sortUsers(key),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_sortColumn == key)
              Icon(
                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }


  String formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';


    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return rawDate; // fallback if parsing fails
    }
  }


  // ================= LOAD USERS + ROLE =================
  Future<void> _loadUsersAndRole() async {
    setState(() => isLoading = true);


    final token = await ApiLogin.getToken();
    if (token == null || token.isEmpty) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view users')),
      );
      return;
    }


    // Fetch users and role in parallel
    final results = await Future.wait([
      ApiGetUser.fetchUsers(),
      ApiLogin.getRole(),
    ]);


    final fetchedUsers = results[0] as List<Map<String, String>>;
    final role = results[1] as String;


    setState(() {
      users.clear();
      users.addAll(fetchedUsers);
      _currentUserRole = role;
      isLoading = false;
    });


    if (fetchedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No users found or failed to fetch users'),
        ),
      );
    }
  }


  // ================= RELOAD USERS ONLY (after add/edit) =================
  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final fetchedUsers = await ApiGetUser.fetchUsers();
    setState(() {
      users.clear();
      users.addAll(fetchedUsers);
      isLoading = false;
    });
  }


  Future<void> _confirmToggleUser(Map<String, String> u, int id) async {
    final isActive = u['status'] == 'active';


    final action = isActive ? 'Disable' : 'Enable';


    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$action User'),
          content: Text(
            'Are you sure you want to $action this user?\n\n'
                'User: ${u['full_name'] ?? ''}\n'
                'Email: ${u['email'] ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.red : Colors.green,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        );
      },
    );


    if (result == true) {
      bool success;


      if (isActive) {
        success = await ApiUser.disableUser(id: id);
      } else {
        success = await ApiUser.enableUser(id: id);
      }


      if (success) {
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${isActive ? 'disabled' : 'enabled'} successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Action failed')));
      }
    }
  }


  bool get _isAdmin => _currentUserRole.toLowerCase() == 'admin';


  void _showAdminOnlyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access denied: Only admins can perform this action'),
        backgroundColor: Colors.red,
      ),
    );
  }


  void _sortUsers(String column) {
    setState(() {
      if (_sortColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = column;
        _isAscending = true;
      }


      users.sort((a, b) {
        final aValue = (a[column] ?? '').toLowerCase();
        final bValue = (b[column] ?? '').toLowerCase();


        return _isAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
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
                'User Management',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),


        // Main Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: AppTheme.surface,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, // 👈 left & right spacing
                      vertical: 12, // 👈 top & bottom spacing
                    ),
                    child: Row(
                      children: [
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
                          '${users.length} total',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),


                  // TABLE SECTION
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : users.isEmpty
                        ? const Center(child: Text('No users found'))
                        : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context)
                              .size
                              .width, // 👈 important: forces "table width"
                          child: Column(
                            children: [
                              // HEADER
                              Container(
                                color: const Color(0xFFF1F3F5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    _buildSortableHeader(
                                      'created_at',
                                      'Created',
                                      2,
                                    ),
                                    _buildSortableHeader(
                                      'username',
                                      'Username',
                                      1,
                                    ),
                                    _buildSortableHeader(
                                      'full_name',
                                      'Full Name',
                                      1,
                                    ),
                                    _buildSortableHeader(
                                      'email',
                                      'Email',
                                      2,
                                    ),
                                    _buildSortableHeader(
                                      'role',
                                      'Role',
                                      1,
                                    ),
                                    _buildSortableHeader(
                                      'position',
                                      'Position',
                                      1,
                                    ),
                                    _buildSortableHeader(
                                      'status',
                                      'Status',
                                      1,
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text('Actions'),
                                    ),
                                  ],
                                ),
                              ),


                              const Divider(height: 1),


                              // BODY
                              Column(
                                children: users.map((u) {
                                  final id =
                                      int.tryParse(u['id'] ?? '0') ?? 0;


                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: AppTheme.border,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            formatDate(
                                              u['created_at'] ?? '',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            u['username'] ?? '',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            u['full_name'] ?? '',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(u['email'] ?? ''),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(u['role'] ?? ''),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            u['position'] ?? '',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            u['status'] ?? '',
                                            style: TextStyle(
                                              color:
                                              (u['status'] ==
                                                  'active')
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Row(
                                            children: [
                                              if (u['role'] !=
                                                  'admin') ...[
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                    size: 18,
                                                  ),
                                                  onPressed: _isAdmin
                                                      ? () =>
                                                      _showEditUserDialog(
                                                        u,
                                                      )
                                                      : _showAdminOnlyWarning,
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    color: Colors.red,
                                                    u['status'] ==
                                                        'active'
                                                        ? Icons.block
                                                        : Icons
                                                        .check_circle,
                                                    size: 18,
                                                  ),
                                                  onPressed: _isAdmin
                                                      ? () =>
                                                      _confirmToggleUser(
                                                        u,
                                                        id,
                                                      )
                                                      : _showAdminOnlyWarning,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ================= EDIT USER =================
  void _showEditUserDialog(Map<String, String> user) {
    final fullNameController = TextEditingController(text: user['full_name']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();


    String? selectedPosition =
    ['Cloud Ops', 'PS', 'QA'].contains(user['position'])
        ? user['position']!
        : null;


    String selectedRole =
    ['user', 'endorser', 'approver', 'resolver'].contains(user['role'])
        ? user['role']!
        : 'user';


    String selectedStatus = user['status'] == 'inactive'
        ? 'inactive'
        : 'active';


    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit User'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Leave blank to keep current',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    items: const [
                      DropdownMenuItem(
                        value: 'Cloud Ops',
                        child: Text('Cloud Operation Support'),
                      ),
                      DropdownMenuItem(
                        value: 'PS',
                        child: Text('Product Specialist'),
                      ),
                      DropdownMenuItem(
                        value: 'QA',
                        child: Text('Quality Assurance'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedPosition = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Position'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(
                        value: 'endorser',
                        child: Text('Endorser'),
                      ),
                      DropdownMenuItem(
                        value: 'approver',
                        child: Text('Approver'),
                      ),
                      DropdownMenuItem(
                        value: 'resolver',
                        child: Text('Resolver'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedRole = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedStatus = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = int.tryParse(user['id'] ?? '');
                if (id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid user ID')),
                  );
                  return;
                }


                final success = await ApiUser.updateUser(
                  id: id,
                  fullname: fullNameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim().isNotEmpty
                      ? passwordController.text.trim()
                      : null,
                  role: selectedRole,
                  position: selectedPosition ?? '',
                  status: selectedStatus,
                );


                if (success) {
                  setState(() {
                    user['name'] = fullNameController.text.trim();
                    user['email'] = emailController.text.trim();
                    user['role'] = selectedRole;
                    user['position'] = selectedPosition ?? '';
                    user['status'] = selectedStatus;
                    user['initials'] = fullNameController.text.trim().isNotEmpty
                        ? fullNameController.text
                        .trim()
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        : '';
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update user')),
                  );
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



