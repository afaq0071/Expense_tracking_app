/// Budget model representing a monthly budget.
///
/// Each budget has a total amount and optional category-specific budgets.
/// Stores data under: users/{uid}/budgets/{budgetId}
class Budget {
  final String id;
  final String name;
  final double totalAmount;
  final int month; // 1-12
  final int year;
  final Map<String, double> categoryBudgets; // category -> amount
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.month,
    required this.year,
    this.categoryBudgets = const {},
    required this.createdAt,
  });

  // ── JSON serialization ─────────────────────────────────────────────

  /// Convert this budget into a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalAmount': totalAmount,
        'month': month,
        'year': year,
        'categoryBudgets': categoryBudgets,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create a [Budget] from a JSON map.
  factory Budget.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    // Parse category budgets safely
    Map<String, double> parsedCategoryBudgets = {};
    if (json['categoryBudgets'] != null) {
      final raw = json['categoryBudgets'] as Map<String, dynamic>;
      for (final entry in raw.entries) {
        parsedCategoryBudgets[entry.key] = (entry.value as num).toDouble();
      }
    }

    return Budget(
      id: json['id'] as String,
      name: json['name'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      categoryBudgets: parsedCategoryBudgets,
      createdAt: parsedCreatedAt,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Returns formatted month name (e.g., "January 2026").
  String get monthLabel => '${_monthNames[month - 1]} $year';

  /// Returns short month name (e.g., "Jan").
  String get shortMonthLabel => _monthNames[month - 1].substring(0, 3);

  /// Check if this budget is for the current month.
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  /// Copy with changes.
  Budget copyWith({
    String? id,
    String? name,
    double? totalAmount,
    int? month,
    int? year,
    Map<String, double>? categoryBudgets,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
