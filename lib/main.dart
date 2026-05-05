import 'dart:async';          // ← add this
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_system/screens/template.dart';
import 'data/light_theme.dart';
import 'widgets/app_sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/all_tickets_screen.dart';
import 'screens/user_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/loginscreen.dart';
import 'screens/reports.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool('darkMode') ?? false;
  themeModeNotifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'IDIYANALE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

// ── AuthGate (unchanged) ──────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  bool _checked    = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    bool valid = false;

    if (kIsWeb) {
      final token = html.window.sessionStorage['user_token'] ?? '';
      if (token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(
              base64Url.decode(base64Url.normalize(parts[1])),
            );
            final map = jsonDecode(payload) as Map<String, dynamic>;
            final exp = map['exp'] as int?;
            if (exp != null) {
              final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
              valid = expiry.isAfter(DateTime.now());
            } else {
              valid = true;
            }
          }
        } catch (_) {
          valid = false;
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      valid = token.isNotEmpty;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = valid;
        _checked    = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        backgroundColor: AppTheme.sidebarBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const MainShell() : const LoginScreen();
  }
}

// ── MainShell with Auto-Refresh ───────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _currentRoute = 'dashboard';
  Timer? _refreshTimer;                          // ← timer reference
  int _refreshKey = 0;                           // ← forces child rebuild

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) {
        if (mounted) {
          final savedRoute = _currentRoute; // ← snapshot current route
          setState(() {
            _refreshKey++;
            _currentRoute = savedRoute;     // ← restore it after rebuild
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();                     // ← always cancel on exit
    super.dispose();
  }

  Widget _buildContent() {
    switch (_currentRoute) {
      case 'tickets':
        return AllTicketsScreen(key: ValueKey('tickets_$_refreshKey'));
      case 'reports':
        return Reports(key: ValueKey('reports_$_refreshKey'));
      case 'users':
        return UserScreen(key: ValueKey('users_$_refreshKey'));
      case 'template':
        return TemplateScreen(key: ValueKey('template_$_refreshKey'));
      case 'settings':
        return SettingsScreen(key: ValueKey('settings_$_refreshKey'));
      default:
        return DashboardScreen(key: ValueKey('dashboard_$_refreshKey'));
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