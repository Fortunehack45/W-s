/// Domain model for user profiles on the W's platform.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.isVerified,
    required this.netLifetimeWEarned,
    required this.followerCount,
    required this.verifiedFollowerCount,
    required this.totalWatchMinutes,
    required this.totalViews,
    required this.isRestricted,
    required this.joinedAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final bool isVerified;
  /// Replaces likes: Net Lifetime W's Earned (including royalties and staking gains minus losses)
  final int netLifetimeWEarned;
  final int followerCount;
  final int verifiedFollowerCount;
  final int totalWatchMinutes;
  final int totalViews;
  final bool isRestricted;
  final DateTime joinedAt;

  /// Gate: Premium + 500 Verified Followers + 2,000 Total Followers + 5M Watch Minutes + 5M Views
  bool get isMonetizationEligible {
    return isVerified &&
        verifiedFollowerCount >= 500 &&
        followerCount >= 2000 &&
        totalWatchMinutes >= 5000000 &&
        totalViews >= 5000000;
  }

  double get monetizationProgress {
    final vFollowersScore = (verifiedFollowerCount / 500).clamp(0.0, 1.0);
    final followersScore = (followerCount / 2000).clamp(0.0, 1.0);
    final minutesScore = (totalWatchMinutes / 5000000).clamp(0.0, 1.0);
    final viewsScore = (totalViews / 5000000).clamp(0.0, 1.0);
    final verifiedScore = isVerified ? 1.0 : 0.0;
    return (vFollowersScore + followersScore + minutesScore + viewsScore + verifiedScore) / 5.0;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      netLifetimeWEarned: json['netLifetimeWEarned'] as int? ?? 0,
      followerCount: json['followerCount'] as int? ?? 0,
      verifiedFollowerCount: json['verifiedFollowerCount'] as int? ?? 0,
      totalWatchMinutes: json['totalWatchMinutes'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      isRestricted: json['isRestricted'] as bool? ?? false,
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
