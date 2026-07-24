import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';

/// A reusable card widget that displays a single expense or income entry.
///
/// Used inside lists (e.g., home screen transaction list).
/// Shows the category icon, title, category label, formatted amount,
/// and optionally allows tap-to-delete via [onLongPress].
class ExpenseCard extends StatelessWidget {
  /// The expense data to display.
  final Expense expense;

  /// Called when the user long-presses the card (for delete action).
  final VoidCallback? onLongPress;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Pick colors based on whether this is an expense or income.
    final color = expense.isExpense ? AppColors.expense : AppColors.income;
    final bgColor = color.withValues(alpha: 0.1);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
            // ── Category icon ──────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Expense.categoryIcon(expense.category),
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // ── Title + category ──────────────────────────────────
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
                ],
              ),
            ),

            // ── Amount ────────────────────────────────────────────
            Text(
              expense.formattedAmount,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
