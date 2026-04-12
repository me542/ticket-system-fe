import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../core/services/api_user.dart';
import '../data/app_theme.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final List<Map<String, String>> users = [];
  bool isLoading = false;
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _loadUsersAndRole();
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

    print('✅ Loaded role: $role');
    print('✅ Loaded ${fetchedUsers.length} users');

    setState(() {
      users.clear();
      users.addAll(fetchedUsers);
      _currentUserRole = role;
      isLoading = false;
    });

    if (fetchedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No users found or failed to fetch users')),
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

  bool get _isAdmin => _currentUserRole.toLowerCase() == 'admin';

  void _showAdminOnlyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access denied: Only admins can perform this action'),
        backgroundColor: Colors.red,
      ),
    );
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
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Users',
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
                        const Spacer(),
                        if (_isAdmin)
                          ElevatedButton.icon(
                            onPressed: _showAddUserDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Users List
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : users.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView(
                      children: users
                          .map((u) => _buildUserRow(u))
                          .toList(),
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

  // ================= USER ROW =================
  Widget _buildUserRow(Map<String, String> u) {
    final bool isDisabled = u['status'] == 'inactive';
    return InkWell(
      onTap: () {
        if (!_isAdmin) {
          _showAdminOnlyWarning();
          return;
        }
        _showUserActions(u);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border:
          Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDisabled ? Colors.grey : AppTheme.accent,
              child: Text(
                u['initials'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u['name'] ?? '',
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    u['email'] ?? '',
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey
                          : AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                u['position'] ?? '',
                style: TextStyle(
                  color: isDisabled
                      ? Colors.grey
                      : AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                u['role'] ?? '',
                style: TextStyle(
                  color: isDisabled
                      ? Colors.grey
                      : AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

            if (!_isAdmin) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  // ================= ACTION MENU =================
  void _showUserActions(Map<String, String> user) {
    final bool isDisabled = user['status'] == 'inactive';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user['name'] ?? ''),
        content: const Text('Select an action'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(user);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isDisabled) {
                _confirmEnableUser(user);
              } else {
                _confirmDisableUser(user);
              }
            },
            child: Text(
              isDisabled ? 'Enable' : 'Disable',
              style: TextStyle(
                  color: isDisabled ? Colors.green : Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ADD USER =================
  void _showAddUserDialog() {
    final fullNameController = TextEditingController();
    final userNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedPosition = 'Cloud Ops';
    String selectedRole = 'enduser';

    bool fullNameValid = true;
    bool userNameValid = true;
    bool emailValid = true;
    bool passwordValid = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add User'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      errorText:
                      fullNameValid ? null : 'Full Name is required',
                    ),
                    onChanged: (value) {
                      setStateDialog(
                              () => fullNameValid = value.trim().isNotEmpty);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: userNameController,
                    decoration: InputDecoration(
                      labelText: 'User Name',
                      errorText: userNameValid
                          ? null
                          : 'Invalid or duplicate username',
                    ),
                    onChanged: (value) {
                      bool valid = value.trim().isNotEmpty &&
                          !RegExp(r'^[0-9]+$').hasMatch(value);
                      bool duplicate = users.any((u) =>
                      u['username']?.toLowerCase() ==
                          value.toLowerCase());
                      setStateDialog(
                              () => userNameValid = valid && !duplicate);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText:
                      emailValid ? null : 'Invalid or duplicate email',
                    ),
                    onChanged: (value) {
                      bool duplicate = users.any((u) =>
                      u['email']?.toLowerCase() ==
                          value.toLowerCase());
                      setStateDialog(() =>
                      emailValid =
                          value.trim().isNotEmpty && !duplicate);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText:
                      passwordValid ? null : 'Password invalid',
                    ),
                    onChanged: (value) {
                      bool valid = value.length >= 8 &&
                          RegExp(r'[A-Z]').hasMatch(value) &&
                          RegExp(r'[a-z]').hasMatch(value) &&
                          RegExp(r'[0-9]').hasMatch(value) &&
                          RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                              .hasMatch(value);
                      setStateDialog(() => passwordValid = valid);
                    },
                  ),
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password must:\n'
                          '• Minimum 8 characters\n'
                          '• Uppercase letter\n'
                          '• Lowercase letter\n'
                          '• Number\n'
                          '• Special character',
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    items: const [
                      DropdownMenuItem(
                          value: 'Cloud Ops',
                          child: Text('Cloud Operation Support')),
                      DropdownMenuItem(
                          value: 'PS',
                          child: Text('Product Specialist')),
                      DropdownMenuItem(
                          value: 'QA',
                          child: Text('Quality Assurance')),
                      DropdownMenuItem(
                          value: 'N/A', child: Text('N/A')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedPosition = value);
                      }
                    },
                    decoration:
                    const InputDecoration(labelText: 'Position'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                          value: 'enduser', child: Text('End User')),
                      DropdownMenuItem(
                          value: 'endorser', child: Text('Endorser')),
                      DropdownMenuItem(
                          value: 'approver', child: Text('Approver')),
                      DropdownMenuItem(
                          value: 'resolver', child: Text('Resolver')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedRole = value);
                      }
                    },
                    decoration:
                    const InputDecoration(labelText: 'Role'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (fullNameController.text.trim().isEmpty ||
                    userNameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty ||
                    !fullNameValid ||
                    !userNameValid ||
                    !emailValid ||
                    !passwordValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please fix the errors before submitting')),
                  );
                  return;
                }

                final success = await ApiUser.createUser(
                  username: userNameController.text.trim(),
                  fullname: fullNameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  role: selectedRole,
                  position: selectedPosition,
                );

                if (success) {
                  Navigator.pop(context);
                  await _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User created successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to create user')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EDIT USER =================
  void _showEditUserDialog(Map<String, String> user) {
    final fullNameController =
    TextEditingController(text: user['name']);
    final emailController =
    TextEditingController(text: user['email']);
    final passwordController = TextEditingController();

    String selectedPosition =
    ['Cloud Ops', 'PS', 'QA', 'N/A'].contains(user['position'])
        ? user['position']!
        : 'N/A';

    String selectedRole = [
      'enduser',
      'endorser',
      'approver',
      'resolver'
    ].contains(user['role'])
        ? user['role']!
        : 'enduser';

    String selectedStatus =
    user['status'] == 'inactive' ? 'inactive' : 'active';

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
                    decoration:
                    const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration:
                    const InputDecoration(labelText: 'Email'),
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
                          child: Text('Cloud Operation Support')),
                      DropdownMenuItem(
                          value: 'PS',
                          child: Text('Product Specialist')),
                      DropdownMenuItem(
                          value: 'QA',
                          child: Text('Quality Assurance')),
                      DropdownMenuItem(
                          value: 'N/A', child: Text('N/A')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedPosition = value);
                      }
                    },
                    decoration:
                    const InputDecoration(labelText: 'Position'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                          value: 'enduser', child: Text('End User')),
                      DropdownMenuItem(
                          value: 'endorser', child: Text('Endorser')),
                      DropdownMenuItem(
                          value: 'approver', child: Text('Approver')),
                      DropdownMenuItem(
                          value: 'resolver', child: Text('Resolver')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedRole = value);
                      }
                    },
                    decoration:
                    const InputDecoration(labelText: 'Role'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(
                          value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedStatus = value);
                      }
                    },
                    decoration:
                    const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
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
                  position: selectedPosition,
                  status: selectedStatus,
                );

                if (success) {
                  setState(() {
                    user['name'] = fullNameController.text.trim();
                    user['email'] = emailController.text.trim();
                    user['role'] = selectedRole;
                    user['position'] = selectedPosition;
                    user['status'] = selectedStatus;
                    user['initials'] =
                    fullNameController.text.trim().isNotEmpty
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
                    const SnackBar(
                        content: Text('User updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to update user')),
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

  // ================= DISABLE USER =================
  void _confirmDisableUser(Map<String, String> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disable User'),
        content:
        Text('Are you sure you want to disable ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final id = int.tryParse(user['id'] ?? '');
              if (id == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid user ID')),
                );
                return;
              }

              final success = await ApiUser.disableUser(id: id);

              if (success) {
                setState(() => user['status'] = 'inactive');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${user['name']} disabled successfully')),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Failed to disable user')),
                );
              }
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  // ================= ENABLE USER =================
  void _confirmEnableUser(Map<String, String> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable User'),
        content:
        Text('Are you sure you want to enable ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final id = int.tryParse(user['id'] ?? '');
              if (id == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid user ID')),
                );
                return;
              }

              final success = await ApiUser.enableUser(id: id);

              if (success) {
                setState(() => user['status'] = 'active');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                      Text('${user['name']} enabled successfully')),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Failed to enable user')),
                );
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}