import 'package:flutter/material.dart';

class AppColors {
  // --- Core Brand (Nepal flag colors) ---
  static const Color primaryBlue = Color(0xFF0033A0);
  static const Color primaryBlueDark = Color(0xFF002080);
  static const Color primaryBlueLight = Color(0xFFE8EEFF);
  static const Color primaryBlue900 = Color(0xFF002880);
  static const Color primaryBlue800 = Color(0xFF003EB8);
  static const Color primaryBlue950 = Color(0xFF001F60);

  // --- Accent (Nepal crimson) ---
  static const Color adminRed = Color(0xFFC8102E);
  static const Color adminRedLight = Color(0xFFFEF2F4);
  static const Color adminRedBorder = Color(0xFFFCCDD3);

  // --- Light surface tokens ---
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderHover = Color(0xFFCBD5E1);
  static const Color white = Color(0xFFFFFFFF);

  // --- Dark surface tokens ---
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurface2 = Color(0xFF334155);
  static const Color darkTextMain = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // --- Gradients ---
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue900, primaryBlue800, primaryBlue950],
    stops: [0.0, 0.5, 1.0],
  );

  // Subtle light gradient used as screen background
  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFF)],
  );

  // Dark mode screen gradient
  static const LinearGradient darkScreenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F172A), Color(0xFF1A2540)],
  );
}
