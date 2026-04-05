import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_user_data.dart';
import '../data/app_theme.dart';
import '../core/services/api_login.dart';

/// Helper to get the current user's role from API
class UserRoleHelper {
  /// Get the role of the currently logged-in user from the full users list
  static Future<String> getCurrentUserRole() async {
    final username = await ApiLogin.getUsername();
    final users = await ApiGetUser.fetchUsers();

    final currentUser = users.firstWhere(
          (user) => user['username'] == username,
      orElse: () => {},
    );

    if (currentUser.isNotEmpty) {
      return currentUser['role'] ?? 'User';
    } else {
      return 'User';
    }
  }

  /// Check if logged-in user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role.toLowerCase() == 'admin';
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _darkMode = true;

  // User info
  String _displayName = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Load user info from login + shared preferences
  Future<void> _loadUserInfo() async {
    final username = await ApiLogin.getUsername();
    final email = await _getEmail();
    final role = await UserRoleHelper.getCurrentUserRole();

    setState(() {
      _displayName = username;
      _email = email;
      _role = role;
    });
  }

  /// Get email from SharedPreferences (or fallback)
  Future<String> _getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? _displayName + '@example.com';
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
                'Settings',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section (read-only)
                _section('Profile', [
                  _settingRow('Display Name', trailing: _displayText(_displayName)),
                  _settingRow('Email', trailing: _displayText(_email)),
                  _settingRow('Role', trailing: _displayText(_role)),
                ]),
                const SizedBox(height: 20),

                // Notifications
                _section('Notifications', [
                  _settingRow(
                    'Email Notifications',
                    trailing: Switch(
                      value: _emailNotifications,
                      onChanged: (v) => setState(() => _emailNotifications = v),
                      activeColor: AppTheme.accent,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Appearance
                _section('Appearance', [
                  _settingRow(
                    'Dark Mode',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                      activeColor: AppTheme.accent,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _settingRow(String label, {required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  Widget _displayText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
