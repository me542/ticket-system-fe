import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../data/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _darkMode = true;

  // User info
  String _username = '';
  String _fullName = '';
  String _email = '';
  String _role = '';
  String _position = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Load user info from API
  Future<void> _loadUserInfo() async {
    try {
      final username = await ApiLogin.getUsername();
      final users = await ApiGetUser.fetchUsers();

      final currentUser = users.firstWhere(
            (user) => user['username'] == username,
        orElse: () => {},
      );

      setState(() {
        _username = username;
        _fullName = currentUser['name'] ?? '';       // ← use 'name' key from API
        _email = currentUser['email'] ?? username + '@example.com';
        _role = currentUser['role'] ?? 'User';
        _position = currentUser['position'] ?? '';
      });
    } catch (e) {
      print('💥 Error loading user info: $e');
      setState(() {
        _username = '';
        _fullName = '';
        _email = '';
        _role = 'User';
        _position = '';
      });
    }
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
                  _settingRow('Full Name', trailing: _displayText(_fullName)),
                  _settingRow('Username', trailing: _displayText(_username)),
                  _settingRow('Email', trailing: _displayText(_email)),
                  _settingRow('Role', trailing: _displayText(_role)),
                  _settingRow('Position', trailing: _displayText(_position)),
                ]),
                const SizedBox(height: 20),

                // Notifications
                _section('Notifications', [
                  _settingRow(
                    'Email Notifications',
                    trailing: Switch(
                      value: _emailNotifications,
                      onChanged: (v) =>
                          setState(() => _emailNotifications = v),
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
                  onPressed: () {
                    // TODO: Implement save changes logic
                    print('💾 Save button pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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

  // Section container
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

  // Individual setting row
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

  // Display text for read-only fields
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
