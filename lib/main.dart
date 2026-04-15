import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/app_theme.dart';
import 'widgets/app_sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/all_tickets_screen.dart';
import 'screens/user_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/loginscreen.dart';

void main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Check if a valid token already exists in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('user_token') ?? '';
  final isLoggedIn = token.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDIYANALE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // If token exists → go straight to MainShell, else LoginScreen
      home: isLoggedIn ? const MainShell() : const LoginScreen(),
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
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            currentRoute: _currentRoute,
            allTicketsCount: 0,
            onNavigate: (route) => setState(() => _currentRoute = route),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}