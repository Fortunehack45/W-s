class PredictionOptionItem {
  final String id;
  final String label;
  final int totalPoints;

  PredictionOptionItem({
    required this.id,
    required this.label,
    required this.totalPoints,
  });

  factory PredictionOptionItem.fromJson(Map<String, dynamic> json) {
    return PredictionOptionItem(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

class PredictionMarketItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<PredictionOptionItem> options;
  final int totalPoolPoints;
  final String status;
  final String? winningOptionId;
  final DateTime closesAt;

  PredictionMarketItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.options,
    required this.totalPoolPoints,
    required this.status,
    this.winningOptionId,
    required this.closesAt,
  });

  factory PredictionMarketItem.fromJson(Map<String, dynamic> json) {
    final rawOpts = (json['options'] as List<dynamic>?)
            ?.map((e) => PredictionOptionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PredictionMarketItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      options: rawOpts,
      totalPoolPoints: (json['totalPoolPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'open',
      winningOptionId: json['winningOptionId'] as String?,
      closesAt: json['closesAt'] != null
          ? DateTime.tryParse(json['closesAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class UserPredictionRecord {
  final String id;
  final String marketId;
  final String optionId;
  final int points;
  final int payoutWon;
  final String status;
  final DateTime createdAt;

  UserPredictionRecord({
    required this.id,
    required this.marketId,
    required this.optionId,
    required this.points,
    required this.payoutWon,
    required this.status,
    required this.createdAt,
  });

  factory UserPredictionRecord.fromJson(Map<String, dynamic> json) {
    return UserPredictionRecord(
      id: json['id'] as String? ?? '',
      marketId: json['marketId'] as String? ?? '',
      optionId: json['optionId'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      payoutWon: (json['payoutWon'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
