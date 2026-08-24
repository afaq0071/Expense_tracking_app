import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';
import '../models/recurring_transaction_model.dart';
import '../services/auth_service.dart';

/// Handles all Firestore persistence for [RecurringTransaction] templates
/// and generates actual [Expense] entries from them.
///
/// Templates are stored under: users/{uid}/recurring_transactions/{templateId}
/// Generated transactions are stored under: users/{uid}/expenses/{expenseId}
class RecurringTransactionService {
  // ── Singleton ──────────────────────────────────────────────────────

  RecurringTransactionService._();
  static final RecurringTransactionService instance =
      RecurringTransactionService._();

  // ── Firestore reference helpers ────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _templatesCol {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recurring_transactions');
  }

  CollectionReference<Map<String, dynamic>> get _expensesCol {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses');
  }

  // ── Template CRUD ──────────────────────────────────────────────────

  Future<void> addTemplate(RecurringTransaction template) async {
    await _templatesCol.doc(template.id).set(template.toJson());
  }

  Future<void> updateTemplate(RecurringTransaction template) async {
    await _templatesCol.doc(template.id).update(template.toJson());
  }

  Future<void> deleteTemplate(String id) async {
    await _templatesCol.doc(id).delete();
  }

  Future<List<RecurringTransaction>> getTemplates() async {
    final snapshot =
        await _templatesCol.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => RecurringTransaction.fromJson(doc.data()))
        .toList();
  }

  Future<RecurringTransaction?> getTemplate(String id) async {
    final doc = await _templatesCol.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return RecurringTransaction.fromJson(doc.data()!);
  }

  // ── Generate transactions from templates ───────────────────────────

  /// Scans all active templates and generates any transactions that are
  /// due (from lastGeneratedDate up to today). Uses a batch write for
  /// efficiency and to prevent duplicates via the date-keyed document ID.
  ///
  /// Returns the number of transactions generated.
  Future<int> generateDueTransactions() async {
    final templates = await getTemplates();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int generated = 0;

    for (final template in templates) {
      if (!template.isActive) continue;

      final lastGenerated = template.lastGeneratedDate;
      DateTime current;

      if (lastGenerated == null) {
        // First time — start from the template's start date.
        current = DateTime(
          template.startDate.year,
          template.startDate.month,
          template.startDate.day,
        );
      } else {
        // Continue from the day after the last generation.
        current = template.nextOccurrence(
          DateTime(lastGenerated.year, lastGenerated.month, lastGenerated.day),
        );
      }

      // Generate all occurrences up to today.
      while (!current.isAfter(todayDate)) {
        final docId = '${template.id}_${current.millisecondsSinceEpoch}';

        // Check if this exact transaction already exists (duplicate prevention).
        final existing = await _expensesCol.doc(docId).get();
        if (!existing.exists) {
          final expense = Expense(
            id: docId,
            title: template.title,
            amount: template.amount,
            category: template.category,
            date: current,
            isExpense: template.isExpense,
            recurringTemplateId: template.id,
          );

          await _expensesCol.doc(docId).set(expense.toJson());
          generated++;
        }

        current = template.nextOccurrence(current);
      }

      // Update lastGeneratedDate to today.
      await _templatesCol.doc(template.id).update({
        'lastGeneratedDate': todayDate.toIso8601String(),
      });
    }

    return generated;
  }

  /// Check if a transaction has already been generated for a specific
  /// template on a specific date.
  Future<bool> isAlreadyGenerated(String templateId, DateTime date) async {
    final docId = '${templateId}_${date.millisecondsSinceEpoch}';
    final doc = await _expensesCol.doc(docId).get();
    return doc.exists;
  }

  // ── Error mapping ──────────────────────────────────────────────────

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
