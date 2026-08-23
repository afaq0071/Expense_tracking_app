import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_app/models/expense_model.dart';

void main() {
  // ── JSON serialization ─────────────────────────────────────────────

  group('Expense JSON serialization', () {
    final date = DateTime(2026, 8, 22, 10, 30);
    final expense = Expense(
      id: 'abc-123',
      title: 'Groceries',
      amount: 42.5,
      category: 'Food',
      date: date,
      isExpense: true,
    );

    test('toJson produces the expected map', () {
      expect(expense.toJson(), {
        'id': 'abc-123',
        'title': 'Groceries',
        'amount': 42.5,
        'category': 'Food',
        'date': date.toIso8601String(),
        'isExpense': true,
      });
    });

    test('fromJson restores every field', () {
      final restored = Expense.fromJson(expense.toJson());

      expect(restored.id, expense.id);
      expect(restored.title, expense.title);
      expect(restored.amount, expense.amount);
      expect(restored.category, expense.category);
      expect(restored.date, expense.date);
      expect(restored.isExpense, expense.isExpense);
    });

    test('round-trip through JSON preserves every field', () {
      final restored =
          Expense.fromJson(Expense.fromJson(expense.toJson()).toJson());

      expect(restored.id, expense.id);
      expect(restored.title, expense.title);
      expect(restored.amount, expense.amount);
      expect(restored.category, expense.category);
      expect(restored.date, expense.date);
      expect(restored.isExpense, expense.isExpense);
    });
  });

  // ── Formatted amounts ──────────────────────────────────────────────

  group('Expense.formattedAmount', () {
    test('expense entries are prefixed with a minus sign', () {
      final expense = Expense(
        id: '1',
        title: 'Coffee',
        amount: 4.25,
        category: 'Food',
        date: DateTime(2026, 8, 22),
        isExpense: true,
      );
      expect(expense.formattedAmount, '-\$4.25');
    });

    test('income entries are prefixed with a plus sign', () {
      final income = Expense(
        id: '2',
        title: 'Salary',
        amount: 1200,
        category: 'Salary',
        date: DateTime(2026, 1, 1),
        isExpense: false,
      );
      expect(income.formattedAmount, '+\$1200.00');
    });
  });

  // ── Categories ─────────────────────────────────────────────────────

  group('Expense categories', () {
    test('expenseCategories contains the expected list', () {
      expect(Expense.expenseCategories, [
        'Food',
        'Transport',
        'Shopping',
        'Bills',
        'Education',
        'Health',
        'Entertainment',
        'Other',
      ]);
    });

    test('incomeCategories contains the expected list', () {
      expect(Expense.incomeCategories, [
        'Salary',
        'Freelance',
        'Business',
        'Gift',
        'Other',
      ]);
    });

    test('every predefined category maps to an icon', () {
      final all = [...Expense.expenseCategories, ...Expense.incomeCategories];
      for (final category in all) {
        expect(
          Expense.categoryIcon(category),
          isNotNull,
          reason: '$category should map to an icon',
        );
      }
    });

    test('custom category falls back to help_outline icon', () {
      expect(Expense.categoryIcon('Gym'), Icons.help_outline);
      expect(Expense.categoryIcon('Fuel'), Icons.help_outline);
      expect(Expense.categoryIcon('Rent'), Icons.help_outline);
    });

    test('Business category maps to business_outlined icon', () {
      expect(Expense.categoryIcon('Business'), Icons.business_outlined);
    });

    test('custom category round-trips through JSON', () {
      final expense = Expense(
        id: '1',
        title: 'Gym',
        amount: 50,
        category: 'Gym',
        date: DateTime(2026, 8, 22),
        isExpense: true,
      );
      final restored = Expense.fromJson(expense.toJson());
      expect(restored.category, 'Gym');
    });
  });

  // ── Formatted dates ──────────────────────────────────────────────

  group('Expense.formattedDate', () {
    test('shows "Today" for current date', () {
      final expense = Expense(
        id: '1',
        title: 'Lunch',
        amount: 15,
        category: 'Food',
        date: DateTime.now(),
        isExpense: true,
      );
      expect(expense.formattedDate, 'Today');
    });

    test('shows "Yesterday" for previous date', () {
      final expense = Expense(
        id: '1',
        title: 'Bus fare',
        amount: 3,
        category: 'Transport',
        date: DateTime.now().subtract(const Duration(days: 1)),
        isExpense: true,
      );
      expect(expense.formattedDate, 'Yesterday');
    });

    test('shows formatted date for older entries', () {
      final expense = Expense(
        id: '1',
        title: 'Salary',
        amount: 3000,
        category: 'Salary',
        date: DateTime(2026, 3, 15),
        isExpense: false,
      );
      expect(expense.formattedDate, '15 Mar 2026');
    });
  });

  // ── Safe fromJson ────────────────────────────────────────────────

  group('Expense.fromJson safety', () {
    test('handles missing date field gracefully', () {
      final json = {
        'id': '1',
        'title': 'Test',
        'amount': 10,
        'category': 'Other',
        'isExpense': true,
      };
      // Should not throw — falls back to DateTime.now()
      expect(() => Expense.fromJson(json), returnsNormally);
    });

    test('handles malformed date string gracefully', () {
      final json = {
        'id': '1',
        'title': 'Test',
        'amount': 10,
        'category': 'Other',
        'date': 'not-a-date',
        'isExpense': true,
      };
      // Should not throw — falls back to DateTime.now()
      expect(() => Expense.fromJson(json), returnsNormally);
    });
  });

  // ── Search filtering ─────────────────────────────────────────────

  group('Expense search filtering', () {
    final expenses = [
      Expense(
        id: '1',
        title: 'Groceries',
        amount: 50,
        category: 'Food',
        date: DateTime(2026, 8, 22),
        isExpense: true,
      ),
      Expense(
        id: '2',
        title: 'Bus fare',
        amount: 3,
        category: 'Transport',
        date: DateTime(2026, 8, 21),
        isExpense: true,
      ),
      Expense(
        id: '3',
        title: 'Salary',
        amount: 3000,
        category: 'Salary',
        date: DateTime(2026, 8, 1),
        isExpense: false,
      ),
      Expense(
        id: '4',
        title: 'Gym membership',
        amount: 40,
        category: 'Gym',
        date: DateTime(2026, 8, 20),
        isExpense: true,
      ),
    ];

    /// Mirrors the filtering logic used in HomeScreen.
    List<Expense> filter(List<Expense> list, String query) {
      if (query.isEmpty) return list;
      final q = query.toLowerCase();
      return list
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q))
          .toList();
    }

    test('empty query returns all transactions', () {
      expect(filter(expenses, ''), expenses);
    });

    test('matches by title (case-insensitive)', () {
      final result = filter(expenses, 'groceries');
      expect(result.length, 1);
      expect(result.first.title, 'Groceries');
    });

    test('matches by category (case-insensitive)', () {
      final result = filter(expenses, 'transport');
      expect(result.length, 1);
      expect(result.first.category, 'Transport');
    });

    test('partial match works', () {
      final result = filter(expenses, 'gym');
      expect(result.length, 1);
      expect(result.first.title, 'Gym membership');
    });

    test('returns empty list when nothing matches', () {
      final result = filter(expenses, 'xyz');
      expect(result, isEmpty);
    });

    test('matches across multiple fields', () {
      // "salary" matches both title "Salary" and category "Salary"
      final result = filter(expenses, 'salary');
      expect(result.length, 1);
      expect(result.first.title, 'Salary');
    });
  });

  // ── Combined filter logic ───────────────────────────────────────────

  group('Combined filtering logic', () {
    final expenses = [
      Expense(
        id: '1',
        title: 'Groceries',
        amount: 42.5,
        category: 'Food',
        date: DateTime(2026, 8, 22),
        isExpense: true,
      ),
      Expense(
        id: '2',
        title: 'Uber ride',
        amount: 15,
        category: 'Transport',
        date: DateTime(2026, 8, 21),
        isExpense: true,
      ),
      Expense(
        id: '3',
        title: 'Salary',
        amount: 3000,
        category: 'Salary',
        date: DateTime(2026, 8, 1),
        isExpense: false,
      ),
      Expense(
        id: '4',
        title: 'Gym membership',
        amount: 40,
        category: 'Gym',
        date: DateTime(2026, 8, 20),
        isExpense: true,
      ),
      Expense(
        id: '5',
        title: 'Freelance work',
        amount: 500,
        category: 'Business',
        date: DateTime(2026, 7, 15),
        isExpense: false,
      ),
    ];

    /// Mirrors the full filter logic from HomeScreen._filteredExpenses.
    List<Expense> applyFilters(
      List<Expense> list, {
      String query = '',
      String filterType = 'all',
      String? filterCategory,
      DateTime? startDate,
      DateTime? endDate,
    }) {
      var result = list;

      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        result = result.where((e) {
          return e.title.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q);
        }).toList();
      }

      if (filterType == 'income') {
        result = result.where((e) => !e.isExpense).toList();
      } else if (filterType == 'expense') {
        result = result.where((e) => e.isExpense).toList();
      }

      if (filterCategory != null) {
        result = result.where((e) => e.category == filterCategory).toList();
      }

      if (startDate != null) {
        result = result.where((e) => !e.date.isBefore(startDate)).toList();
      }
      if (endDate != null) {
        final endDay = DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1));
        result = result.where((e) => e.date.isBefore(endDay)).toList();
      }

      return result;
    }

    test('no filters returns all transactions', () {
      expect(applyFilters(expenses), expenses);
    });

    test('filterType=expense returns only expenses', () {
      final result = applyFilters(expenses, filterType: 'expense');
      expect(result.length, 3);
      expect(result.every((e) => e.isExpense), true);
    });

    test('filterType=income returns only income', () {
      final result = applyFilters(expenses, filterType: 'income');
      expect(result.length, 2);
      expect(result.every((e) => !e.isExpense), true);
    });

    test('filterCategory returns only matching category', () {
      final result = applyFilters(expenses, filterCategory: 'Food');
      expect(result.length, 1);
      expect(result.first.category, 'Food');
    });

    test('startDate filters out earlier dates', () {
      final result =
          applyFilters(expenses, startDate: DateTime(2026, 8, 20));
      expect(result.length, 3); // Groceries(22), Uber(21), Gym(20)
    });

    test('endDate filters out later dates', () {
      final result =
          applyFilters(expenses, endDate: DateTime(2026, 8, 21));
      expect(result.length, 4); // Uber(21), Gym(20), Salary(1), Freelance(15 Jul)
    });

    test('date range filters correctly', () {
      final result = applyFilters(
        expenses,
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 22),
      );
      expect(result.length, 3); // Groceries(22), Uber(21), Gym(20)
    });

    test('search + type filter combine correctly', () {
      final result = applyFilters(
        expenses,
        query: 'gym',
        filterType: 'expense',
      );
      expect(result.length, 1);
      expect(result.first.title, 'Gym membership');
    });

    test('search + category filter combine correctly', () {
      final result = applyFilters(
        expenses,
        query: 'salary',
        filterCategory: 'Salary',
      );
      expect(result.length, 1);
      expect(result.first.title, 'Salary');
    });

    test('all filters combined returns empty when nothing matches', () {
      final result = applyFilters(
        expenses,
        query: 'groceries',
        filterType: 'income',
        filterCategory: 'Food',
        startDate: DateTime(2026, 8, 22),
        endDate: DateTime(2026, 8, 22),
      );
      expect(result, isEmpty); // Groceries is expense, not income
    });

    test('multiple filters narrowing down results', () {
      final result = applyFilters(
        expenses,
        filterType: 'expense',
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 21),
      );
      expect(result.length, 2); // Uber(21), Gym(20)
    });
  });

  // ── Available categories helper ─────────────────────────────────────

  group('Available categories from expenses list', () {
    test('extracts unique categories and sorts them', () {
      final expenses = [
        Expense(id: '1', title: 'A', amount: 10, category: 'Food', date: DateTime.now(), isExpense: true),
        Expense(id: '2', title: 'B', amount: 20, category: 'Transport', date: DateTime.now(), isExpense: true),
        Expense(id: '3', title: 'C', amount: 30, category: 'Food', date: DateTime.now(), isExpense: true),
        Expense(id: '4', title: 'D', amount: 40, category: 'Gym', date: DateTime.now(), isExpense: true),
      ];
      final cats = <String>{};
      for (final e in expenses) {
        cats.add(e.category);
      }
      final sorted = cats.toList()..sort();
      expect(sorted, ['Food', 'Gym', 'Transport']);
    });
  });

  // ── Current-month statistics ────────────────────────────────────────

  group('Current-month statistics', () {
    final now = DateTime.now();

    test('computes income total for current month', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 3000,
          category: 'Salary',
          date: now,
          isExpense: false,
        ),
        Expense(
          id: '2',
          title: 'Freelance',
          amount: 500,
          category: 'Freelance',
          date: now,
          isExpense: false,
        ),
        Expense(
          id: '3',
          title: 'Last month salary',
          amount: 3000,
          category: 'Salary',
          date: DateTime(now.year, now.month - 1, 15),
          isExpense: false,
        ),
      ];
      final current = expenses.where((e) {
        return e.date.year == now.year &&
            e.date.month == now.month &&
            !e.isExpense;
      }).toList();
      final total = current.fold(0.0, (sum, e) => sum + e.amount);
      expect(total, 3500);
    });

    test('computes expense total for current month', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Food',
          amount: 42,
          category: 'Food',
          date: now,
          isExpense: true,
        ),
        Expense(
          id: '2',
          title: 'Old food',
          amount: 100,
          category: 'Food',
          date: DateTime(now.year, now.month - 1, 10),
          isExpense: true,
        ),
      ];
      final current = expenses.where((e) {
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.isExpense;
      }).toList();
      final total = current.fold(0.0, (sum, e) => sum + e.amount);
      expect(total, 42);
    });

    test('savings is income minus expenses', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 3000,
          category: 'Salary',
          date: now,
          isExpense: false,
        ),
        Expense(
          id: '2',
          title: 'Food',
          amount: 42,
          category: 'Food',
          date: now,
          isExpense: true,
        ),
      ];
      final income =
          expenses.where((e) => !e.isExpense).fold(0.0, (s, e) => s + e.amount);
      final expense =
          expenses.where((e) => e.isExpense).fold(0.0, (s, e) => s + e.amount);
      expect(income - expense, 2958);
    });

    test('savings can be negative (overspending)', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 500,
          category: 'Salary',
          date: now,
          isExpense: false,
        ),
        Expense(
          id: '2',
          title: 'Shopping',
          amount: 800,
          category: 'Shopping',
          date: now,
          isExpense: true,
        ),
      ];
      final income =
          expenses.where((e) => !e.isExpense).fold(0.0, (s, e) => s + e.amount);
      final expense =
          expenses.where((e) => e.isExpense).fold(0.0, (s, e) => s + e.amount);
      expect(income - expense, -300);
    });

    test('empty expenses returns zero for all month stats', () {
      final expenses = <Expense>[];
      final income =
          expenses.where((e) => !e.isExpense).fold(0.0, (s, e) => s + e.amount);
      final expense =
          expenses.where((e) => e.isExpense).fold(0.0, (s, e) => s + e.amount);
      expect(income, 0);
      expect(expense, 0);
      expect(income - expense, 0);
    });
  });

  // ── Category breakdown ──────────────────────────────────────────────

  group('Category breakdown', () {
    final now = DateTime.now();

    test('groups expenses by category and sums amounts', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Lunch',
          amount: 15,
          category: 'Food',
          date: now,
          isExpense: true,
        ),
        Expense(
          id: '2',
          title: 'Dinner',
          amount: 30,
          category: 'Food',
          date: now,
          isExpense: true,
        ),
        Expense(
          id: '3',
          title: 'Uber',
          amount: 12,
          category: 'Transport',
          date: now,
          isExpense: true,
        ),
      ];
      final map = <String, double>{};
      for (final e in expenses) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
      expect(map['Food'], 45);
      expect(map['Transport'], 12);
    });

    test('sorts categories by amount descending', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Uber',
          amount: 12,
          category: 'Transport',
          date: now,
          isExpense: true,
        ),
        Expense(
          id: '2',
          title: 'Lunch',
          amount: 50,
          category: 'Food',
          date: now,
          isExpense: true,
        ),
        Expense(
          id: '3',
          title: 'Movie',
          amount: 20,
          category: 'Entertainment',
          date: now,
          isExpense: true,
        ),
      ];
      final map = <String, double>{};
      for (final e in expenses) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
      final entries = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      expect(entries.first.key, 'Food');
      expect(entries.last.key, 'Transport');
    });

    test('only includes expenses, not income', () {
      final expenses = [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 3000,
          category: 'Salary',
          date: now,
          isExpense: false,
        ),
        Expense(
          id: '2',
          title: 'Food',
          amount: 42,
          category: 'Food',
          date: now,
          isExpense: true,
        ),
      ];
      final expensesOnly = expenses.where((e) => e.isExpense).toList();
      final map = <String, double>{};
      for (final e in expensesOnly) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
      expect(map.length, 1);
      expect(map.containsKey('Food'), true);
    });

    test('handles empty list gracefully', () {
      final expenses = <Expense>[];
      final map = <String, double>{};
      for (final e in expenses) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
      expect(map.isEmpty, true);
    });

    test('percentage calculation works correctly', () {
      final total = 200.0;
      final foodAmount = 80.0;
      final pct = (foodAmount / total * 100).toStringAsFixed(1);
      expect(pct, '40.0');
    });
  });
}
