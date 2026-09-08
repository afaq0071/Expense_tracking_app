import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onLongPress;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final category = expense.category;
    final bgColor = AppColors.categoryBackground(category);
    final fgColor = AppColors.categoryForeground(category);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            // ── Circular category icon ────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Expense.categoryIcon(category),
                color: fgColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // ── Title + category + date ──────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.category,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // ── Amount ────────────────────────────────────────────
            Text(
              expense.formattedAmount,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: expense.isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
