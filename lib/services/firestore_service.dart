import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';
import '../services/auth_service.dart';

/// Handles all Firestore persistence for [Expense] entries.
///
/// Each user's expenses are stored under: users/{uid}/expenses/{expenseId}
/// This keeps every user's data isolated and secure.
class FirestoreService {
  // ── Singleton ──────────────────────────────────────────────────────

  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  // ── Firestore reference helpers ────────────────────────────────────

  /// Returns the expenses collection for the currently logged-in user.
  /// Throws if no user is authenticated.
  CollectionReference<Map<String, dynamic>> get _expensesCol {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses');
  }

  // ── Get user display name ──────────────────────────────────────────

  /// Fetches the user's name from Firestore.
  /// Falls back to the Auth display name, then to "User".
  Future<String> getUserName() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return 'User';

    // Try Firestore first.
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return doc.data()!['name'] as String? ?? 'User';
    }

    // Fallback to Auth profile.
    return user.displayName ?? 'User';
  }

  // ── Add expense ────────────────────────────────────────────────────

  /// Saves a new expense to the user's Firestore sub-collection.
  Future<void> addExpense(Expense expense) async {
    await _expensesCol.doc(expense.id).set(expense.toJson());
  }

  // ── Get all expenses ───────────────────────────────────────────────

  /// Returns all expenses for the current user, sorted newest first.
  Future<List<Expense>> getExpenses() async {
    final snapshot = await _expensesCol.orderBy('date', descending: true).get();

    return snapshot.docs
        .map((doc) => Expense.fromJson(doc.data()))
        .toList();
  }

  // ── Delete expense ─────────────────────────────────────────────────

  /// Removes an expense by its [id].
  Future<void> deleteExpense(String id) async {
    await _expensesCol.doc(id).delete();
  }

  // ── Error mapping ──────────────────────────────────────────────────

  /// Converts a Firestore failure into a clear, actionable message
  /// instead of hiding every problem behind a generic
  /// "check your internet connection" text.
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
