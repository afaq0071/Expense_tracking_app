import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';

/// Screen for creating or editing a savings goal.
///
/// If [goal] is provided, the form is pre-populated for editing.
/// Otherwise, a new goal is created.
class AddEditGoalScreen extends StatefulWidget {
  final SavingsGoal? goal;

  const AddEditGoalScreen({super.key, this.goal});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _selectedIcon = 'savings';
  bool _isSaving = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.goal!.name;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _targetDate = widget.goal!.targetDate;
      _selectedIcon = widget.goal!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success = false;

    try {
      final targetAmount = double.parse(_targetAmountController.text.trim());
      final currentAmount = double.parse(
        _currentAmountController.text.isEmpty
            ? '0'
            : _currentAmountController.text.trim(),
      );

      final goal = SavingsGoal(
        id: _isEditing ? widget.goal!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        iconName: _selectedIcon,
        isCompleted: currentAmount >= targetAmount,
        createdAt: _isEditing ? widget.goal!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        await SavingsGoalService.instance.updateGoal(goal);
        // Cancel old notifications and reschedule with updated data
        _cancelGoalNotifications(goal);
        _scheduleGoalReminders(goal);
      } else {
        await SavingsGoalService.instance.addGoal(goal);
        // Schedule reminders for newly created goals
        _scheduleGoalReminders(goal);
      }
      success = true;
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
      if (mounted && !success) {
        setState(() => _isSaving = false);
      }
    }

    if (success && mounted) Navigator.pop(context);
  }

  /// Cancels all pending notifications for a savings goal.
  void _cancelGoalNotifications(SavingsGoal goal) {
    final notifId = NotificationService.savingsGoalReminderId(goal.id);
    NotificationService.instance.cancel(notifId);
    NotificationService.instance.cancel(notifId + 10000);
  }

  /// Schedules reminder notifications for a newly created savings goal.
  void _scheduleGoalReminders(SavingsGoal goal) {
    if (goal.isCompleted) return;
    if (!NotificationSettingsService.instance.savingsGoalReminderEnabled) return;

    // Weekly reminder (every Monday at 9 AM)
    final weeklyNotifId = NotificationService.savingsGoalReminderId(goal.id);
    NotificationService.instance.scheduleWeeklyNotification(
      id: weeklyNotifId,
      title: 'Savings Goal Reminder',
      body: 'Keep saving for "${goal.name}" — '
          '${goal.formattedRemaining} to go!',
      dayOfWeek: 1,
      timeOfDay: '09:00',
      payload: 'savings_${goal.id}',
    );

    // Target date approaching reminder (3 days before)
    final daysUntilTarget = goal.targetDate
        .difference(DateTime.now())
        .inDays;
    if (daysUntilTarget > 3) {
      final reminderDate =
          goal.targetDate.subtract(const Duration(days: 3));
      final targetNotifId = NotificationService.savingsGoalReminderId(
        goal.id,
      ) + 10000;
      NotificationService.instance.scheduleNotification(
        id: targetNotifId,
        title: 'Goal Deadline Approaching',
        body: '"${goal.name}" target date is in 3 days — '
            'you have ${goal.formattedRemaining} left!',
        scheduledTime: reminderDate,
        payload: 'savings_${goal.id}',
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Goal' : 'Add Goal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name field ────────────────────────────────────
              Text(
                'Goal Name',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDecoration(
                  hint: 'e.g., Emergency Fund, Vacation',
                  icon: Icons.flag_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // ── Target amount ────────────────────────────────
              Text(
                'Target Amount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDecoration(
                  hint: '0.00',
                  icon: Icons.attach_money_rounded,
                ),
              ),

              const SizedBox(height: 20),

              // ── Current amount (only on create) ──────────────
              if (!_isEditing) ...[
                Text(
                  'Already Saved (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (double.tryParse(value.trim()) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value.trim()) < 0) {
                        return 'Amount cannot be negative';
                      }
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration(
                    hint: '0.00',
                    icon: Icons.savings_outlined,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Target date ──────────────────────────────────
              Text(
                'Target Date',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_targetDate),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Icon picker ──────────────────────────────────
              Text(
                'Icon',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildIconPicker(),

              const SizedBox(height: 40),

              // ── Save button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Goal' : 'Create Goal',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary,
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.expense, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.expense, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 12),
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: SavingsGoal.availableIcons.map((iconName) {
        final isSelected = iconName == _selectedIcon;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = iconName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.inputBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              SavingsGoal.iconFromName(iconName),
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }
}
