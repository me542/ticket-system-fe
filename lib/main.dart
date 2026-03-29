import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/ticket_provider.dart';
import 'data/app_theme.dart';
import 'widgets/app_sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/all_tickets_screen.dart';
import 'screens/user_screen.dart';
import 'screens/settings_screen.dart';
import 'package:ticket_system/screens/loginscreen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TicketProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _currentRoute = 'dashboard';

  Widget _buildContent() {
    switch (_currentRoute) {
      case 'tickets':
        return const AllTicketsScreen();
      case 'users':
        return const UserScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            currentRoute: _currentRoute,
            userName: provider.currentUserName,
            userRole: provider.currentUserRole,
            userInitials: provider.currentUserInitials,
            allTicketsCount: provider.totalTickets,
            onNavigate: (route) => setState(() => _currentRoute = route),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
