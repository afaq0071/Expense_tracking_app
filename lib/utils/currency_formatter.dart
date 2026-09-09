import '../models/currency_model.dart';

/// Centralized currency formatting utility.
///
/// All currency formatting throughout the app should go through this utility
/// to ensure consistency and proper locale-aware formatting.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format an amount with the given currency's symbol and decimal rules.
  ///
  /// Examples:
  ///   format(1500, usd) → "$1,500.00"
  ///   format(1500, pkr) → "Rs. 1,500.00"
  ///   format(150000, jpy) → "¥150,000"
  static String format(double amount, AppCurrency currency) {
    final absAmount = amount.abs();
    final formatted = _numberWithCommas(absAmount, currency.decimalDigits);
    return '${currency.symbol}$formatted';
  }

  /// Format with a + or - prefix based on sign.
  ///
  /// Used for income (+) / expense (-) display.
  static String formatSigned(double amount, AppCurrency currency,
      {bool isExpense = true}) {
    final prefix = isExpense ? '-' : '+';
    return '$prefix${format(amount, currency)}';
  }

  /// Format without the symbol — just the number with commas and decimals.
  ///
  /// Useful for labels, tooltips, or when the symbol is shown separately.
  static String formatNumber(double amount, {int decimalDigits = 2}) {
    return _numberWithCommas(amount.abs(), decimalDigits);
  }

  /// Format a compact version for charts (e.g., "$1.5k", "Rs. 50k").
  static String formatCompact(double amount, AppCurrency currency) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    String value;
    if (abs >= 1000000) {
      value = '${(abs / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      value = '${(abs / 1000).toStringAsFixed(1)}k';
    } else {
      value = abs.toStringAsFixed(currency.decimalDigits);
    }
    return '$sign${currency.symbol}$value';
  }

  /// Format with explicit decimal digits override.
  static String formatWithDecimals(
      double amount, AppCurrency currency, int decimals) {
    final absAmount = amount.abs();
    final formatted = _numberWithCommas(absAmount, decimals);
    return '${currency.symbol}$formatted';
  }

  // ── Internal helpers ──────────────────────────────────────────────

  /// Adds thousand separators and correct decimal places.
  static String _numberWithCommas(double number, int decimalPlaces) {
    final fixed = number.toStringAsFixed(decimalPlaces);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;

    // Add commas to integer part
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    if (decimalPlaces > 0 && decPart != null) {
      buffer.write('.');
      buffer.write(decPart);
    }

    return buffer.toString();
  }
}
