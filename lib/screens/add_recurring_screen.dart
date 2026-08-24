import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';
import '../models/recurring_transaction_model.dart';
import '../services/recurring_transaction_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';

/// Screen for creating or editing a recurring transaction template.
class AddRecurringScreen extends StatefulWidget {
  final RecurringTransaction? existingTemplate;

  const AddRecurringScreen({super.key, this.existingTemplate});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();

  bool _isExpense = true;
  String _selectedCategory = Expense.expenseCategories.first;
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _showCustomCategory = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existingTemplate != null;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTemplate!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toStringAsFixed(2);
      _isExpense = t.isExpense;
      _selectedCategory = t.category;
      _frequency = t.frequency;
      _startDate = t.startDate;
      if (!Expense.expenseCategories.contains(t.category) &&
          !Expense.incomeCategories.contains(t.category)) {
        _showCustomCategory = true;
        _customCategoryController.text = t.category;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _isExpense ? Expense.expenseCategories : Expense.incomeCategories;

  /// Schedules a reminder notification for the day before the next
  /// occurrence of the recurring transaction template.
  void _scheduleRecurringReminder(RecurringTransaction template) {
    if (!NotificationSettingsService.instance.recurringReminderEnabled) return;

    final nextDate = template.nextOccurrence(DateTime.now());
    final reminderDate = nextDate.subtract(const Duration(days: 1));

    // Don't schedule if the reminder date is in the past
    if (reminderDate.isBefore(DateTime.now())) return;

    final notifId = NotificationService.recurringReminderId(template.id);

    NotificationService.instance.scheduleNotification(
      id: notifId,
      title: 'Recurring Transaction Reminder',
      body: '"${template.title}" (\$${template.amount.toStringAsFixed(2)}) '
          'is due tomorrow.',
      scheduledTime: reminderDate,
      payload: 'recurring_${template.id}',
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text);
      final category =
          _showCustomCategory ? _customCategoryController.text : _selectedCategory;

      final template = RecurringTransaction(
        id: widget.existingTemplate?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: amount,
        category: category,
        isExpense: _isExpense,
        startDate: _startDate,
        frequency: _frequency,
        isActive: widget.existingTemplate?.isActive ?? true,
        createdAt: widget.existingTemplate?.createdAt ?? DateTime.now(),
        lastGeneratedDate: widget.existingTemplate?.lastGeneratedDate,
      );

      if (_isEditing) {
        await RecurringTransactionService.instance.updateTemplate(template);
      } else {
        await RecurringTransactionService.instance.addTemplate(template);
      }

      // Schedule reminder notification for the day before the next occurrence
      if (template.isActive) {
        _scheduleRecurringReminder(template);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Template updated' : 'Recurring transaction created',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RecurringTransactionService.describeError(e),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Recurring' : 'New Recurring',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggle(),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              _buildCategoryPicker(),
              if (_showCustomCategory) ...[
                const SizedBox(height: 16),
                _buildCustomCategoryField(),
              ],
              const SizedBox(height: 20),
              _buildFrequencyPicker(),
              const SizedBox(height: 20),
              _buildStartDateField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isExpense = true;
                _selectedCategory = Expense.expenseCategories.first;
                _showCustomCategory = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpense ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Expense',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isExpense ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isExpense = false;
                _selectedCategory = Expense.incomeCategories.first;
                _showCustomCategory = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpense ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Income',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_isExpense ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Title',
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        hintText: 'e.g., Netflix Subscription',
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        labelText: 'Amount',
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        hintText: '0.00',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 24,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        items: [
          ..._categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }),
          const DropdownMenuItem(
            value: 'Other',
            child: Text(
              'Other (custom)',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
        onChanged: (value) {
          if (value == 'Other') {
            setState(() {
              _showCustomCategory = true;
              _customCategoryController.clear();
            });
          } else if (value != null) {
            setState(() {
              _selectedCategory = value;
              _showCustomCategory = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildCustomCategoryField() {
    return TextFormField(
      controller: _customCategoryController,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Custom Category',
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        hintText: 'Enter category name',
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (_showCustomCategory && (value == null || value.trim().isEmpty)) {
          return 'Please enter a category name';
        }
        return null;
      },
    );
  }

  Widget _buildFrequencyPicker() {
    final frequencies = [
      ('daily', 'Daily'),
      ('weekly', 'Weekly'),
      ('monthly', 'Monthly'),
      ('yearly', 'Yearly'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: frequencies.map((f) {
            final isSelected = _frequency == f.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _frequency = f.$1),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    f.$2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartDateField() {
    return GestureDetector(
      onTap: _pickStartDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              'Starts: ${_formatDate(_startDate)}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditing ? 'Update Template' : 'Create Recurring',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
