import '../models/expense_model.dart';

/// Data models for charts
class MonthlyData {
  final String label;
  final double income;
  final double expense;

  const MonthlyData({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class CategoryData {
  final String category;
  final double amount;
  final double percentage;
  final int colorIndex;

  const CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.colorIndex,
  });
}

/// Service to compute analytics data from expenses list.
/// All computations are local - no Firestore reads needed.
class AnalyticsService {
  AnalyticsService._();

  /// Get last 6 months of income vs expense data for bar/line chart.
  /// Returns list of [MonthlyData] sorted from oldest to newest.
  static List<MonthlyData> getLast6MonthsData(List<Expense> expenses) {
    final now = DateTime.now();
    final months = <MonthlyData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthAbbreviation(month.month);
      final year = month.year;

      double income = 0;
      double expense = 0;

      for (final e in expenses) {
        if (e.date.year == year && e.date.month == month.month) {
          if (e.isExpense) {
            expense += e.amount;
          } else {
            income += e.amount;
          }
        }
      }

      months.add(MonthlyData(
        label: '$monthName\n${year.toString().substring(2)}',
        income: income,
        expense: expense,
      ));
    }

    return months;
  }

  /// Get current month expense breakdown by category.
  /// Returns list of [CategoryData] sorted by amount descending.
  static List<CategoryData> getCurrentMonthCategoryBreakdown(
      List<Expense> expenses) {
    final now = DateTime.now();
    final categoryMap = <String, double>{};
    double totalExpenses = 0;

    for (final e in expenses) {
      if (e.date.year == now.year &&
          e.date.month == now.month &&
          e.isExpense) {
        categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
        totalExpenses += e.amount;
      }
    }

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <CategoryData>[];
    int colorIndex = 0;

    for (final entry in entries) {
      final percentage = totalExpenses > 0
          ? (entry.value / totalExpenses * 100)
          : 0.0;

      result.add(CategoryData(
        category: entry.key,
        amount: entry.value,
        percentage: percentage,
        colorIndex: colorIndex % 10,
      ));
      colorIndex++;
    }

    return result;
  }

  /// Get current month summary statistics.
  static Map<String, double> getCurrentMonthSummary(List<Expense> expenses) {
    final now = DateTime.now();
    double income = 0;
    double expense = 0;

    for (final e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        if (e.isExpense) {
          expense += e.amount;
        } else {
          income += e.amount;
        }
      }
    }

    return {
      'income': income,
      'expense': expense,
      'savings': income - expense,
    };
  }

  /// Get monthly income vs expense totals for current month.
  static Map<String, double> getCurrentMonthTotals(List<Expense> expenses) {
    final now = DateTime.now();
    double income = 0;
    double expense = 0;

    for (final e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        if (e.isExpense) {
          expense += e.amount;
        } else {
          income += e.amount;
        }
      }
    }

    return {
      'income': income,
      'expense': expense,
    };
  }

  static String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
