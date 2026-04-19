import 'package:flutter/material.dart';

class AppTheme {
  // ───────────────── LIGHT BACKGROUND ─────────────────
  static const Color background = Color(0xFFEDEFF3);         // Slightly darker
  static const Color surface = Color(0xFFF5F6FA);            // "Cards"
  static const Color surfaceElevated = Color(0xFFE2E8F0);    // Even more contrast for "elevated" surfaces
  static const Color border = Color(0xFFD1D5DB);             // Soften the border

  // ───────────────── TEXT ─────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // ───────────────── ACCENT ─────────────────
  static const Color accent = Color(0xFF268A15);

  // ───────────────── STATUS COLORS ─────────────────
  static const Color statusAssessment = Color(0xFF7C3AED);
  static const Color statusProgress = Color(0xFFD97706);
  static const Color statusResolved = Color(0xFF059669);
  static const Color statusCancelled = Color(0xFFDC2626);

  // ───────────────── PRIORITY ─────────────────
  static const Color priority1 = Color(0xFFEF4444);
  static const Color priority2 = Color(0xFFF59E0B);
  static const Color priority3 = Color(0xFF6366F1);
  static const Color priority4 = Color(0xFF268A15);

  // ───────────────── CATEGORY ─────────────────
  static const Color catCustomer = Color(0xFFEF4444);
  static const Color catSoftware = Color(0xFFF59E0B);
  static const Color catStorage = Color(0xFF6366F1);
  static const Color catNetwork = Color(0xFF3B82F6);
  static const Color catApplications = Color(0xFF10B981);
  static const Color catDatabase = Color(0xFF14B8A6);
  static const Color catEndpoint = Color(0xFFF472B6);




  // ───────────────── SIDEBAR ─────────────────
  static const Color sidebarBg = Color(0xFFF2F3F7);          // Soft tint for sidebar
  static const Color sidebarActive = Color(0xFFE2E8F0);

  // ───────────────── THEME ─────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      canvasColor: sidebarBg,                     // For sidebar + drawer panel
      cardColor: surface,                         // Card-style widgets
      dividerColor: border,                       // Borders/dividers
      colorScheme: ColorScheme.light(
        primary: accent,
        surface: surface,
        background: background,
        onBackground: textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
    );
  }
}