class AdCampaign {
  final String id;
  final String advertiserId;
  final String videoId;
  final String campaignName;
  final String headline;
  final String callToActionUrl;
  final String callToActionLabel;
  final int budgetCents;
  final int spentCents;
  final int cpmBidCents;
  final String status;
  final int impressionCount;
  final int clickCount;
  final DateTime startsAt;
  final DateTime endsAt;

  AdCampaign({
    required this.id,
    required this.advertiserId,
    required this.videoId,
    required this.campaignName,
    required this.headline,
    required this.callToActionUrl,
    required this.callToActionLabel,
    required this.budgetCents,
    required this.spentCents,
    required this.cpmBidCents,
    required this.status,
    required this.impressionCount,
    required this.clickCount,
    required this.startsAt,
    required this.endsAt,
  });

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    return AdCampaign(
      id: json['id'] as String? ?? '',
      advertiserId: json['advertiserId'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      campaignName: json['campaignName'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      callToActionUrl: json['callToActionUrl'] as String? ?? '',
      callToActionLabel: json['callToActionLabel'] as String? ?? 'Learn More',
      budgetCents: (json['budgetCents'] as num?)?.toInt() ?? 0,
      spentCents: (json['spentCents'] as num?)?.toInt() ?? 0,
      cpmBidCents: (json['cpmBidCents'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      impressionCount: (json['impressionCount'] as num?)?.toInt() ?? 0,
      clickCount: (json['clickCount'] as num?)?.toInt() ?? 0,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class MonetizationProgress {
  final bool isPremium;
  final int verifiedFollowers;
  final int totalFollowers;
  final int totalWatchMinutes;
  final int totalViews;
  final int reqVerifiedFollowers;
  final int reqTotalFollowers;
  final int reqTotalWatchMinutes;
  final int reqTotalViews;
  final bool isEligible;
  final bool isApproved;

  MonetizationProgress({
    required this.isPremium,
    required this.verifiedFollowers,
    required this.totalFollowers,
    required this.totalWatchMinutes,
    required this.totalViews,
    required this.reqVerifiedFollowers,
    required this.reqTotalFollowers,
    required this.reqTotalWatchMinutes,
    required this.reqTotalViews,
    required this.isEligible,
    required this.isApproved,
  });

  factory MonetizationProgress.fromJson(Map<String, dynamic> json) {
    return MonetizationProgress(
      isPremium: json['isPremium'] as bool? ?? false,
      verifiedFollowers: (json['verifiedFollowers'] as num?)?.toInt() ?? 0,
      totalFollowers: (json['totalFollowers'] as num?)?.toInt() ?? 0,
      totalWatchMinutes: (json['totalWatchMinutes'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      reqVerifiedFollowers: (json['reqVerifiedFollowers'] as num?)?.toInt() ?? 500,
      reqTotalFollowers: (json['reqTotalFollowers'] as num?)?.toInt() ?? 2000,
      reqTotalWatchMinutes: (json['reqTotalWatchMinutes'] as num?)?.toInt() ?? 5000000,
      reqTotalViews: (json['reqTotalViews'] as num?)?.toInt() ?? 5000000,
      isEligible: json['isEligible'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
    );
  }
}

class CreatorEarningsLedgerEntry {
  final String id;
  final String creatorId;
  final String type;
  final int amountCents;
  final String referenceId;
  final String description;
  final DateTime createdAt;

  CreatorEarningsLedgerEntry({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.amountCents,
    required this.referenceId,
    required this.description,
    required this.createdAt,
  });

  factory CreatorEarningsLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CreatorEarningsLedgerEntry(
      id: json['id'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      referenceId: json['referenceId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class MonetizationSummary {
  final MonetizationProgress progress;
  final int availableBalanceCents;
  final int lifetimeEarnedCents;
  final int totalWithdrawnCents;
  final double estimatedRpmUsd;
  final List<CreatorEarningsLedgerEntry> ledgerHistory;

  MonetizationSummary({
    required this.progress,
    required this.availableBalanceCents,
    required this.lifetimeEarnedCents,
    required this.totalWithdrawnCents,
    required this.estimatedRpmUsd,
    required this.ledgerHistory,
  });

  factory MonetizationSummary.fromJson(Map<String, dynamic> json) {
    final historyList = (json['ledgerHistory'] as List<dynamic>?)
            ?.map((e) => CreatorEarningsLedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MonetizationSummary(
      progress: json['progress'] != null
          ? MonetizationProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : MonetizationProgress(
              isPremium: false,
              verifiedFollowers: 0,
              totalFollowers: 0,
              totalWatchMinutes: 0,
              totalViews: 0,
              reqVerifiedFollowers: 500,
              reqTotalFollowers: 2000,
              reqTotalWatchMinutes: 5000000,
              reqTotalViews: 5000000,
              isEligible: false,
              isApproved: false,
            ),
      availableBalanceCents: (json['availableBalanceCents'] as num?)?.toInt() ?? 0,
      lifetimeEarnedCents: (json['lifetimeEarnedCents'] as num?)?.toInt() ?? 0,
      totalWithdrawnCents: (json['totalWithdrawnCents'] as num?)?.toInt() ?? 0,
      estimatedRpmUsd: (json['estimatedRpmUsd'] as num?)?.toDouble() ?? 4.50,
      ledgerHistory: historyList,
    );
  }
}
