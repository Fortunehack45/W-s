/// Chat, Direct Messaging, Streaks, and Collectible Cards models.

class CanonicalChatMessage {
  const CanonicalChatMessage({
    required this.id,
    required this.authorUsername,
    required this.content,
    required this.badge,
    required this.createdAt,
  });

  final String id;
  final String authorUsername;
  final String content;
  final String badge; // "⚡ Top 1 Backer", "🔥 Top 5 Backer", "Backer", or empty
  final DateTime createdAt;

  factory CanonicalChatMessage.fromJson(Map<String, dynamic> json) {
    return CanonicalChatMessage(
      id: json['id'] as String? ?? '',
      authorUsername: json['authorUsername'] as String? ?? '',
      content: json['content'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DirectMessageThread {
  const DirectMessageThread({
    required this.id,
    required this.otherUsername,
    required this.otherAvatarUrl,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastMessageSnippet,
    required this.lastMessageAt,
  });

  final String id;
  final String otherUsername;
  final String otherAvatarUrl;
  final int currentStreakDays;
  final int longestStreakDays;
  final String lastMessageSnippet;
  final DateTime lastMessageAt;

  factory DirectMessageThread.fromJson(Map<String, dynamic> json) {
    return DirectMessageThread(
      id: json['id'] as String? ?? '',
      otherUsername: json['otherUsername'] as String? ?? '',
      otherAvatarUrl: json['otherAvatarUrl'] as String? ?? '',
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      longestStreakDays: json['longestStreakDays'] as int? ?? 0,
      lastMessageSnippet: json['lastMessageSnippet'] as String? ?? '',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DirectChatMessage {
  const DirectChatMessage({
    required this.id,
    required this.senderUsername,
    required this.content,
    required this.isMe,
    required this.createdAt,
  });

  final String id;
  final String senderUsername;
  final String content;
  final bool isMe;
  final DateTime createdAt;
}

enum CardRarity { common, rare, epic, legendary }

class StreakRewardCard {
  const StreakRewardCard({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.artworkUrl,
    required this.serialNumber,
    required this.streakMilestoneDays,
  });

  final String id;
  final String name;
  final String description;
  final CardRarity rarity;
  final String artworkUrl;
  final int serialNumber;
  final int streakMilestoneDays;

  factory StreakRewardCard.fromJson(Map<String, dynamic> json) {
    final def = json['definition'] as Map<String, dynamic>? ?? {};
    final rStr = def['rarity'] as String? ?? 'common';
    CardRarity r;
    switch (rStr) {
      case 'legendary':
        r = CardRarity.legendary;
        break;
      case 'epic':
        r = CardRarity.epic;
        break;
      case 'rare':
        r = CardRarity.rare;
        break;
      default:
        r = CardRarity.common;
    }

    return StreakRewardCard(
      id: json['id'] as String? ?? '',
      name: def['name'] as String? ?? '',
      description: def['description'] as String? ?? '',
      rarity: r,
      artworkUrl: def['artworkUrl'] as String? ?? '',
      serialNumber: json['serialNumber'] as int? ?? 1,
      streakMilestoneDays: 7,
    );
  }
}
