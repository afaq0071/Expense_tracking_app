import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';
import '../models/wallet_model.dart';
import '../services/export_service.dart';

/// Screen for exporting transactions as CSV or PDF monthly report.
///
/// Accepts the already-loaded [expenses] list and [wallets] from the
/// home screen so no extra Firestore reads are needed.
class ExportScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Wallet> wallets;

  const ExportScreen({
    super.key,
    required this.expenses,
    required this.wallets,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // last day of month
  }

  // ── Derived data ────────────────────────────────────────────────

  Map<String, String> get _walletMap =>
      {for (final w in widget.wallets) w.id: w.name};

  List<Expense> get _filtered =>
      ExportService.instance.filterByDateRange(
        widget.expenses,
        _startDate,
        _endDate,
      );

  double get _totalIncome =>
      _filtered.where((e) => !e.isExpense).fold(0.0, (s, e) => s + e.amount);

  double get _totalExpenses =>
      _filtered.where((e) => e.isExpense).fold(0.0, (s, e) => s + e.amount);

  double get _balance => _totalIncome - _totalExpenses;

  // ── Period label ────────────────────────────────────────────────

  String get _periodLabel {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = _startDate;
    final e = _endDate;
    if (s.year == e.year && s.month == e.month) {
      return '${months[s.month - 1]} ${s.year}';
    }
    return '${s.day} ${months[s.month - 1]} ${s.year} – '
        '${e.day} ${months[e.month - 1]} ${e.year}';
  }

  // ── Actions ─────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  Future<void> _exportCsv() async {
    if (_filtered.isEmpty) {
      _showEmptyWarning();
      return;
    }
    setState(() => _isExporting = true);
    try {
      final csv = ExportService.instance.buildCsv(_filtered, _walletMap);
      final fileName =
          'expenses_${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}.csv';
      await ExportService.instance.shareCsv(csv, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_filtered.isEmpty) {
      _showEmptyWarning();
      return;
    }
    setState(() => _isExporting = true);
    try {
      await ExportService.instance.generateAndSharePdf(
        title: 'Expense Report – $_periodLabel',
        expenses: _filtered,
        walletMap: _walletMap,
        totalIncome: _totalIncome,
        totalExpenses: _totalExpenses,
        balance: _balance,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showEmptyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No transactions in the selected period.'),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Export Transactions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Preparing export…'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSection(),
                  const SizedBox(height: 24),
                  _buildSummarySection(),
                  const SizedBox(height: 32),
                  _buildExportButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSection() {
    return Container(
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
          Text(
            'Report Period',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'From',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'To',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('This Month', _applyThisMonth),
              _buildPresetChip('Last Month', _applyLastMonth),
              _buildPresetChip('Last 3 Months', _applyLast3Months),
              _buildPresetChip('This Year', _applyThisYear),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final display =
        '${date.day} ${months[date.month - 1]} ${date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              display,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
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
          Text(
            'Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Transactions',
            '${_filtered.length}',
            AppColors.textPrimary,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Income',
            '\$${_totalIncome.toStringAsFixed(2)}',
            AppColors.income,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Expenses',
            '\$${_totalExpenses.toStringAsFixed(2)}',
            AppColors.expense,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Balance',
            '\$${_balance.toStringAsFixed(2)}',
            _balance >= 0 ? AppColors.income : AppColors.expense,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export As',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.table_chart_outlined, size: 20),
            label: Text(
              'CSV Spreadsheet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: Text(
              'PDF Report',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Preset helpers ──────────────────────────────────────────────

  void _applyThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  void _applyLastMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0);
    });
  }

  void _applyLast3Months() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 2, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  void _applyThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, 12, 31);
    });
  }
}
