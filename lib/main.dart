import 'package:flutter/material.dart';
import 'package:ticket_system/features/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticketing System',
      debugShowCheckedModeBanner: false,

      // DARK THEME (matches your UI)
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'Arial',
      ),

      // START PAGE
      home: const Dashboard(),

      // OPTIONAL ROUTES (for later use)
      routes: {
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}
