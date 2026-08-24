import 'package:flutter/material.dart';

/// Wallet model representing a user's payment method / account.
///
/// Each wallet has a unique [id], a display [name], an icon identifier,
/// and an active/inactive flag. Balance is computed at runtime from
/// associated expenses — not stored in the document.
class Wallet {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;

  const Wallet({
    required this.id,
    required this.name,
    required this.iconName,
    this.isActive = true,
  });

  // ── Preset wallets ────────────────────────────────────────────────

  /// Default wallet names offered during first-time setup.
  static const List<Map<String, String>> presets = [
    {'name': 'Cash', 'icon': 'cash'},
    {'name': 'Bank Account', 'icon': 'bank'},
    {'name': 'Easypaisa', 'icon': 'easypaisa'},
    {'name': 'JazzCash', 'icon': 'jazzcash'},
  ];

  // ── Icon mapping ──────────────────────────────────────────────────

  static IconData iconFromName(String iconName) {
    const icons = <String, IconData>{
      'cash': Icons.payments_outlined,
      'bank': Icons.account_balance_outlined,
      'easypaisa': Icons.phone_android_outlined,
      'jazzcash': Icons.phone_iphone_outlined,
      'credit_card': Icons.credit_card_outlined,
      'savings': Icons.savings_outlined,
      'wallet': Icons.account_balance_wallet_outlined,
      'other': Icons.more_horiz_outlined,
    };
    return icons[iconName] ?? Icons.account_balance_wallet_outlined;
  }

  static const List<String> availableIcons = [
    'cash',
    'bank',
    'easypaisa',
    'jazzcash',
    'credit_card',
    'savings',
    'wallet',
    'other',
  ];

  // ── JSON serialization ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'isActive': isActive,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String? ?? 'wallet',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // ── Copy with ─────────────────────────────────────────────────────

  Wallet copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
    );
  }
}
