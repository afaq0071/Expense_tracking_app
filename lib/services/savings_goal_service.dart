import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/savings_goal_model.dart';
import '../services/auth_service.dart';

/// Handles all Firestore persistence for [SavingsGoal] entries.
///
/// Each user's goals are stored under: users/{uid}/savings_goals/{goalId}
/// This keeps every user's data isolated and secure.
class SavingsGoalService {
  // ── Singleton ──────────────────────────────────────────────────────

  SavingsGoalService._();
  static final SavingsGoalService instance = SavingsGoalService._();

  // ── Firestore reference helpers ────────────────────────────────────

  /// Returns the savings goals collection for the currently logged-in user.
  /// Throws if no user is authenticated.
  CollectionReference<Map<String, dynamic>> get _goalsCol {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savings_goals');
  }

  // ── Add goal ─────────────────────────────────────────────────────

  /// Saves a new savings goal to the user's Firestore sub-collection.
  Future<void> addGoal(SavingsGoal goal) async {
    await _goalsCol.doc(goal.id).set(goal.toJson());
  }

  // ── Update goal ─────────────────────────────────────────────────

  /// Updates an existing savings goal document.
  Future<void> updateGoal(SavingsGoal goal) async {
    await _goalsCol.doc(goal.id).update(goal.toJson());
  }

  // ── Get all goals ───────────────────────────────────────────────

  /// Returns all savings goals for the current user, sorted by creation date.
  Future<List<SavingsGoal>> getGoals() async {
    final snapshot = await _goalsCol.orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map((doc) => SavingsGoal.fromJson(doc.data()))
        .toList();
  }

  // ── Delete goal ─────────────────────────────────────────────────

  /// Removes a savings goal by its [id].
  Future<void> deleteGoal(String id) async {
    await _goalsCol.doc(id).delete();
  }

  // ── Add money to goal ───────────────────────────────────────────

  /// Adds [amount] to the goal's current amount.
  /// Automatically marks as completed if target is reached.
  Future<void> addMoney(String goalId, double amount) async {
    final doc = await _goalsCol.doc(goalId).get();
    if (!doc.exists) throw Exception('Goal not found');

    final goal = SavingsGoal.fromJson(doc.data()!);
    final newAmount = goal.currentAmount + amount;
    final reachedTarget = newAmount >= goal.targetAmount;

    await _goalsCol.doc(goalId).update({
      'currentAmount': newAmount,
      'isCompleted': reachedTarget,
    });
  }

  // ── Remove money from goal ──────────────────────────────────────

  /// Removes [amount] from the goal's current amount.
  /// Cannot go below zero. If amount was completed, uncompletes it.
  Future<void> removeMoney(String goalId, double amount) async {
    final doc = await _goalsCol.doc(goalId).get();
    if (!doc.exists) throw Exception('Goal not found');

    final goal = SavingsGoal.fromJson(doc.data()!);
    final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);
    final reachedTarget = newAmount >= goal.targetAmount;

    await _goalsCol.doc(goalId).update({
      'currentAmount': newAmount,
      'isCompleted': reachedTarget,
    });
  }

  // ── Error mapping ───────────────────────────────────────────────

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
