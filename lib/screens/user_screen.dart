import 'package:flutter/material.dart';
import '../data/app_theme.dart';
import '../core/services/api_user.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final List<Map<String, String>> users = [];

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
                    child: ListView(
                      children:
                      users.map((u) => _buildUserRow(u)).toList(),
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

  Widget _buildUserRow(Map<String, String> u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accent,
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

          // Name + Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u['name'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  u['email'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Position
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
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),

          // Role
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              u['role'] ?? '',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final fullNameController = TextEditingController();
    final userNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedPosition = 'Cloud Ops';
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add User'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: fullNameController,
                  decoration:
                  const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: userNameController,
                  decoration:
                  const InputDecoration(labelText: 'User Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration:
                  const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 10),

                // Position Dropdown
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
                  decoration:
                  const InputDecoration(labelText: 'Position'),
                ),

                const SizedBox(height: 10),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(
                        value: 'endorser', child: Text('Endorser')),
                    DropdownMenuItem(
                        value: 'approver', child: Text('Approver')),
                    DropdownMenuItem(
                        value: 'resolver', child: Text('Resolver')),
                    DropdownMenuItem(
                        value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'superadmin',
                        child: Text('SuperAdmin')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() => selectedRole = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final fullName = fullNameController.text.trim();
                final userName = userNameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (fullName.isEmpty ||
                    userName.isEmpty ||
                    email.isEmpty ||
                    password.isEmpty) return;

                final initials = fullName
                    .split(' ')
                    .map((e) => e[0])
                    .take(2)
                    .join()
                    .toUpperCase();

                final success = await ApiUser.createUser(
                  username: userName,
                  email: email,
                  password: password,
                  role: selectedRole,
                  fullname: fullName,
                  position: selectedPosition, Position: '',
                );

                if (success) {
                  setState(() {
                    users.add({
                      'name': fullName,
                      'email': email,
                      'role': selectedRole,
                      'position': selectedPosition,
                      'initials': initials,
                    });
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to create user.')),
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
}
