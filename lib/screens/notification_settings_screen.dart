import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';

/// Settings screen for toggling notification types on/off.
///
/// Each toggle persists via [NotificationSettingsService] so user
/// preferences survive app restarts.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late bool _budgetWarning;
  late bool _budgetExceeded;
  late bool _recurringReminder;
  late bool _savingsGoalReminder;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    final settings = NotificationSettingsService.instance;
    _budgetWarning = settings.budgetWarningEnabled;
    _budgetExceeded = settings.budgetExceededEnabled;
    _recurringReminder = settings.recurringReminderEnabled;
    _savingsGoalReminder = settings.savingsGoalReminderEnabled;
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Permission banner ──────────────────────────────
            if (!_permissionGranted) ...[
              _buildPermissionBanner(),
              const SizedBox(height: 20),
            ],

            // ── Budget notifications ──────────────────────────
            _buildSectionHeader(
              title: 'Budget Alerts',
              subtitle: 'Get notified about your spending limits',
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildToggleTile(
              title: 'Budget Warning',
              subtitle: 'Alert when spending reaches 80%',
              value: _budgetWarning,
              onChanged: (v) {
                setState(() => _budgetWarning = v);
                NotificationSettingsService.instance.setBudgetWarning(v);
              },
            ),
            _buildToggleTile(
              title: 'Budget Exceeded',
              subtitle: 'Alert when spending exceeds the budget',
              value: _budgetExceeded,
              onChanged: (v) {
                setState(() => _budgetExceeded = v);
                NotificationSettingsService.instance.setBudgetExceeded(v);
              },
            ),

            const SizedBox(height: 28),

            // ── Recurring transaction notifications ───────────
            _buildSectionHeader(
              title: 'Recurring Transactions',
              subtitle: 'Reminders for upcoming payments',
              icon: Icons.repeat_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildToggleTile(
              title: 'Payment Reminder',
              subtitle: 'Reminder the day before a recurring transaction',
              value: _recurringReminder,
              onChanged: (v) {
                setState(() => _recurringReminder = v);
                NotificationSettingsService.instance.setRecurringReminder(v);
                if (!v) {
                  // Cancel all pending recurring reminders
                  NotificationService.instance.cancelByPayloadPrefix('recurring_');
                }
              },
            ),

            const SizedBox(height: 28),

            // ── Savings goal notifications ────────────────────
            _buildSectionHeader(
              title: 'Savings Goals',
              subtitle: 'Stay on track with your goals',
              icon: Icons.savings_outlined,
              color: AppColors.income,
            ),
            const SizedBox(height: 12),
            _buildToggleTile(
              title: 'Weekly Progress Reminder',
              subtitle: 'Weekly nudge to keep saving',
              value: _savingsGoalReminder,
              onChanged: (v) {
                setState(() => _savingsGoalReminder = v);
                NotificationSettingsService.instance
                    .setSavingsGoalReminder(v);
                if (!v) {
                  // Cancel all pending savings goal reminders
                  NotificationService.instance.cancelByPayloadPrefix('savings_');
                }
              },
            ),
            _buildToggleTile(
              title: 'Deadline Reminder',
              subtitle: 'Alert 3 days before a goal\'s target date',
              value: _savingsGoalReminder,
              onChanged: null, // Tied to the same setting
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are disabled',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable notifications to receive alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: Text(
              'Enable',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.inputFill,
          ),
        ],
      ),
    );
  }
}
