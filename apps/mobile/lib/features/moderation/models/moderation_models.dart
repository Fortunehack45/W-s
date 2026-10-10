/// Moderation and account restriction status models.
class AccountRestrictionStatus {
  const AccountRestrictionStatus({
    required this.isRestricted,
    required this.reason,
    required this.restrictedAt,
    required this.isPassivePreviewMode,
    this.appealSubmitted = false,
  });

  final bool isRestricted;
  final String reason;
  final DateTime restrictedAt;
  /// In passive preview mode: user can watch videos and read chat,
  /// but views do not increment video counters and commenting/posting is disabled.
  final bool isPassivePreviewMode;
  final bool appealSubmitted;

  factory AccountRestrictionStatus.fromJson(Map<String, dynamic> json) {
    return AccountRestrictionStatus(
      isRestricted: json['isRestricted'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
      restrictedAt: DateTime.tryParse(json['restrictedAt'] as String? ?? '') ?? DateTime.now(),
      isPassivePreviewMode: json['isPassivePreviewMode'] as bool? ?? false,
      appealSubmitted: json['appealSubmitted'] as bool? ?? false,
    );
  }
}
