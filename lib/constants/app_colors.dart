import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A3FCF);
  static const Color primaryLight = Color(0xFF8B85FF);

  static const Color secondary = Color(0xFF1E1E2D);
  static const Color accent = Color(0xFF00D9A6);

  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color cardShadow = Color(0x1A000000);

  static const Color textPrimary = Color(0xFF1E1E2D);
  static const Color textSecondary = Color(0xFF8E8EA0);
  static const Color textOnPrimary = Colors.white;

  static const Color income = Color(0xFF00D9A6);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color balance = Color(0xFF6C63FF);

  static const Color inputFill = Color(0xFFF0F0F5);
  static const Color inputBorder = Color(0xFFE0E0E8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A3FCF), Color(0xFF2D246B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D9A6), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00D9A6), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Chart colors ─────────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF6C63FF), // Primary purple
    Color(0xFF00D9A6), // Teal/accent
    Color(0xFFFF6B6B), // Red/expense
    Color(0xFFFFD93D), // Yellow
    Color(0xFF6B5BFF), // Indigo
    Color(0xFFFF8C69), // Coral
    Color(0xFF4ECDC4), // Turquoise
    Color(0xFFFF6B6B), // Pink
    Color(0xFF95E1D3), // Mint
    Color(0xFFF38181), // Salmon
  ];

  static const Color chartGridLine = Color(0xFFE8E8E8);
  static const Color chartTooltipBg = Color(0xFF1E1E2D);
}
