import 'package:flutter/material.dart';

/// Savings goal model representing a user's financial target.
///
/// Each goal tracks a name, target amount, current saved amount,
/// target date, and optional icon. The goal is marked as completed
/// when [currentAmount] >= [targetAmount].
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String iconName;
  final bool isCompleted;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    this.iconName = 'savings',
    this.isCompleted = false,
    required this.createdAt,
  });

  // ── Preset icons ────────────────────────────────────────────────

  static const List<String> availableIcons = [
    'savings',
    'flag',
    'home',
    'car',
    'flight',
    'school',
    'phone',
    'laptop',
    'gift',
    'heart',
    'star',
    'other',
  ];

  static IconData iconFromName(String iconName) {
    const icons = <String, IconData>{
      'savings': Icons.savings_outlined,
      'flag': Icons.flag_outlined,
      'home': Icons.home_outlined,
      'car': Icons.directions_car_outlined,
      'flight': Icons.flight_outlined,
      'school': Icons.school_outlined,
      'phone': Icons.phone_iphone_outlined,
      'laptop': Icons.laptop_mac_outlined,
      'gift': Icons.card_giftcard_outlined,
      'heart': Icons.favorite_outline,
      'star': Icons.star_outline,
      'other': Icons.more_horiz_outlined,
    };
    return icons[iconName] ?? Icons.savings_outlined;
  }

  // ── Computed properties ─────────────────────────────────────────

  /// Progress as a value between 0.0 and 1.0+.
  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, double.infinity);
  }

  /// Remaining amount to reach the target.
  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Whether the target amount has been reached.
  bool get reachedTarget => currentAmount >= targetAmount;

  /// Days remaining until the target date. Negative if past due.
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  // ── Helpers ───────────────────────────────────────────────────

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get formattedTargetDate {
    final day = targetDate.day;
    final month = _monthNames[targetDate.month - 1];
    final year = targetDate.year;
    return '$day $month $year';
  }

  String get formattedCurrentAmount => '\$${currentAmount.toStringAsFixed(2)}';
  String get formattedTargetAmount => '\$${targetAmount.toStringAsFixed(2)}';
  String get formattedRemaining => '\$${remaining.toStringAsFixed(2)}';

  String get daysRemainingText {
    if (daysRemaining < 0) return '${-daysRemaining} days overdue';
    if (daysRemaining == 0) return 'Due today';
    return '$daysRemaining days left';
  }

  // ── JSON serialization ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'iconName': iconName,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    DateTime parsedTargetDate;
    try {
      parsedTargetDate = DateTime.parse(json['targetDate'] as String);
    } catch (_) {
      parsedTargetDate = DateTime.now().add(const Duration(days: 30));
    }

    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: parsedTargetDate,
      iconName: json['iconName'] as String? ?? 'savings',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  // ── Copy with ─────────────────────────────────────────────────────

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? iconName,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconName: iconName ?? this.iconName,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
