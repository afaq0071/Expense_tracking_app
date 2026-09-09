import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_colors.dart';
import '../models/expense_model.dart';
import '../models/wallet_model.dart';
import '../services/firestore_service.dart';
import '../services/currency_service.dart';
import '../services/wallet_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isExpense = true;
  String _selectedCategory = Expense.expenseCategories.first;
  bool _isSaving = false;
  bool _showCustomCategory = false;
  final _customCategoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Wallet> _wallets = [];
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await WalletService.instance.getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets.where((w) => w.isActive).toList();
        if (_wallets.isNotEmpty && _selectedWalletId == null) {
          _selectedWalletId = _wallets.first.id;
        }
      });
    } catch (_) {}
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

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final String finalCategory;
    if (_selectedCategory == 'Other') {
      finalCategory = _customCategoryController.text.trim();
      if (finalCategory.isEmpty) return;
    } else {
      finalCategory = _selectedCategory;
    }
    setState(() => _isSaving = true);
    bool success = false;
    try {
      final id = const Uuid().v4();
      final amount = double.parse(_amountController.text.trim());
      final expense = Expense(
        id: id,
        title: _titleController.text.trim(),
        amount: amount,
        category: finalCategory,
        date: _selectedDate,
        isExpense: _isExpense,
        walletId: _selectedWalletId,
      );
      await FirestoreService.instance.addExpense(expense);
      success = true;
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
      if (mounted && !success) {
        setState(() => _isSaving = false);
      }
    }
    if (success && mounted) Navigator.pop(context);
  }

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
              _buildToggle(),
              const SizedBox(height: 32),
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
              _buildAmountField(),
              const SizedBox(height: 24),
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
                    borderRadius: BorderRadius.circular(18),
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
              if (_wallets.isNotEmpty) ...[
                Text(
                  'Wallet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWalletPicker(),
                const SizedBox(height: 24),
              ],
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryBubbles(),
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
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isExpense ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color:
                          _isExpense ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expense',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            _isExpense ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isExpense ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color:
                          !_isExpense ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Income',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            !_isExpense ? Colors.white : AppColors.textSecondary,
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

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixText: '${CurrencyService.instance.currentCurrency.symbol} ',
        prefixStyle: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
        hintText: '0.00',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 28,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 12),
      ),
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
    );
  }

  Widget _buildCategoryBubbles() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _categories.map((cat) {
        final isSelected = cat == _selectedCategory;
        final bgColor = AppColors.categoryBackground(cat);
        final fgColor = AppColors.categoryForeground(cat);
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? fgColor : bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? fgColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: fgColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Expense.categoryIcon(cat),
                  size: 18,
                  color: isSelected ? Colors.white : fgColor,
                ),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : fgColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWalletPicker() {
    return GestureDetector(
      onTap: _showWalletPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedWalletName,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String get _selectedWalletName {
    if (_selectedWalletId == null) return 'No wallet';
    final match = _wallets.where((w) => w.id == _selectedWalletId);
    return match.isNotEmpty ? match.first.name : 'No wallet';
  }

  void _showWalletPicker() {
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
              'Select Wallet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'No wallet',
                style: GoogleFonts.poppins(
                  color: _selectedWalletId == null
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              trailing: _selectedWalletId == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedWalletId = null);
                Navigator.pop(ctx);
              },
            ),
            ..._wallets.map((wallet) => ListTile(
                  leading: Icon(
                    Wallet.iconFromName(wallet.iconName),
                    color: AppColors.textSecondary,
                  ),
                  title: Text(
                    wallet.name,
                    style: GoogleFonts.poppins(
                      color: _selectedWalletId == wallet.id
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: _selectedWalletId == wallet.id
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedWalletId = wallet.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isExpense ? AppColors.expense : AppColors.income,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
    );
  }
}
