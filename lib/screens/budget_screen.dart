import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../services/budget_service.dart';
import 'add_budget_screen.dart';

/// Screen displaying all budgets with spending progress.
///
/// Shows budget amount, spent amount, remaining amount, and percentage used.
/// Warns when spending reaches 80% and indicates when budget is exceeded.
class BudgetScreen extends StatefulWidget {
  final List<Expense> expenses;

  const BudgetScreen({super.key, required this.expenses});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Budget> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);

    try {
      final budgets = await BudgetService.instance.getBudgets();
      if (mounted) {
        setState(() {
          _budgets = budgets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${budget.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BudgetService.instance.deleteBudget(budget.id);
        _loadBudgets();
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Future<void> _editBudget(Budget budget) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(existingBudget: budget),
      ),
    );
    if (result == true) _loadBudgets();
  }

  Future<void> _createBudget() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBudgetScreen(),
      ),
    );
    if (result == true) _loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Budgets',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _budgets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBudgets,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildBudgetCard(_budgets[index]),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBudget,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'No budgets yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget to track your spending',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createBudget,
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'Create Budget',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = BudgetService.instance.calculateTotalSpent(
      widget.expenses,
      budget.month,
      budget.year,
    );
    final remaining = budget.totalAmount - spent;
    final percentage = BudgetService.instance.calculatePercentage(
      spent,
      budget.totalAmount,
    );
    final warningLevel = BudgetService.instance.getWarningLevel(percentage);

    return GestureDetector(
      onTap: () => _editBudget(budget),
      onLongPress: () => _deleteBudget(budget),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget.monthLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildWarningBadge(warningLevel),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildBudgetStat(
                  label: 'Budget',
                  amount: budget.totalAmount,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildBudgetStat(
                  label: 'Spent',
                  amount: spent,
                  color: AppColors.expense,
                ),
                const SizedBox(width: 16),
                _buildBudgetStat(
                  label: 'Remaining',
                  amount: remaining,
                  color: remaining >= 0 ? AppColors.income : AppColors.expense,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(percentage, warningLevel),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}% used',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _getWarningColor(warningLevel),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (budget.categoryBudgets.isNotEmpty)
                  Text(
                    '${budget.categoryBudgets.length} categories',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            if (budget.categoryBudgets.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCategoryBreakdown(budget, spent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStat({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double percentage, int warningLevel) {
    final clampedPercentage = percentage.clamp(0.0, 1.0);
    final color = _getWarningColor(warningLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clampedPercentage,
            backgroundColor: AppColors.inputFill,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBadge(int warningLevel) {
    if (warningLevel == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warningLevel == 2
            ? AppColors.expense.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warningLevel == 2 ? Icons.warning_rounded : Icons.info_outline,
            size: 14,
            color: warningLevel == 2 ? AppColors.expense : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            warningLevel == 2 ? 'Exceeded' : 'Warning',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: warningLevel == 2 ? AppColors.expense : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Budget budget, double totalSpent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Budgets',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...budget.categoryBudgets.entries.map((entry) {
            final categorySpent = BudgetService.instance.calculateCategorySpent(
              widget.expenses,
              entry.key,
              budget.month,
              budget.year,
            );
            final categoryPercentage = BudgetService.instance.calculatePercentage(
              categorySpent,
              entry.value,
            );
            final categoryWarningLevel = BudgetService.instance.getWarningLevel(
              categoryPercentage,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Expense.categoryIcon(entry.key),
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '\$${categorySpent.toStringAsFixed(0)} / \$${entry.value.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getWarningColor(categoryWarningLevel),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getWarningColor(int warningLevel) {
    switch (warningLevel) {
      case 2:
        return AppColors.expense;
      case 1:
        return Colors.orange;
      default:
        return AppColors.income;
    }
  }
}
