import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/expense_card.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';

/// Main dashboard screen showing balance summary and recent transactions.
///
/// Loads all expenses from [FirestoreService] and refreshes when the
/// screen becomes visible (e.g., after adding an entry).
/// Shows the user's real name and provides a logout button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State ──────────────────────────────────────────────────────────

  List<Expense> _expenses = [];
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _balance = 0;
  String _userName = 'User';
  bool _isLoading = true;

  // ── Search state ─────────────────────────────────────────────────
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // ── Filter state ─────────────────────────────────────────────────
  String _filterType = 'all'; // 'all', 'income', 'expense'
  String? _filterCategory;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool get _hasActiveFilters =>
      _filterType != 'all' ||
      _filterCategory != null ||
      _filterStartDate != null ||
      _filterEndDate != null;

  /// Available categories derived from loaded expenses.
  List<String> get _availableCategories {
    final cats = <String>{};
    for (final e in _expenses) {
      cats.add(e.category);
    }
    return cats.toList()..sort();
  }

  // ── Current-month statistics (computed from _expenses, no Firestore) ──

  /// Expenses falling in the current calendar month.
  List<Expense> get _currentMonthExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.date.year == now.year &&
          e.date.month == now.month &&
          e.isExpense;
    }).toList();
  }

  /// Income falling in the current calendar month.
  List<Expense> get _currentMonthIncome {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.date.year == now.year &&
          e.date.month == now.month &&
          !e.isExpense;
    }).toList();
  }

  double get _currentMonthIncomeTotal =>
      _currentMonthIncome.fold(0.0, (sum, e) => sum + e.amount);

  double get _currentMonthExpenseTotal =>
      _currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  double get _currentMonthSavings =>
      _currentMonthIncomeTotal - _currentMonthExpenseTotal;

  /// Category → total amount for current-month expenses, sorted descending.
  List<MapEntry<String, double>> get _categoryBreakdown {
    final map = <String, double>{};
    for (final e in _currentMonthExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Applies search + type + category + date range filters locally.
  List<Expense> get _filteredExpenses {
    var list = _expenses;

    // ── Search filter (case-insensitive on title / category) ──────
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query);
      }).toList();
    }

    // ── Type filter ───────────────────────────────────────────────
    if (_filterType == 'income') {
      list = list.where((e) => !e.isExpense).toList();
    } else if (_filterType == 'expense') {
      list = list.where((e) => e.isExpense).toList();
    }

    // ── Category filter ───────────────────────────────────────────
    if (_filterCategory != null) {
      list = list.where((e) => e.category == _filterCategory).toList();
    }

    // ── Date range filter ─────────────────────────────────────────
    if (_filterStartDate != null) {
      list = list.where((e) => !e.date.isBefore(_filterStartDate!)).toList();
    }
    if (_filterEndDate != null) {
      // Include the entire end day.
      final endDay = DateTime(
        _filterEndDate!.year,
        _filterEndDate!.month,
        _filterEndDate!.day,
      ).add(const Duration(days: 1));
      list = list.where((e) => e.date.isBefore(endDay)).toList();
    }

    return list;
  }

  // ── Load data from Firestore ───────────────────────────────────────

  Future<void> _loadExpenses() async {
    try {
      // Fetch user name and expenses once; totals are computed locally
      // from that single result instead of extra Firestore reads.
      final results = await Future.wait([
        FirestoreService.instance.getUserName(),
        FirestoreService.instance.getExpenses(),
      ]);

      if (!mounted) return;

      final expenses = results[1] as List<Expense>;

      double income = 0;
      double spent = 0;
      for (final e in expenses) {
        if (e.isExpense) {
          spent += e.amount;
        } else {
          income += e.amount;
        }
      }

      setState(() {
        _userName = results[0] as String;
        _expenses = expenses;
        _totalIncome = income;
        _totalExpenses = spent;
        _balance = income - spent;
      });
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
      // Never leave the spinner stuck after an error.
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Delete handler ─────────────────────────────────────────────────

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Entry',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove "${expense.title}" from your records?',
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
      await FirestoreService.instance.deleteExpense(expense.id);
      _loadExpenses();
    }
  }

  // ── Logout handler ─────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to log out?',
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
              'Log Out',
              style: GoogleFonts.poppins(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );

    // Only log out when the user confirms the dialog.
    if (confirmed != true) return;

    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  // ── Navigate to add screen ─────────────────────────────────────────

  Future<void> _goToAddExpense() async {
    await Navigator.pushNamed(context, '/add-expense');
    _loadExpenses();
  }

  // ── Navigate to analytics screen ──────────────────────────────────

  void _goToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsScreen(expenses: _expenses),
      ),
    );
  }

  // ── Navigate to budget screen ─────────────────────────────────────

  void _goToBudgets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetScreen(expenses: _expenses),
      ),
    );
  }

  // ── Format currency ────────────────────────────────────────────────

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // ── Filter helpers ─────────────────────────────────────────────────

  void _clearFilters() {
    setState(() {
      _filterType = 'all';
      _filterCategory = null;
      _filterStartDate = null;
      _filterEndDate = null;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
    );
    if (picked != null && mounted) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadExpenses,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildBalanceCard(),
                      const SizedBox(height: 24),
                      _buildSummaryRow(),
                      const SizedBox(height: 24),
                      _buildMonthSummary(),
                      if (_categoryBreakdown.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildCategoryBreakdown(),
                      ],
                      const SizedBox(height: 32),
                      _buildTransactionsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Widget builders ──────────────────────────────────────────────

  /// Header with user greeting and logout button.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $_userName 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Budget button
          GestureDetector(
            onTap: _goToBudgets,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Analytics button
          GestureDetector(
            onTap: _goToAnalytics,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Logout button
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.expense,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Main balance card with gradient background.
  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Balance',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _formatCurrency(_balance),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _expenses.isEmpty
                  ? 'No transactions yet'
                  : '${_expenses.length} transaction${_expenses.length == 1 ? '' : 's'} recorded',
              style: GoogleFonts.poppins(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Side-by-side income and expense summary cards.
  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildSummaryCard(
            title: 'Income',
            amount: _formatCurrency(_totalIncome),
            icon: Icons.arrow_downward_rounded,
            gradient: AppColors.incomeGradient,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            title: 'Expenses',
            amount: _formatCurrency(_totalExpenses),
            icon: Icons.arrow_upward_rounded,
            gradient: AppColors.expenseGradient,
          ),
        ],
      ),
    );
  }

  /// Single summary card (used in the income/expense row).
  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Expanded(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Current month summary — income, expenses, and savings.
  Widget _buildMonthSummary() {
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel = '${monthNames[now.month - 1]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (_expenses.isEmpty)
            _buildEmptyMonthCard()
          else
            Row(
              children: [
                _buildMonthStatCard(
                  label: 'Income',
                  amount: _formatCurrency(_currentMonthIncomeTotal),
                  color: AppColors.income,
                ),
                const SizedBox(width: 10),
                _buildMonthStatCard(
                  label: 'Expenses',
                  amount: _formatCurrency(_currentMonthExpenseTotal),
                  color: AppColors.expense,
                ),
                const SizedBox(width: 10),
                _buildMonthStatCard(
                  label: 'Savings',
                  amount: _formatCurrency(_currentMonthSavings),
                  color: _currentMonthSavings >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Compact stat card used inside the month summary row.
  Widget _buildMonthStatCard({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder when no data exists for the month summary.
  Widget _buildEmptyMonthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No data for this month yet',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Spending breakdown by category for the current month.
  Widget _buildCategoryBreakdown() {
    final breakdown = _categoryBreakdown;
    final total = _currentMonthExpenseTotal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
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
                ...breakdown.map((entry) {
                  final pct = total > 0
                      ? (entry.value / total * 100).toStringAsFixed(1)
                      : '0';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Expense.categoryIcon(entry.key),
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(entry.value),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$pct%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? entry.value / total : 0,
                            backgroundColor: AppColors.inputFill,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.primary),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Transaction list section with search, filters, and items.
  Widget _buildTransactionsSection() {
    final displayExpenses = _filteredExpenses;
    final isActive = _hasActiveFilters || _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_expenses.isNotEmpty)
                Text(
                  isActive
                      ? '${displayExpenses.length} of ${_expenses.length}'
                      : '${_expenses.length} total',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Search field ──────────────────────────────────────
          if (_expenses.isNotEmpty) ...[
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              ),
            ),
            const SizedBox(height: 12),

            // ── Type filter chips ───────────────────────────────
            _buildTypeFilterChips(),
            const SizedBox(height: 12),

            // ── Category + Date range row ───────────────────────
            _buildCategoryAndDateRow(),

            // ── Active filter summary + clear ───────────────────
            if (isActive) ...[
              const SizedBox(height: 12),
              _buildActiveFilterBar(displayExpenses.length),
            ],

            const SizedBox(height: 16),
          ],

          if (_expenses.isEmpty)
            _buildEmptyState()
          else if (displayExpenses.isEmpty)
            _buildNoResultsState()
          else
            ...List.generate(displayExpenses.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < displayExpenses.length - 1 ? 12 : 0,
                ),
                child: ExpenseCard(
                  expense: displayExpenses[index],
                  onLongPress: () => _deleteExpense(displayExpenses[index]),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Type filter chips: All / Income / Expense.
  Widget _buildTypeFilterChips() {
    return Row(
      children: [
        _buildFilterChip(
          label: 'All',
          selected: _filterType == 'all',
          onTap: () => setState(() => _filterType = 'all'),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: 'Income',
          selected: _filterType == 'income',
          onTap: () => setState(() => _filterType = 'income'),
          color: AppColors.income,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: 'Expense',
          selected: _filterType == 'expense',
          onTap: () => setState(() => _filterType = 'expense'),
          color: AppColors.expense,
        ),
      ],
    );
  }

  /// Single filter chip.
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (color ?? AppColors.primary)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Category dropdown + date range picker row.
  Widget _buildCategoryAndDateRow() {
    return Row(
      children: [
        // ── Category dropdown ────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filterCategory ?? 'All Categories',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _filterCategory != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ── Date range button ────────────────────────────────────
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _filterStartDate != null
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  color: _filterStartDate != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _filterStartDate != null ? 'Date Range' : 'Date',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _filterStartDate != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows a modal bottom sheet with category options.
  void _showCategoryPicker() {
    final categories = _availableCategories;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'All Categories',
                style: GoogleFonts.poppins(
                  color: _filterCategory == null
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              trailing: _filterCategory == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _filterCategory = null);
                Navigator.pop(ctx);
              },
            ),
            ...categories.map((cat) => ListTile(
                  title: Text(
                    cat,
                    style: GoogleFonts.poppins(
                      color: _filterCategory == cat
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: _filterCategory == cat
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _filterCategory = cat);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// Active filter summary bar with clear button.
  Widget _buildActiveFilterBar(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_outlined,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count result${count == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when there are no transactions.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first entry',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when search returns no results.
  Widget _buildNoResultsState() {
    final hasFilters = _hasActiveFilters || _searchQuery.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your filters or search term'
                : 'Try a different search term',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Gradient floating action button.
  Widget _buildFab() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _goToAddExpense,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
