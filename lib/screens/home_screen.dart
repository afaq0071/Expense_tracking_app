import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';
import '../models/wallet_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/wallet_service.dart';
import '../widgets/expense_card.dart';
import '../widgets/fade_slide_in.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'recurring_transactions_screen.dart';
import 'wallets_screen.dart';
import 'savings_goals_screen.dart';
import 'notification_settings_screen.dart';
import 'export_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _balance = 0;
  String _userName = 'User';
  bool _isLoading = true;
  List<Wallet> _wallets = [];
  String? _selectedWalletId;
  int _bottomNavIndex = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _filterType = 'all';
  String? _filterCategory;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool get _hasActiveFilters =>
      _filterType != 'all' ||
      _filterCategory != null ||
      _filterStartDate != null ||
      _filterEndDate != null;

  List<String> get _availableCategories {
    final cats = <String>{};
    for (final e in _expenses) {
      cats.add(e.category);
    }
    return cats.toList()..sort();
  }

  List<Expense> get _walletExpenses {
    if (_selectedWalletId == null) return _expenses;
    return _expenses.where((e) => e.walletId == _selectedWalletId).toList();
  }

  double get _displayBalance {
    if (_selectedWalletId == null) return _balance;
    return WalletService.instance.calculateBalance(
      _expenses,
      _selectedWalletId!,
    );
  }

  double get _displayIncome {
    if (_selectedWalletId == null) return _totalIncome;
    double income = 0;
    for (final e in _walletExpenses) {
      if (!e.isExpense) income += e.amount;
    }
    return income;
  }

  double get _displayExpenses {
    if (_selectedWalletId == null) return _totalExpenses;
    double spent = 0;
    for (final e in _walletExpenses) {
      if (e.isExpense) spent += e.amount;
    }
    return spent;
  }

  List<Expense> get _currentMonthExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.date.year == now.year &&
          e.date.month == now.month &&
          e.isExpense;
    }).toList();
  }

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

  List<MapEntry<String, double>> get _categoryBreakdown {
    final map = <String, double>{};
    for (final e in _currentMonthExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<Expense> get _filteredExpenses {
    var list = _walletExpenses;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query);
      }).toList();
    }
    if (_filterType == 'income') {
      list = list.where((e) => !e.isExpense).toList();
    } else if (_filterType == 'expense') {
      list = list.where((e) => e.isExpense).toList();
    }
    if (_filterCategory != null) {
      list = list.where((e) => e.category == _filterCategory).toList();
    }
    if (_filterStartDate != null) {
      list = list.where((e) => !e.date.isBefore(_filterStartDate!)).toList();
    }
    if (_filterEndDate != null) {
      final endDay = DateTime(
        _filterEndDate!.year,
        _filterEndDate!.month,
        _filterEndDate!.day,
      ).add(const Duration(days: 1));
      list = list.where((e) => e.date.isBefore(endDay)).toList();
    }
    return list;
  }

  Future<void> _loadExpenses() async {
    try {
      final results = await Future.wait([
        FirestoreService.instance.getUserName(),
        FirestoreService.instance.getExpenses(),
        WalletService.instance.getWallets(),
      ]);
      if (!mounted) return;
      final expenses = results[1] as List<Expense>;
      final wallets = results[2] as List<Wallet>;
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
        _wallets = wallets;
        _totalIncome = income;
        _totalExpenses = spent;
        _balance = income - spent;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirestoreService.describeError(e),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
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

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    if (confirmed != true) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _goToAddExpense() async {
    await Navigator.pushNamed(context, '/add-expense');
    _loadExpenses();
  }

  void _goToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsScreen(expenses: _expenses),
      ),
    );
  }

  void _goToBudgets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetScreen(expenses: _expenses),
      ),
    );
  }

  void _goToRecurringTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecurringTransactionsScreen(),
      ),
    );
  }

  void _goToWallets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletsScreen(expenses: _expenses),
      ),
    ).then((_) => _loadExpenses());
  }

  void _goToSavingsGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavingsGoalsScreen(),
      ),
    );
  }

  void _goToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _goToExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportScreen(
          expenses: _expenses,
          wallets: _wallets,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

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
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: _buildHeader(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: _buildWalletSelector(),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: _buildBalanceCard(),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: _buildSummaryRow(),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 500),
                        child: _buildMonthSummary(),
                      ),
                      if (_categoryBreakdown.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildCategoryBreakdown(),
                      ],
                      const SizedBox(height: 24),
                      _buildTransactionsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning,',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildHeaderIcon(
                onTap: _handleLogout,
                icon: Icons.logout_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.hardEdge,
              children: [
                _buildHeaderIcon(
                  onTap: _goToWallets,
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  onTap: _goToRecurringTransactions,
                  icon: Icons.repeat,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  onTap: _goToBudgets,
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  onTap: _goToAnalytics,
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  onTap: _goToSavingsGoals,
                  icon: Icons.savings_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  onTap: _goToNotificationSettings,
                  icon: Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  onTap: _goToExport,
                  icon: Icons.file_download_outlined,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── Wallet selector ─────────────────────────────────────────────

  Widget _buildWalletSelector() {
    if (_wallets.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildWalletChip(
            label: 'All',
            icon: Icons.account_balance_wallet_outlined,
            selected: _selectedWalletId == null,
            onTap: () => setState(() => _selectedWalletId = null),
          ),
          const SizedBox(width: 8),
          ..._wallets.map((wallet) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildWalletChip(
                  label: wallet.name,
                  icon: Wallet.iconFromName(wallet.iconName),
                  selected: _selectedWalletId == wallet.id,
                  onTap: () => setState(() => _selectedWalletId = wallet.id),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWalletChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.inputBorder,
          ),
          boxShadow: selected ? AppColors.softShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Balance card ────────────────────────────────────────────────

  Widget _buildBalanceCard() {
    final walletName = _selectedWalletId != null
        ? (_wallets
                .where((w) => w.id == _selectedWalletId)
                .map((w) => w.name)
                .firstOrNull ??
            'All Wallets')
        : 'All Wallets';
    final walletExpenses = _walletExpenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decorative bubbles inside the card ────────────────
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 40,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      walletName,
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
                  'Total Balance',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(_displayBalance),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  walletExpenses.isEmpty
                      ? 'No transactions yet'
                      : '${walletExpenses.length} transaction${walletExpenses.length == 1 ? '' : 's'} recorded',
                  style: GoogleFonts.poppins(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary row ─────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildSummaryCard(
            title: 'Income',
            amount: _formatCurrency(_displayIncome),
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            title: 'Expenses',
            amount: _formatCurrency(_displayExpenses),
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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

  // ── Month summary ───────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
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

  Widget _buildEmptyMonthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
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

  // ── Category breakdown ──────────────────────────────────────────

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
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                ...breakdown.map((entry) {
                  final pct = total > 0
                      ? (entry.value / total * 100).toStringAsFixed(1)
                      : '0';
                  final fgColor = AppColors.categoryForeground(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.categoryBackground(entry.key),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Expense.categoryIcon(entry.key),
                                size: 16,
                                color: fgColor,
                              ),
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
                            valueColor: AlwaysStoppedAnimation(fgColor),
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

  // ── Transactions section ────────────────────────────────────────

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
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeFilterChips(),
            const SizedBox(height: 12),
            _buildCategoryAndDateRow(),
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
          color: selected ? (color ?? AppColors.primary) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.inputBorder,
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

  Widget _buildCategoryAndDateRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  void _showCategoryPicker() {
    final categories = _availableCategories;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
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

  Widget _buildNoResultsState() {
    final hasFilters = _hasActiveFilters || _searchQuery.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
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

  // ── FAB ─────────────────────────────────────────────────────────

  Widget _buildFab() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
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

  // ── Bottom navigation bar ───────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Transactions',
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: _buildNavItem(
                  index: 2,
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  label: 'Reports',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _bottomNavIndex = index);
        switch (index) {
          case 1:
            // Already on home, transactions are shown here
            break;
          case 2:
            _goToAnalytics();
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
