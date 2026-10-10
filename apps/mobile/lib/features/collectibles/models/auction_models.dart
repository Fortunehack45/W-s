class AuctionListingItem {
  final String id;
  final String cardInstanceId;
  final String cardName;
  final String cardRarity;
  final String artworkUrl;
  final int serialNumber;
  final String sellerId;
  final int minimumBidW;
  final int currentHighestBidW;
  final String? currentBidderId;
  final String status;
  final DateTime endsAt;
  final int bidCount;
  final double feePercentage;

  AuctionListingItem({
    required this.id,
    required this.cardInstanceId,
    required this.cardName,
    required this.cardRarity,
    required this.artworkUrl,
    required this.serialNumber,
    required this.sellerId,
    required this.minimumBidW,
    required this.currentHighestBidW,
    this.currentBidderId,
    required this.status,
    required this.endsAt,
    required this.bidCount,
    required this.feePercentage,
  });

  factory AuctionListingItem.fromJson(Map<String, dynamic> json) {
    final card = json['card'] as Map<String, dynamic>?;
    final def = card?['definition'] as Map<String, dynamic>?;

    return AuctionListingItem(
      id: json['id'] as String? ?? '',
      cardInstanceId: json['cardInstanceId'] as String? ?? '',
      cardName: def?['name'] as String? ?? (card?['name'] as String? ?? 'Streak Card'),
      cardRarity: def?['rarity'] as String? ?? (card?['rarity'] as String? ?? 'common'),
      artworkUrl: def?['artworkUrl'] as String? ?? 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
      serialNumber: (card?['serialNumber'] as num?)?.toInt() ?? 1,
      sellerId: json['sellerId'] as String? ?? '',
      minimumBidW: (json['minimumBidW'] as num?)?.toInt() ?? 10,
      currentHighestBidW: (json['currentHighestBidW'] as num?)?.toInt() ?? 0,
      currentBidderId: json['currentBidderId'] as String?,
      status: json['status'] as String? ?? 'active',
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'] as String) ?? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      bidCount: (json['bidCount'] as num?)?.toInt() ?? 0,
      feePercentage: (json['feePercentage'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
