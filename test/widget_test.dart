import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_system/main.dart';
import 'package:ticket_system/screens/loginscreen.dart';
import 'package:ticket_system/data/dark_theme.dart';

void main() {
  // Reset SharedPreferences before each test
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shows LoginScreen when no token saved', (WidgetTester tester) async {
    // No token in prefs → should show LoginScreen
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Shows MainShell when token exists', (WidgetTester tester) async {
    // Token present → should skip LoginScreen
    SharedPreferences.setMockInitialValues({'user_token': 'fake_test_token'});

    await tester.pumpWidget(const MyApp(isLoggedIn: true));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('App uses dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.dark);
  });
}