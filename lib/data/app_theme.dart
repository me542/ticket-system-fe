import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceElevated = Color(0xFF1E2130);
  static const Color border = Color(0xFF2A2D3E);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color accent = Color(0xFF268A15);

  static const Color statusAssessment = Color(0xFF7C3AED);
  static const Color statusProgress = Color(0xFFD97706);
  static const Color statusResolved = Color(0xFF059669);
  static const Color statusCancelled = Color(0xFFDC2626);

  static const Color priority1 = Color(0xFFEF4444);
  static const Color priority2 = Color(0xFFF59E0B);
  static const Color priority3 = Color(0xFF6366F1);

  static const Color catCustomer = Color(0xFFEF4444);
  static const Color catSoftware = Color(0xFFF59E0B);
  static const Color catStorage = Color(0xFF6366F1);
  static const Color catNetwork = Color(0xFF3B82F6);
  static const Color catApplications = Color(0xFF10B981);

  static const Color sidebarBg = Color(0xFF13151F);
  static const Color sidebarActive = Color(0xFF1E2130);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
      ),
      fontFamily: 'Roboto',
    );
  }
}
