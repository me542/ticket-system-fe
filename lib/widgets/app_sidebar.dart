import 'package:flutter/material.dart';
import '../data/app_theme.dart';
import '../screens/loginscreen.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final String userName;
  final String userRole;
  final String userInitials;
  final int allTicketsCount;
  final Function(String) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.userName,
    required this.userRole,
    required this.userInitials,
    required this.allTicketsCount,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF268A15), Color(0xFF268A15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'TS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TICKET SYSTEM',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'V1.0.1',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // MAIN section
          _sectionLabel('MAIN'),
          _navItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: 'dashboard',
          ),
          _navItem(
            icon: Icons.confirmation_number_outlined,
            label: 'All Tickets',
            route: 'tickets',
            badge: allTicketsCount,
          ),

          const SizedBox(height: 16),
          _sectionLabel('MANAGEMENT'),
          _navItem(
            icon: Icons.people_outline,
            label: 'User',
            route: 'users',
          ),
          _navItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            route: 'settings',
          ),

          const Spacer(),

          // User profile at bottom
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.accent,
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userRole,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 16, color: AppTheme.textSecondary),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false, // removes all previous routes
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required String route,
    int? badge,
  }) {
    final isActive = currentRoute == route;
    return GestureDetector(
      onTap: () => onNavigate(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.accent : AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
