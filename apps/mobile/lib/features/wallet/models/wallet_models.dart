/// Client-facing wallet summary model.
class WalletSummary {
  const WalletSummary({
    required this.availableW,
    required this.reservedW,
    required this.earnedWBalance,
    required this.purchasedWBalance,
  });

  final int availableW;
  final int reservedW;
  final int earnedWBalance;
  final int purchasedWBalance;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      availableW: json['availableW'] as int? ?? 0,
      reservedW: json['reservedW'] as int? ?? 0,
      earnedWBalance: json['earnedWBalance'] as int? ?? 0,
      purchasedWBalance: json['purchasedWBalance'] as int? ?? 0,
    );
  }
}

/// Ledger item model for transaction history.
class LedgerItem {
  const LedgerItem({
    required this.id,
    required this.eventType,
    required this.pointAmount,
    required this.balanceSource,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final int pointAmount;
  final String balanceSource;
  final String referenceType;
  final String referenceId;
  final DateTime createdAt;

  factory LedgerItem.fromJson(Map<String, dynamic> json) {
    return LedgerItem(
      id: json['id'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      pointAmount: json['pointAmount'] as int? ?? 0,
      balanceSource: json['balanceSource'] as String? ?? '',
      referenceType: json['referenceType'] as String? ?? '',
      referenceId: json['referenceId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
