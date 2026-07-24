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
}
