import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/currency_model.dart';
import '../services/auth_service.dart';

/// Persists the user's currency preference in Firestore.
///
/// Stored under: users/{uid}/settings/currency
/// Defaults to USD if no setting exists.
class CurrencyService {
  // ── Singleton ──────────────────────────────────────────────────────

  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  // ── Cached preference ─────────────────────────────────────────────

  AppCurrency? _cached;

  // ── Firestore reference ────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('currency');
  }

  // ── Get current currency ──────────────────────────────────────────

  /// Returns the user's selected currency, falling back to USD.
  /// Uses a cached value after the first load for synchronous access.
  AppCurrency get currentCurrency => _cached ?? AppCurrency.defaultCurrency;

  /// Loads the user's currency preference from Firestore.
  /// Must be called at app startup (e.g., in SplashScreen or main).
  Future<AppCurrency> loadCurrency() async {
    try {
      final doc = _doc;
      if (doc == null) return AppCurrency.defaultCurrency;

      final snapshot = await doc.get();
      if (snapshot.exists && snapshot.data() != null) {
        final code = snapshot.data()!['code'] as String?;
        _cached = AppCurrency.fromCode(code);
      } else {
        _cached = AppCurrency.defaultCurrency;
      }
    } catch (_) {
      _cached = AppCurrency.defaultCurrency;
    }
    return _cached!;
  }

  // ── Set currency ──────────────────────────────────────────────────

  /// Saves the user's currency preference to Firestore.
  Future<void> setCurrency(AppCurrency currency) async {
    try {
      final doc = _doc;
      if (doc == null) return;

      await doc.set({
        'code': currency.code,
        'name': currency.name,
        'symbol': currency.symbol,
        'decimalDigits': currency.decimalDigits,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _cached = currency;
    } catch (_) {
      // Non-fatal: cached value is still updated for the current session.
      _cached = currency;
    }
  }

  // ── Clear cache ───────────────────────────────────────────────────

  void clearCache() {
    _cached = null;
  }
}
