import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet_model.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';

/// Handles all Firestore persistence for [Wallet] entries.
///
/// Each user's wallets are stored under: users/{uid}/wallets/{walletId}
/// This keeps every user's data isolated and secure.
class WalletService {
  // ── Singleton ──────────────────────────────────────────────────────

  WalletService._();
  static final WalletService instance = WalletService._();

  // ── Firestore reference helpers ────────────────────────────────────

  /// Returns the wallets collection for the currently logged-in user.
  /// Throws if no user is authenticated.
  CollectionReference<Map<String, dynamic>> get _walletsCol {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallets');
  }

  // ── Add wallet ────────────────────────────────────────────────────

  /// Saves a new wallet to the user's Firestore sub-collection.
  Future<void> addWallet(Wallet wallet) async {
    await _walletsCol.doc(wallet.id).set(wallet.toJson());
  }

  // ── Update wallet ─────────────────────────────────────────────────

  /// Updates an existing wallet document.
  Future<void> updateWallet(Wallet wallet) async {
    await _walletsCol.doc(wallet.id).update(wallet.toJson());
  }

  // ── Get all wallets ───────────────────────────────────────────────

  /// Returns all wallets for the current user, sorted by name.
  Future<List<Wallet>> getWallets() async {
    final snapshot = await _walletsCol.orderBy('name').get();

    return snapshot.docs
        .map((doc) => Wallet.fromJson(doc.data()))
        .toList();
  }

  // ── Delete wallet ─────────────────────────────────────────────────

  /// Removes a wallet by its [id].
  Future<void> deleteWallet(String id) async {
    await _walletsCol.doc(id).delete();
  }

  // ── Calculate wallet balance from expenses ────────────────────────

  /// Computes the net balance for a given [walletId] from a list of expenses.
  /// Balance = total income - total expenses for that wallet.
  /// Transactions without a walletId are ignored.
  double calculateBalance(List<Expense> expenses, String walletId) {
    double balance = 0;
    for (final e in expenses) {
      if (e.walletId == walletId) {
        balance += e.isExpense ? -e.amount : e.amount;
      }
    }
    return balance;
  }

  // ── First-time setup helper ───────────────────────────────────────

  /// Creates the four preset wallets (Cash, Bank, Easypaisa, JazzCash)
  /// only if the user has zero wallets. Returns the created list.
  Future<List<Wallet>> ensureDefaultWallets() async {
    final existing = await getWallets();
    if (existing.isNotEmpty) return existing;

    final created = <Wallet>[];
    for (final preset in Wallet.presets) {
      final wallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            preset['name']!,
        name: preset['name']!,
        iconName: preset['icon']!,
      );
      await addWallet(wallet);
      created.add(wallet);
    }
    return created;
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
