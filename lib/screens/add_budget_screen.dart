import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../services/budget_service.dart';

/// Screen for creating or editing a monthly budget.
///
/// Allows setting a total monthly budget and optional category-specific budgets.
class AddBudgetScreen extends StatefulWidget {
  final Budget? existingBudget; // For editing

  const AddBudgetScreen({super.key, this.existingBudget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalBudgetController = TextEditingController();
  final _nameController = TextEditingController();

  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = false;
  bool _hasExistingBudget = false;

  // Category budgets
  final Map<String, TextEditingController> _categoryControllers = {};
  bool _showCategoryBudgets = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final now = DateTime.now();
    _selectedMonth = widget.existingBudget?.month ?? now.month;
    _selectedYear = widget.existingBudget?.year ?? now.year;

    if (widget.existingBudget != null) {
      _hasExistingBudget = true;
      _nameController.text = widget.existingBudget!.name;
      _totalBudgetController.text =
          widget.existingBudget!.totalAmount.toStringAsFixed(2);

      if (widget.existingBudget!.categoryBudgets.isNotEmpty) {
        _showCategoryBudgets = true;
        for (final entry in widget.existingBudget!.categoryBudgets.entries) {
          _categoryControllers[entry.key] =
              TextEditingController(text: entry.value.toStringAsFixed(2));
        }
      }
    } else {
      _nameController.text = 'Monthly Budget';
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    _nameController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final totalAmount = double.parse(_totalBudgetController.text);

      // Build category budgets
      final categoryBudgets = <String, double>{};
      for (final entry in _categoryControllers.entries) {
        final value = double.tryParse(entry.value.text) ?? 0;
        if (value > 0) {
          categoryBudgets[entry.key] = value;
        }
      }

      final budget = Budget(
        id: widget.existingBudget?.id ?? const Uuid().v4(),
        name: _nameController.text,
        totalAmount: totalAmount,
        month: _selectedMonth,
        year: _selectedYear,
        categoryBudgets: categoryBudgets,
        createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      );

      if (_hasExistingBudget) {
        await BudgetService.instance.updateBudget(budget);
      } else {
        await BudgetService.instance.addBudget(budget);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasExistingBudget ? 'Budget updated' : 'Budget created',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              BudgetService.describeError(e),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _hasExistingBudget ? 'Edit Budget' : 'Create Budget',
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
              _buildMonthSelector(),
              const SizedBox(height: 24),
              _buildBudgetNameField(),
              const SizedBox(height: 24),
              _buildTotalBudgetField(),
              const SizedBox(height: 24),
              _buildCategoryBudgetsSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Period',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildYearDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _selectedMonth,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        items: List.generate(12, (index) {
          return DropdownMenuItem(
            value: index + 1,
            child: Text(
              months[index],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedMonth = value);
          }
        },
      ),
    );
  }

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        items: years.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(
              year.toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedYear = value);
          }
        },
      ),
    );
  }

  Widget _buildBudgetNameField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Name',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Monthly Budget',
              hintStyle: GoogleFonts.poppins(
                color: AppColors.textSecondary,
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
                return 'Please enter a budget name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudgetField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Monthly Budget',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _totalBudgetController,
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
                return 'Please enter a budget amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budgets',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Optional',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set spending limits for specific categories',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable category budgets',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            value: _showCategoryBudgets,
            onChanged: (value) {
              setState(() {
                _showCategoryBudgets = value;
                if (!value) {
                  // Clear category controllers when disabled
                  for (final controller in _categoryControllers.values) {
                    controller.dispose();
                  }
                  _categoryControllers.clear();
                }
              });
            },
            activeThumbColor: AppColors.primary,
          ),
          if (_showCategoryBudgets) ...[
            const SizedBox(height: 16),
            ...Expense.expenseCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryBudgetField(category),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetField(String category) {
    // Initialize controller if not exists
    if (!_categoryControllers.containsKey(category)) {
      _categoryControllers[category] = TextEditingController();
    }

    return Row(
      children: [
        Icon(
          Expense.categoryIcon(category),
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: _categoryControllers[category],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              hintText: '0',
              hintStyle: GoogleFonts.poppins(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _hasExistingBudget ? 'Update Budget' : 'Create Budget',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
