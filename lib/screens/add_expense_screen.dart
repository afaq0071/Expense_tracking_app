import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ── ADDED: for FilteringTextInputFormatter
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';

/// Screen for adding a new expense or income entry.
///
/// Contains a toggle to switch between expense/income mode,
/// text fields for title and amount, a category picker, and
/// a save button that persists the entry via [FirestoreService].
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ── State ──────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  /// True = expense mode, false = income mode.
  bool _isExpense = true;

  /// Currently selected category.
  String _selectedCategory = Expense.expenseCategories.first;

  /// True while the entry is being saved to Firestore.
  bool _isSaving = false;

  /// Shows the custom category text field when "Other" is selected.
  bool _showCustomCategory = false;

  /// Controller for the custom category text field.
  final _customCategoryController = TextEditingController();

  /// Selected transaction date (defaults to today).
  DateTime _selectedDate = DateTime.now();

  // ── Lifecycle ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  // ── Category list based on mode ────────────────────────────────────

  List<String> get _categories =>
      _isExpense ? Expense.expenseCategories : Expense.incomeCategories;

  // ── Date helpers ───────────────────────────────────────────────────

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats the selected date for display in the picker field.
  String _formatSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    return '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  /// Opens the Material date picker and updates [_selectedDate].
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Save handler ───────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine the final category string.
    final String finalCategory;
    if (_selectedCategory == 'Other') {
      finalCategory = _customCategoryController.text.trim();
      if (finalCategory.isEmpty) {
        // Safety fallback (form validation should catch this).
        return;
      }
    } else {
      finalCategory = _selectedCategory;
    }

    setState(() => _isSaving = true);

    bool success = false;

    try {
      // Generate a unique ID using the uuid package.
      final id = const Uuid().v4();

      // Parse the amount from the text field.
      final amount = double.parse(_amountController.text.trim());

      // Create the expense object.
      final expense = Expense(
        id: id,
        title: _titleController.text.trim(),
        amount: amount,
        category: finalCategory,
        date: _selectedDate,
        isExpense: _isExpense,
      );

      // Save to Firestore.
      await FirestoreService.instance.addExpense(expense);
      success = true;
    } catch (e) {
      if (!mounted) return;

      // Surface the real cause (auth, rules, network…) — not a vague message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirestoreService.describeError(e),
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
      // Re-enable the save button so the user can retry after a failure.
      if (mounted && !success) {
        setState(() => _isSaving = false);
      }
    }

    // Go back to the previous screen (home), which reloads on return.
    if (success && mounted) Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add ${_isExpense ? 'Expense' : 'Income'}',
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
              // ── Expense / Income toggle ──────────────────────────
              _buildToggle(),

              const SizedBox(height: 32),

              // ── Title field ──────────────────────────────────────
              _buildTextField(
                controller: _titleController,
                hint: 'Title (e.g., Groceries)',
                icon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Amount field ─────────────────────────────────────
              _buildTextField(
                controller: _amountController,
                hint: 'Amount',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // ── ADDED: only allow digits and one decimal point ──
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── Date picker ───────────────────────────────────
              Text(
                'Date',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
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
                        _formatSelectedDate(),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Category label ───────────────────────────────────
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // ── Category chips ──────────────────────────────────
              _buildCategoryChips(),

              // ── Custom category field (shown when "Other" is selected) ──
              if (_showCustomCategory) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _customCategoryController,
                  hint: 'Enter custom category',
                  icon: Icons.label_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 40),

              // ── Save button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isExpense ? AppColors.expense : AppColors.income,
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
                    'Save ${_isExpense ? 'Expense' : 'Income'}',
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

  // ── Widget builders ──────────────────────────────────────────────

  /// Toggle between Expense and Income mode.
  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Expense tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpense = true;
                  _selectedCategory = Expense.expenseCategories.first;
                  _showCustomCategory = false;
                  _customCategoryController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isExpense ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: _isExpense ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expense',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isExpense ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Income tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpense = false;
                  _selectedCategory = Expense.incomeCategories.first;
                  _showCustomCategory = false;
                  _customCategoryController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isExpense ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color: !_isExpense ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Income',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !_isExpense ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Scrollable row of category chips.
  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final isSelected = cat == _selectedCategory;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = cat;
              if (cat == 'Other') {
                _showCustomCategory = true;
              } else {
                _showCustomCategory = false;
                _customCategoryController.clear();
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (_isExpense ? AppColors.expense : AppColors.income)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.inputBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Expense.categoryIcon(cat),
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Styled text field matching the login screen design.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    // ── ADDED: optional input formatters parameter ──
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // ── CHANGED: pass through formatters
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
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
      ),
    );
  }
}
