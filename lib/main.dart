import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ── AuthGate ──────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  bool _checked = false;

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
              final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1500);
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
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        backgroundColor: AppTheme.sidebarBg,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainShell() : const LoginScreen();
  }
}

// ── MainShell ─────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _currentRoute = 'dashboard';

  Timer? _idleTimer;

  // AUTO LOGOUT TIME
  static const Duration idleDuration = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  // START TIMER
  void _startIdleTimer() {
    _idleTimer?.cancel();

    _idleTimer = Timer(idleDuration, () async {
      await _logout();
    });
  }

  // RESET TIMER WHEN USER INTERACTS
  void _resetIdleTimer() {
    _startIdleTimer();
  }

  // LOGOUT FUNCTION
  Future<void> _logout() async {
    if (kIsWeb) {
      html.window.sessionStorage.remove('user_token');
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Widget _buildContent() {
    switch (_currentRoute) {
      case 'tickets':
        return const AllTicketsScreen();

      case 'reports':
        return const Reports();

      case 'users':
        return const UserScreen();

      case 'template':
        return const TemplateScreen();

      case 'profile':
        return const SettingsScreen();

      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,

      // DETECT USER ACTIVITY
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerHover: (_) => _resetIdleTimer(),

      child: Scaffold(
        body: Row(
          children: [
            AppSidebar(
              currentRoute: _currentRoute,
              allTicketsCount: 0,
              onNavigate: (route) {
                _resetIdleTimer();

                setState(() {
                  _currentRoute = route;
                });
              },
            ),

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}