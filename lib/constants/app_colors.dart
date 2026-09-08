import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0A5C56);
  static const Color primaryLight = Color(0xFF14B8A6);

  // ── Secondary emerald/green ─────────────────────────────────────
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFF34D399);

  // ── Backgrounds & surfaces ──────────────────────────────────────
  static const Color background = Color(0xFFF7F8F6);
  static const Color surface = Colors.white;
  static const Color cardShadow = Color(0x0D000000);

  // ── Text ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF12343B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Colors.white;

  // ── Semantic ────────────────────────────────────────────────────
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color balance = Color(0xFF0F766E);

  // ── Input fields ────────────────────────────────────────────────
  static const Color inputFill = Color(0xFFF1F5F9);
  static const Color inputBorder = Color(0xFFE2E8F0);

  // ── Soft category pastels ───────────────────────────────────────
  static const Color foodBg = Color(0xFFFEF3C7);
  static const Color foodFg = Color(0xFFD97706);
  static const Color transportBg = Color(0xFFDBEAFE);
  static const Color transportFg = Color(0xFF2563EB);
  static const Color shoppingBg = Color(0xFFFCE7F3);
  static const Color shoppingFg = Color(0xFFDB2777);
  static const Color billsBg = Color(0xFFFEE2E2);
  static const Color billsFg = Color(0xFFDC2626);
  static const Color entertainmentBg = Color(0xFFE0E7FF);
  static const Color entertainmentFg = Color(0xFF4F46E5);
  static const Color healthBg = Color(0xFFD1FAE5);
  static const Color healthFg = Color(0xFF059669);
  static const Color educationBg = Color(0xFFF3E8FF);
  static const Color educationFg = Color(0xFF7C3AED);
  static const Color otherBg = Color(0xFFF1F5F9);
  static const Color otherFg = Color(0xFF64748B);
  static const Color salaryBg = Color(0xFFD1FAE5);
  static const Color salaryFg = Color(0xFF059669);
  static const Color freelanceBg = Color(0xFFDBEAFE);
  static const Color freelanceFg = Color(0xFF2563EB);
  static const Color businessBg = Color(0xFFF3E8FF);
  static const Color businessFg = Color(0xFF7C3AED);
  static const Color giftBg = Color(0xFFFCE7F3);
  static const Color giftFg = Color(0xFFDB2777);

  /// Returns a soft pastel background for a category.
  static Color categoryBackground(String category) {
    switch (category) {
      case 'Food':
        return foodBg;
      case 'Transport':
        return transportBg;
      case 'Shopping':
        return shoppingBg;
      case 'Bills':
        return billsBg;
      case 'Entertainment':
        return entertainmentBg;
      case 'Health':
        return healthBg;
      case 'Education':
        return educationBg;
      case 'Salary':
        return salaryBg;
      case 'Freelance':
        return freelanceBg;
      case 'Business':
        return businessBg;
      case 'Gift':
        return giftBg;
      default:
        return otherBg;
    }
  }

  /// Returns a saturated foreground color for a category.
  static Color categoryForeground(String category) {
    switch (category) {
      case 'Food':
        return foodFg;
      case 'Transport':
        return transportFg;
      case 'Shopping':
        return shoppingFg;
      case 'Bills':
        return billsFg;
      case 'Entertainment':
        return entertainmentFg;
      case 'Health':
        return healthFg;
      case 'Education':
        return educationFg;
      case 'Salary':
        return salaryFg;
      case 'Freelance':
        return freelanceFg;
      case 'Business':
        return businessFg;
      case 'Gift':
        return giftFg;
      default:
        return otherFg;
    }
  }

  // ── Gradients ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF7F8F6), Color(0xFFEDFCF5), Color(0xFFF7F8F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Soft card shadow ────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F766E).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Chart colors ────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF0F766E), // Primary teal
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF6366F1), // Indigo
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
    Color(0xFF8B5CF6), // Violet
  ];

  static const Color chartGridLine = Color(0xFFE2E8F0);
  static const Color chartTooltipBg = Color(0xFF12343B);
}
