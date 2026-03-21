import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Palette (from bg-blue-900, text-blue-900)
  static const Color primaryBlue = Color.fromRGBO(30, 58, 138, 1);
  static const Color primaryBlueDark = Color(0xFF172554);
  static const Color primaryBlueLight = Color(0xFFEFF6FF);

  // Admin/Danger Palette (from text-red-600, bg-red-50)
  static const Color adminRed = Color(0xFFDC2626);
  static const Color adminRedLight = Color(0xFFFEF2F2);
  static const Color adminRedBorder = Color(0xFFFECACA);

  // Grayscale & Backgrounds (from bg-gray-50, text-gray-900, etc.)
  static const Color background = Color(0xFFF9FAFB);
  static const Color textMain = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderHover = Color(0xFFD1D5DB);

  // White
  static const Color white = Color(0xFFFFFFFF);

  // --- Core Brand Colors ---
  static const Color primaryBlue900 = Color(0xFF1E3A8A);
  static const Color primaryBlue800 = Color(0xFF1E40AF);
  static const Color primaryBlue950 = Color(0xFF172554);

  // --- Background Gradients ---
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue900, primaryBlue800, primaryBlue950],
    stops: [0.0, 0.5, 1.0],
  );
}
