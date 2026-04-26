import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_system/main.dart';
import 'package:ticket_system/screens/loginscreen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shows LoginScreen when no token saved', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump(); // first frame
    await tester.pump(const Duration(seconds: 1)); // wait for _checkAuth

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Shows LoginScreen when token is invalid', (WidgetTester tester) async {
    // Invalid/fake token that won't parse as a real JWT
    SharedPreferences.setMockInitialValues({'user_token': 'fake_test_token'});

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Shows AuthGate loading state initially', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump(); // only first frame — before _checkAuth completes

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App uses light theme by default', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.light);
  });
}