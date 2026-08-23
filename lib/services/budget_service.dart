import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';

/// Handles all Firestore persistence for [Budget] entries.
///
/// Each user's budgets are stored under: users/{uid}/budgets/{budgetId}
/// This keeps every user's data isolated and secure.
class BudgetService {
  // ── Singleton ──────────────────────────────────────────────────────

  BudgetService._();
  static final BudgetService instance = BudgetService._();

  // ── Firestore reference helpers ────────────────────────────────────

  /// Returns the budgets collection for the currently logged-in user.
  /// Throws if no user is authenticated.
  CollectionReference<Map<String, dynamic>> get _budgetsCol {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets');
  }

  // ── Add budget ────────────────────────────────────────────────────

  /// Saves a new budget to the user's Firestore sub-collection.
  Future<void> addBudget(Budget budget) async {
    await _budgetsCol.doc(budget.id).set(budget.toJson());
  }

  // ── Update budget ─────────────────────────────────────────────────

  /// Updates an existing budget.
  Future<void> updateBudget(Budget budget) async {
    await _budgetsCol.doc(budget.id).update(budget.toJson());
  }

  // ── Get all budgets ───────────────────────────────────────────────

  /// Returns all budgets for the current user, sorted by date descending.
  Future<List<Budget>> getBudgets() async {
    final snapshot = await _budgetsCol.orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map((doc) => Budget.fromJson(doc.data()))
        .toList();
  }

  // ── Get budget by month and year ──────────────────────────────────

  /// Returns the budget for a specific month and year, or null if not found.
  Future<Budget?> getBudgetForMonth(int month, int year) async {
    final snapshot = await _budgetsCol
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Budget.fromJson(snapshot.docs.first.data());
  }

  // ── Delete budget ─────────────────────────────────────────────────

  /// Removes a budget by its [id].
  Future<void> deleteBudget(String id) async {
    await _budgetsCol.doc(id).delete();
  }

  // ── Calculate spent amounts ───────────────────────────────────────

  /// Calculates total spent for a given month/year from expenses.
  /// Only counts expense transactions, not income.
  double calculateTotalSpent(List<Expense> expenses, int month, int year) {
    double total = 0;
    for (final expense in expenses) {
      if (expense.isExpense &&
          expense.date.month == month &&
          expense.date.year == year) {
        total += expense.amount;
      }
    }
    return total;
  }

  /// Calculates spent amount for a specific category in a given month/year.
  double calculateCategorySpent(
      List<Expense> expenses, String category, int month, int year) {
    double total = 0;
    for (final expense in expenses) {
      if (expense.isExpense &&
          expense.category == category &&
          expense.date.month == month &&
          expense.date.year == year) {
        total += expense.amount;
      }
    }
    return total;
  }

  // ── Calculate percentage ──────────────────────────────────────────

  /// Calculates percentage of budget used.
  /// Returns value between 0.0 and 1.0+ (can exceed 1.0 for over-budget).
  double calculatePercentage(double spent, double budget) {
    if (budget <= 0) return 0;
    return spent / budget;
  }

  // ── Get warning level ─────────────────────────────────────────────

  /// Returns warning level based on spending percentage.
  /// 0 = normal, 1 = warning (>=80%), 2 = exceeded (>100%).
  int getWarningLevel(double percentage) {
    if (percentage > 1.0) return 2;
    if (percentage >= 0.8) return 1;
    return 0;
  }

  // ── Error mapping ──────────────────────────────────────────────────

  /// Converts a Firestore failure into a clear, actionable message.
  static String describeError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "Your account doesn't have permission to access this "
              'data. Make sure you are signed in and that the Firestore '
              'security rules allow owners to read and write their data.';
        case 'unauthenticated':
          return 'Your session has expired. Please log in again.';
        case 'unavailable':
          return 'Cannot reach Firestore right now. '
              'Check your internet connection and try again.';
        case 'network-request-failed':
          return 'Network error. '
              'Check your internet connection and try again.';
        case 'failed-precondition':
          return 'Firestore is not ready yet. Please try again shortly.';
        case 'deadline-exceeded':
          return 'The request timed out. Please try again.';
        case 'resource-exhausted':
          return 'Firestore quota exceeded for today. Please try again later.';
        case 'invalid-argument':
          return 'The entry could not be saved because some data was invalid.';
        default:
          return 'Firestore error (${error.code}). Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
