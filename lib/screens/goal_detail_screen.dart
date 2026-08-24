import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';

/// Screen showing detailed progress for a single savings goal.
///
/// Allows adding and removing money, displays progress percentage,
/// remaining amount, and target date. Marks as completed when target
/// is reached.
class GoalDetailScreen extends StatefulWidget {
  final SavingsGoal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late SavingsGoal _goal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _scheduleGoalReminders();
  }

  /// Schedules reminder notifications for the savings goal:
  /// - A weekly recurring reminder every Monday at 9:00 AM
  /// - A one-time reminder 3 days before the target date
  void _scheduleGoalReminders() {
    if (_goal.isCompleted) return;
    if (!NotificationSettingsService.instance.savingsGoalReminderEnabled) return;

    // Weekly reminder (every Monday at 9 AM)
    final weeklyNotifId = NotificationService.savingsGoalReminderId(_goal.id);
    NotificationService.instance.scheduleWeeklyNotification(
      id: weeklyNotifId,
      title: 'Savings Goal Reminder',
      body: 'Keep saving for "${_goal.name}" — '
          '${_goal.formattedRemaining} to go!',
      dayOfWeek: 1, // Monday
      timeOfDay: '09:00',
      payload: 'savings_${_goal.id}',
    );

    // Target date approaching reminder (3 days before)
    final daysUntilTarget = _goal.targetDate
        .difference(DateTime.now())
        .inDays;
    if (daysUntilTarget > 3) {
      final reminderDate =
          _goal.targetDate.subtract(const Duration(days: 3));
      final targetNotifId = NotificationService.savingsGoalReminderId(
        _goal.id,
      ) + 10000;
      NotificationService.instance.scheduleNotification(
        id: targetNotifId,
        title: 'Goal Deadline Approaching',
        body: '"${_goal.name}" target date is in 3 days — '
            'you have ${_goal.formattedRemaining} left!',
        scheduledTime: reminderDate,
        payload: 'savings_${_goal.id}',
      );
    }
  }

  Future<void> _refreshGoal() async {
    try {
      final goals = await SavingsGoalService.instance.getGoals();
      final updated = goals.where((g) => g.id == _goal.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _goal = updated);
      }
    } catch (_) {
      // Non-fatal: keep current state
    }
  }

  Future<void> _addMoney() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Money',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          autofocus: true,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Amount to add',
            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.add_rounded, color: AppColors.income),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                Navigator.pop(ctx, amount);
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.poppins(
                color: AppColors.income,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != null) {
      setState(() => _isLoading = true);
      try {
        await SavingsGoalService.instance.addMoney(_goal.id, confirmed);
        await _refreshGoal();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SavingsGoalService.describeError(e),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeMoney() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Money',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          autofocus: true,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Amount to remove',
            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
            prefixIcon:
                const Icon(Icons.remove_rounded, color: AppColors.expense),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                Navigator.pop(ctx, amount);
              }
            },
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != null) {
      setState(() => _isLoading = true);
      try {
        await SavingsGoalService.instance.removeMoney(_goal.id, confirmed);
        await _refreshGoal();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SavingsGoalService.describeError(e),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (_goal.progress * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _goal.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Progress card ─────────────────────────────
                  _buildProgressCard(progressPercent),

                  const SizedBox(height: 24),

                  // ── Details card ─────────────────────────────
                  _buildDetailsCard(),

                  const SizedBox(height: 24),

                  // ── Action buttons ───────────────────────────
                  if (!_goal.isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Add Money',
                            icon: Icons.add_rounded,
                            color: AppColors.income,
                            onTap: _addMoney,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Remove Money',
                            icon: Icons.remove_rounded,
                            color: AppColors.expense,
                            onTap: _goal.currentAmount > 0 ? _removeMoney : null,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildCompletedBanner(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard(String progressPercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _goal.isCompleted ? AppColors.accentGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_goal.isCompleted ? AppColors.accent : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _goal.isCompleted
                ? Icons.check_circle_outline
                : SavingsGoal.iconFromName(_goal.iconName),
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _goal.formattedCurrentAmount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _goal.isCompleted ? 'Goal reached!' : 'of ${_goal.formattedTargetAmount}',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _goal.progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$progressPercent%',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.flag_outlined,
            label: 'Target Amount',
            value: _goal.formattedTargetAmount,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.savings_outlined,
            label: 'Current Saved',
            value: _goal.formattedCurrentAmount,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.trending_down_outlined,
            label: 'Remaining',
            value: _goal.formattedRemaining,
            valueColor: _goal.remaining > 0 ? AppColors.textPrimary : AppColors.income,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Target Date',
            value: _goal.formattedTargetDate,
            valueColor: _goal.daysRemaining < 0 ? AppColors.expense : AppColors.textPrimary,
          ),
          if (!_goal.isCompleted) ...[
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.timer_outlined,
              label: 'Time Left',
              value: _goal.daysRemainingText,
              valueColor: _goal.daysRemaining < 0 ? AppColors.expense : AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppColors.inputFill : color,
          foregroundColor: isDisabled ? AppColors.textSecondary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.income.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.income,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Goal Completed!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.income,
            ),
          ),
        ],
      ),
    );
  }
}
