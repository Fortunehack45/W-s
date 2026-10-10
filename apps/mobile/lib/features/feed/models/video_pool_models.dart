/// Video W pool metrics and current market valuation.
class VideoWPool {
  const VideoWPool({
    required this.videoId,
    required this.currentWCount,
    required this.reserveBalance,
    required this.totalShares,
    required this.basePriceW,
    required this.creatorRoyaltyBps,
  });

  final String videoId;
  final int currentWCount;
  final int reserveBalance;
  final int totalShares;
  final int basePriceW;
  final int creatorRoyaltyBps;

  int get pricePerShareW =>
      totalShares > 0 ? (reserveBalance / totalShares).round().clamp(1, 999999) : (basePriceW > 0 ? basePriceW : 1);

  factory VideoWPool.fromJson(Map<String, dynamic> json) {
    return VideoWPool(
      videoId: json['videoId'] as String? ?? '',
      currentWCount: json['currentWCount'] as int? ?? 0,
      reserveBalance: json['reserveBalance'] as int? ?? 0,
      totalShares: json['totalShares'] as int? ?? 0,
      basePriceW: json['basePriceW'] as int? ?? 1,
      creatorRoyaltyBps: json['creatorRoyaltyBps'] as int? ?? 200,
    );
  }
}

/// User's active position in a specific video.
class UserPosition {
  const UserPosition({
    required this.videoId,
    required this.sharesOwned,
    required this.wCostBasis,
    required this.totalWRealizedPnL,
  });

  final String videoId;
  final int sharesOwned;
  final int wCostBasis;
  final int totalWRealizedPnL;

  factory UserPosition.fromJson(Map<String, dynamic> json) {
    return UserPosition(
      videoId: json['videoId'] as String? ?? '',
      sharesOwned: json['sharesOwned'] as int? ?? 0,
      wCostBasis: json['wCostBasis'] as int? ?? 0,
      totalWRealizedPnL: json['totalWRealizedPnl'] as int? ?? 0,
    );
  }
}
