import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/expense_model.dart';

/// Handles CSV and PDF export of transactions, and sharing the generated files.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── Filtering ─────────────────────────────────────────────────────

  /// Filters [expenses] to those within [startDate] (inclusive) and
  /// [endDate] (inclusive), sorted oldest-first for chronological output.
  List<Expense> filterByDateRange(
    List<Expense> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final filtered = expenses.where((e) {
      return !e.date.isBefore(startDate) && !e.date.isAfter(end);
    }).toList();
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  // ── CSV ───────────────────────────────────────────────────────────

  /// Builds a CSV string from [expenses] using [walletMap] for name lookup.
  String buildCsv(
    List<Expense> expenses,
    Map<String, String> walletMap,
  ) {
    final buf = StringBuffer();
    buf.writeln('Date,Title,Type,Category,Amount,Wallet,Notes');

    for (final e in expenses) {
      final date = _csvDate(e.date);
      final title = _csvEscape(e.title);
      final type = e.isExpense ? 'Expense' : 'Income';
      final category = _csvEscape(e.category);
      final amount = e.amount.toStringAsFixed(2);
      final wallet = _csvEscape(walletMap[e.walletId] ?? 'N/A');
      buf.writeln('$date,$title,$type,$category,$amount,$wallet,');
    }

    return buf.toString();
  }

  /// Writes [csv] to a temp file and shares it.
  Future<void> shareCsv(String csv, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)]);
  }

  // ── PDF ───────────────────────────────────────────────────────────

  /// Generates a monthly PDF report and shares it.
  Future<void> generateAndSharePdf({
    required String title,
    required List<Expense> expenses,
    required Map<String, String> walletMap,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    final pdf = pw.Document();

    // Build category breakdown
    final categoryTotals = <String, double>{};
    for (final e in expenses) {
      if (e.isExpense) {
        categoryTotals[e.category] =
            (categoryTotals[e.category] ?? 0) + e.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary
          _summaryRow('Total Income', '\$${totalIncome.toStringAsFixed(2)}'),
          _summaryRow('Total Expenses', '\$${totalExpenses.toStringAsFixed(2)}'),
          _summaryRow('Balance', '\$${balance.toStringAsFixed(2)}'),
          pw.SizedBox(height: 20),

          // Category breakdown
          if (categoryTotals.isNotEmpty) ...[
            pw.Header(
              level: 1,
              child: pw.Text(
                'Expense Breakdown by Category',
                style: pw.TextStyle(fontSize: 16),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Amount', '% of Total'],
              data: categoryTotals.entries.map((e) {
                final pct = totalExpenses > 0
                    ? ((e.value / totalExpenses) * 100).toStringAsFixed(1)
                    : '0.0';
                return [e.key, '\$${e.value.toStringAsFixed(2)}', '$pct%'];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
          ],

          // Transaction list
          if (expenses.isNotEmpty) ...[
            pw.Header(
              level: 1,
              child: pw.Text(
                'Transactions',
                style: pw.TextStyle(fontSize: 16),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Title', 'Type', 'Category', 'Amount', 'Wallet'],
              data: expenses.map((e) {
                final wallet = walletMap[e.walletId] ?? 'N/A';
                final amount = '${e.isExpense ? '-' : '+'}'
                    '\$${e.amount.toStringAsFixed(2)}';
                return [
                  _pdfDate(e.date),
                  e.title,
                  e.isExpense ? 'Expense' : 'Income',
                  e.category,
                  amount,
                  wallet,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.3),
                5: const pw.FlexColumnWidth(1.5),
              },
            ),
          ] else ...[
            pw.Center(
              child: pw.Text(
                'No transactions for this period.',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$title.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  // ── Helpers ───────────────────────────────────────────────────────

  static String _csvDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _pdfDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
