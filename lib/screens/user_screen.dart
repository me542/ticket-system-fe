import 'package:flutter/material.dart';
import '../data/app_theme.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
    ];

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
              Text('User Management', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('Users', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Text('${users.length} total', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...users.map((u) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.accent,
                          child: Text(u['initials']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(u['email']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(u['role']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusResolved.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(u['status']!, style: const TextStyle(color: AppTheme.statusResolved, fontSize: 11)),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
