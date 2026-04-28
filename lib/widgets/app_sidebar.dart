import 'package:flutter/material.dart';
import '../core/services/api_login.dart';
import '../data/light_theme.dart';
import '../screens/loginscreen.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final int allTicketsCount;
  final Function(String) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.allTicketsCount,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final roleFuture = ApiLogin.getRole(); // ✅ reuse for all role checks

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
                Image.asset(
                  '/Users/bakawan-user/Desktop/ticket-system-fe/lib/assets/favicon1.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IDIYANALE',
                      style: TextStyle(
                        color: Color(0xFFDAB76B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Bakawan Ticketing System',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 7,
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

          // ✅ REPORTS (ADMIN ONLY)
          FutureBuilder<String>(
            future: roleFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              if (snapshot.data == 'admin') {
                return _navItem(
                  icon: Icons.report,
                  label: 'Reports',
                  route: 'reports',
                );
              }

              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 16),

          _sectionLabel('MANAGEMENT'),

          // ✅ USERS (ADMIN ONLY)
          FutureBuilder<String>(
            future: roleFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              if (snapshot.data == 'admin') {
                return _navItem(
                  icon: Icons.people_outline,
                  label: 'User',
                  route: 'users',
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // ✅ Template (ADMIN ONLY)
          FutureBuilder<String>(
            future: roleFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              if (snapshot.data == 'admin') {
                return _navItem(
                  icon: Icons.report,
                  label: 'Template',
                  route: 'template',
                );
              }

              return const SizedBox.shrink();
            },
          ),


          _navItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            route: 'settings',
          ),

          const Spacer(),

          // User profile at bottom
          FutureBuilder(
            future: Future.wait([
              ApiLogin.getUsername(),
              ApiLogin.getRole(),
              ApiLogin.getInitials(),
            ]),
            builder: (context, AsyncSnapshot<List<String>> snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final username = snapshot.data![0];
              final initials = snapshot.data![2];

              return Container(
                margin: const EdgeInsets.all(12),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        username,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () async {
                        await ApiLogin.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
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
                  color:
                  isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
