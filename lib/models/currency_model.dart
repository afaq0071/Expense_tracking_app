/// ISO 4217 currency data model.
///
/// Each currency has a code, name, symbol, and decimal digits.
/// Used throughout the app for formatting and display.
class AppCurrency {
  final String code;
  final String name;
  final String symbol;
  final int decimalDigits;

  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalDigits = 2,
  });

  // ── Supported currencies ─────────────────────────────────────────

  static const List<AppCurrency> supported = [
    AppCurrency(code: 'USD', name: 'US Dollar', symbol: '\$', decimalDigits: 2),
    AppCurrency(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs.', decimalDigits: 2),
    AppCurrency(code: 'GBP', name: 'British Pound', symbol: '£', decimalDigits: 2),
    AppCurrency(code: 'EUR', name: 'Euro', symbol: '€', decimalDigits: 2),
    AppCurrency(code: 'INR', name: 'Indian Rupee', symbol: '₹', decimalDigits: 2),
    AppCurrency(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', decimalDigits: 2),
    AppCurrency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', decimalDigits: 2),
    AppCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', decimalDigits: 2),
    AppCurrency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', decimalDigits: 2),
    AppCurrency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', decimalDigits: 0),
    AppCurrency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', decimalDigits: 2),
    AppCurrency(code: 'TRY', name: 'Turkish Lira', symbol: '₺', decimalDigits: 2),
    AppCurrency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', decimalDigits: 2),
    AppCurrency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', decimalDigits: 2),
    AppCurrency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', decimalDigits: 2),
    AppCurrency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', decimalDigits: 2),
    AppCurrency(code: 'DKK', name: 'Danish Krone', symbol: 'kr', decimalDigits: 2),
    AppCurrency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', decimalDigits: 2),
    AppCurrency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', decimalDigits: 2),
    AppCurrency(code: 'KRW', name: 'South Korean Won', symbol: '₩', decimalDigits: 0),
    AppCurrency(code: 'ZAR', name: 'South African Rand', symbol: 'R', decimalDigits: 2),
    AppCurrency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', decimalDigits: 2),
    AppCurrency(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$', decimalDigits: 2),
    AppCurrency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', decimalDigits: 2),
    AppCurrency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£', decimalDigits: 2),
    AppCurrency(code: 'PHP', name: 'Philippine Peso', symbol: '₱', decimalDigits: 2),
    AppCurrency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', decimalDigits: 0),
    AppCurrency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', decimalDigits: 2),
    AppCurrency(code: 'THB', name: 'Thai Baht', symbol: '฿', decimalDigits: 2),
    AppCurrency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', decimalDigits: 0),
    AppCurrency(code: 'PLN', name: 'Polish Zloty', symbol: 'zł', decimalDigits: 2),
    AppCurrency(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', decimalDigits: 2),
    AppCurrency(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft', decimalDigits: 0),
    AppCurrency(code: 'ILS', name: 'Israeli Shekel', symbol: '₪', decimalDigits: 2),
    AppCurrency(code: 'CLP', name: 'Chilean Peso', symbol: 'CL\$', decimalDigits: 0),
    AppCurrency(code: 'TWD', name: 'Taiwan Dollar', symbol: 'NT\$', decimalDigits: 0),
    AppCurrency(code: 'ARS', name: 'Argentine Peso', symbol: 'AR\$', decimalDigits: 2),
    AppCurrency(code: 'COP', name: 'Colombian Peso', symbol: 'COL\$', decimalDigits: 2),
    AppCurrency(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', decimalDigits: 2),
    AppCurrency(code: 'QAR', name: 'Qatari Riyal', symbol: 'QR', decimalDigits: 2),
    AppCurrency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'KD', decimalDigits: 3),
    AppCurrency(code: 'BHD', name: 'Bahraini Dinar', symbol: 'BD', decimalDigits: 3),
    AppCurrency(code: 'OMR', name: 'Omani Rial', symbol: 'OMR', decimalDigits: 3),
    AppCurrency(code: 'JOD', name: 'Jordanian Dinar', symbol: 'JD', decimalDigits: 3),
    AppCurrency(code: 'LBP', name: 'Lebanese Pound', symbol: 'L£', decimalDigits: 2),
    AppCurrency(code: 'ISK', name: 'Icelandic Krona', symbol: 'kr', decimalDigits: 0),
  ];

  // ── Default ──────────────────────────────────────────────────────

  static const AppCurrency defaultCurrency = AppCurrency(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    decimalDigits: 2,
  );

  // ── Lookup ───────────────────────────────────────────────────────

  /// Find a currency by its ISO code. Returns [defaultCurrency] if not found.
  static AppCurrency fromCode(String? code) {
    if (code == null) return defaultCurrency;
    for (final c in supported) {
      if (c.code == code) return c;
    }
    return defaultCurrency;
  }

  // ── JSON ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'decimalDigits': decimalDigits,
      };

  factory AppCurrency.fromJson(Map<String, dynamic> json) {
    return AppCurrency(
      code: json['code'] as String? ?? 'USD',
      name: json['name'] as String? ?? 'US Dollar',
      symbol: json['symbol'] as String? ?? '\$',
      decimalDigits: json['decimalDigits'] as int? ?? 2,
    );
  }

  // ── Equality ─────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$code ($symbol)';
}
