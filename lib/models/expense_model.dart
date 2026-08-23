import 'package:flutter/material.dart';

/// Expense model representing a single income or expense entry.
///
/// Each entry has a title, amount, category, date, and type (income/expense).
/// Supports JSON serialization for local storage persistence.
class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
  });

  // ── Predefined categories ──────────────────────────────────────────

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Education',
    'Health',
    'Entertainment',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Gift',
    'Other',
  ];

  // ── Category → Icon mapping ────────────────────────────────────────

  static IconData categoryIcon(String category) {
    const icons = <String, IconData>{
      'Food': Icons.restaurant_outlined,
      'Shopping': Icons.shopping_bag_outlined,
      'Transport': Icons.directions_car_outlined,
      'Entertainment': Icons.movie_outlined,
      'Bills': Icons.receipt_long_outlined,
      'Health': Icons.favorite_outline,
      'Education': Icons.school_outlined,
      'Salary': Icons.account_balance_outlined,
      'Freelance': Icons.laptop_mac_outlined,
      'Business': Icons.business_outlined,
      'Investment': Icons.trending_up_outlined, // kept for old data
      'Gift': Icons.card_giftcard_outlined,
      'Other': Icons.more_horiz_outlined,
    };
    return icons[category] ?? Icons.help_outline;
  }

  // ── JSON serialization ─────────────────────────────────────────────

  /// Convert this expense into a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'isExpense': isExpense,
      };

  /// Create an [Expense] from a JSON map.
  /// Handles missing or malformed dates safely — falls back to now.
  factory Expense.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: parsedDate,
      isExpense: json['isExpense'] as bool,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Returns the formatted amount with a + or - prefix.
  String get formattedAmount {
    final formatted = amount.toStringAsFixed(2);
    return isExpense ? '-\$$formatted' : '+\$$formatted';
  }

  /// Returns a user-friendly date string.
  /// Shows "Today", "Yesterday", or "23 Aug 2026" for older dates.
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    final day = date.day;
    final month = _monthNames[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }
}
