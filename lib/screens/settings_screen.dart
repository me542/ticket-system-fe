import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../data/light_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  String _username = '';
  String _fullName = '';
  String _email = '';
  String _role = '';
  String _position = '';


  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    //_darkMode = themeModeNotifier.value == ThemeMode.dark;
  }

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
        _fullName = currentUser['full_name'] ?? '';
        _email = currentUser['email'] ?? username + '@example.com';
        _role = currentUser['role'] ?? 'User';
        _position = currentUser['position'] ?? '';
      });
    } catch (e) {
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
                // Profile section
                _section('Profile', [
                  _settingRow('Full Name', trailing: _displayText(_fullName)),
                  _settingRow('Username', trailing: _displayText(_username)),
                  _settingRow('Email', trailing: _displayText(_email)),
                  _settingRow('Role', trailing: _displayText(_role)),
                  _settingRow('Position', trailing: _displayText(_position)),
                ]),
                const SizedBox(height: 20),

                // ElevatedButton(
                //   onPressed: () {
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: AppTheme.accent,
                //     foregroundColor: Colors.white,
                //     padding:
                //     const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                //     shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(8)),
                //   ),
                //   child: const Text(
                //     'Save Changes',
                //     style: TextStyle(fontWeight: FontWeight.w600),
                //   ),
                // ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: isSmall
          // 📱 SMALL SCREEN (stacked)
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: trailing),
            ],
          )
          // 💻 LARGE SCREEN (row)
              : Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ),
              trailing,
            ],
          ),
        );
      },
    );
  }

  // Display text for read-only fields
  Widget _displayText(String text) {
    return SizedBox(
      width: 200, // limit width
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
