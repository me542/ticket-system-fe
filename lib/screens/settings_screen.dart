import 'dart:async';
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
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = '';
  String _position = '';
  String _institution = '';

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // Auto-refresh every 1 minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadUserInfo();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

        _firstName = currentUser['first_name'] ?? '';
        _lastName = currentUser['last_name'] ?? '';

        _email =
            currentUser['email'] ?? '$username@example.com';

        _role = currentUser['role'] ?? 'User';

        _position = currentUser['position'] ?? '';

        _institution = currentUser['institution'] ?? '';
      });
    } catch (e) {
      setState(() {
        _username = '';
        _firstName = '';
        _lastName = '';
        _email = '';
        _role = 'User';
        _position = '';
        _institution = '';
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
            border: Border(
              bottom: BorderSide(color: AppTheme.border),
            ),
          ),
          child: const Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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

                // PROFILE HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppTheme.accent,
                        child: Text(
                          _username.isNotEmpty
                              ? _username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_firstName $_lastName',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              _email,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.sidebarActive,
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                _role.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // INFO GRID
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile =
                        constraints.maxWidth < 700;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _infoCard(
                          icon: Icons.person_outline,
                          title: 'Username',
                          value: _username,
                          width: isMobile
                              ? constraints.maxWidth
                              : (constraints.maxWidth / 2) - 24,
                        ),

                        _infoCard(
                          icon: Icons.badge_outlined,
                          title: 'Position',
                          value: _position,
                          width: isMobile
                              ? constraints.maxWidth
                              : (constraints.maxWidth / 2) - 24,
                        ),

                        _infoCard(
                          icon: Icons.business_outlined,
                          title: 'Institution',
                          value: _institution,
                          width: isMobile
                              ? constraints.maxWidth
                              : (constraints.maxWidth / 2) - 24,
                        ),

                        _infoCard(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Role',
                          value: _role,
                          width: isMobile
                              ? constraints.maxWidth
                              : (constraints.maxWidth / 2) - 24,
                        ),
                      ],
                    );
                  },
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
            padding:
            const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // Individual setting row
  Widget _settingRow(
      String label, {
        required Widget trailing,
      }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppTheme.border,
                width: 0.5,
              ),
            ),
          ),
          child: isSmall
              ? Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: trailing,
              ),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
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
      width: 220,
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

Widget _infoCard({
  required IconData icon,
  required String title,
  required String value,
  required double width,
}) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.sidebarActive,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.accent,
            size: 20,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isEmpty ? '-' : value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}