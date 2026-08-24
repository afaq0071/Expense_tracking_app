import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-type notification toggle settings via [SharedPreferences].
///
/// Each toggle defaults to `true` (enabled) so the user gets notifications
/// out of the box and can selectively disable types they don't want.
class NotificationSettingsService {
  // ── Singleton ──────────────────────────────────────────────────────

  NotificationSettingsService._();
  static final NotificationSettingsService instance =
      NotificationSettingsService._();

  // ── SharedPreferences keys ─────────────────────────────────────────

  static const String _keyBudgetWarning = 'notif_budget_warning';
  static const String _keyBudgetExceeded = 'notif_budget_exceeded';
  static const String _keyRecurringReminder = 'notif_recurring_reminder';
  static const String _keySavingsGoalReminder = 'notif_savings_goal_reminder';

  SharedPreferences? _prefs;

  // ── Init ───────────────────────────────────────────────────────────

  /// Loads the cached [SharedPreferences] instance.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Getters ────────────────────────────────────────────────────────

  bool get budgetWarningEnabled => _prefs?.getBool(_keyBudgetWarning) ?? true;
  bool get budgetExceededEnabled =>
      _prefs?.getBool(_keyBudgetExceeded) ?? true;
  bool get recurringReminderEnabled =>
      _prefs?.getBool(_keyRecurringReminder) ?? true;
  bool get savingsGoalReminderEnabled =>
      _prefs?.getBool(_keySavingsGoalReminder) ?? true;

  // ── Setters ────────────────────────────────────────────────────────

  Future<void> setBudgetWarning(bool enabled) async {
    await _prefs?.setBool(_keyBudgetWarning, enabled);
  }

  Future<void> setBudgetExceeded(bool enabled) async {
    await _prefs?.setBool(_keyBudgetExceeded, enabled);
  }

  Future<void> setRecurringReminder(bool enabled) async {
    await _prefs?.setBool(_keyRecurringReminder, enabled);
  }

  Future<void> setSavingsGoalReminder(bool enabled) async {
    await _prefs?.setBool(_keySavingsGoalReminder, enabled);
  }

  // ── Bulk helpers ───────────────────────────────────────────────────

  /// Returns all settings as a map (useful for debugging / UI).
  Map<String, bool> getAll() => {
        'budgetWarning': budgetWarningEnabled,
        'budgetExceeded': budgetExceededEnabled,
        'recurringReminder': recurringReminderEnabled,
        'savingsGoalReminder': savingsGoalReminderEnabled,
      };

  /// Resets all toggles to `true`.
  Future<void> resetAll() async {
    await setBudgetWarning(true);
    await setBudgetExceeded(true);
    await setRecurringReminder(true);
    await setSavingsGoalReminder(true);
  }
}
