/// Recurring transaction template.
///
/// Defines how often a transaction should repeat. The actual transactions
/// are generated from this template and stored in the regular expenses
/// collection with a `recurringTemplateId` field linking back to this template.
///
/// Stored under: users/{uid}/recurring_transactions/{templateId}
class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final bool isExpense;
  final DateTime startDate;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastGeneratedDate;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.startDate,
    required this.frequency,
    this.isActive = true,
    required this.createdAt,
    this.lastGeneratedDate,
  });

  // ── JSON serialization ─────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'isExpense': isExpense,
        'startDate': startDate.toIso8601String(),
        'frequency': frequency,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    DateTime parsedStartDate;
    try {
      parsedStartDate = DateTime.parse(json['startDate'] as String);
    } catch (_) {
      parsedStartDate = DateTime.now();
    }

    DateTime? parsedLastGenerated;
    if (json['lastGeneratedDate'] != null) {
      try {
        parsedLastGenerated = DateTime.parse(json['lastGeneratedDate'] as String);
      } catch (_) {
        parsedLastGenerated = null;
      }
    }

    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      isExpense: json['isExpense'] as bool,
      startDate: parsedStartDate,
      frequency: json['frequency'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastGeneratedDate: parsedLastGenerated,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }

  String get formattedAmount {
    final formatted = amount.toStringAsFixed(2);
    return isExpense ? '-\$$formatted' : '+\$$formatted';
  }

  String get formattedStartDate {
    return '${startDate.day} ${_monthNames[startDate.month - 1]} ${startDate.year}';
  }

  /// Returns the next occurrence date after [after].
  DateTime nextOccurrence(DateTime after) {
    switch (frequency) {
      case 'daily':
        return after.add(const Duration(days: 1));
      case 'weekly':
        return after.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(after.year, after.month + 1, after.day);
      case 'yearly':
        return DateTime(after.year + 1, after.month, after.day);
      default:
        return after.add(const Duration(days: 1));
    }
  }

  /// Returns the date of the first occurrence on or after [startDate].
  DateTime get firstOccurrence => startDate;

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    bool? isExpense,
    DateTime? startDate,
    String? frequency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastGeneratedDate,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isExpense: isExpense ?? this.isExpense,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
    );
  }
}
