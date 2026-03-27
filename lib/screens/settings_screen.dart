import 'package:flutter/material.dart';
import '../data/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _darkMode = true;

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
              Text('Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Profile', [
                  _settingRow('Display Name', trailing: _inputField('')),
                  _settingRow('Email', trailing: _inputField('')),
                  _settingRow('Role', trailing: _inputField('', enabled: false)),
                ]),
                const SizedBox(height: 20),
                _section('Notifications', [
                  _settingRow('Email Notifications', trailing: Switch(
                    value: _emailNotifications,
                    onChanged: (v) => setState(() => _emailNotifications = v),
                    activeColor: AppTheme.accent,
                  )),
                ]),
                const SizedBox(height: 20),
                _section('Appearance', [
                  _settingRow('Dark Mode', trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeColor: AppTheme.accent,
                  )),
                ]),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
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
            child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
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
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  Widget _inputField(String value, {bool enabled = true}) {
    return SizedBox(
      width: 240,
      child: TextFormField(
        initialValue: value,
        enabled: enabled,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: AppTheme.border,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
