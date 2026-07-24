import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_model.dart';

/// Handles all local persistence for [Expense] entries.
///
/// Uses SharedPreferences to store expenses as a JSON-encoded list.
/// This keeps things simple — no database setup required.
class StorageService {
  // The key used to store the expense list in SharedPreferences.
  static const String _storageKey = 'expenses';

  // ── Singleton pattern ──────────────────────────────────────────────

  // Private constructor — prevents external instantiation.
  StorageService._();

  // The single instance of StorageService used across the app.
  static final StorageService instance = StorageService._();

  // ── Load expenses ──────────────────────────────────────────────────

  /// Returns all saved expenses, sorted by date (newest first).
  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the raw JSON string; returns empty string if nothing stored.
    final jsonString = prefs.getString(_storageKey) ?? '[]';

    // Decode the JSON string into a list of maps.
    final List<dynamic> jsonList = jsonDecode(jsonString);

    // Convert each map into an Expense object.
    final expenses = jsonList
        .map((item) => Expense.fromJson(item as Map<String, dynamic>))
        .toList();

    // Sort by date descending (newest expenses appear first).
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return expenses;
  }

  // ── Save a new expense ─────────────────────────────────────────────

  /// Adds a new expense to the list and saves it.
  Future<void> addExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();

    // Get the current list.
    final expenses = await getExpenses();

    // Add the new expense at the beginning.
    expenses.insert(0, expense);

    // Encode and save.
    await _saveAll(expenses, prefs);
  }

  // ── Delete an expense ──────────────────────────────────────────────

  /// Removes an expense by its [id].
  Future<void> deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();

    final expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == id);

    await _saveAll(expenses, prefs);
  }

  // ── Computed totals ────────────────────────────────────────────────

  /// Total amount of all expenses (isExpense == true).
  Future<double> getTotalExpenses() async {
    final expenses = await getExpenses();
    double total = 0;
    for (final e in expenses) {
      if (e.isExpense) total += e.amount;
    }
    return total;
  }

  /// Total amount of all income entries (isExpense == false).
  Future<double> getTotalIncome() async {
    final expenses = await getExpenses();
    double total = 0;
    for (final e in expenses) {
      if (!e.isExpense) total += e.amount;
    }
    return total;
  }

  /// Balance = total income - total expenses.
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expenses = await getTotalExpenses();
    return income - expenses;
  }

  // ── Private helper ─────────────────────────────────────────────────

  /// Encodes the full list and writes it to SharedPreferences.
  Future<void> _saveAll(List<Expense> expenses, SharedPreferences prefs) async {
    final jsonList = expenses.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}
