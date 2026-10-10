import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens.dart';

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white, size: 24),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Inbox',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white60,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 26),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 1. Stories / Streak Quick Heads Bar (Screenshot 1 inspired)
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // "Create" with thought bubble
                _StoryBubbleItem(
                  label: 'Create',
                  initial: '👤',
                  isCreate: true,
                  thoughtBubble: "What's up?",
                  onTap: () => context.push('/create'),
                ),
                const SizedBox(width: 14),
                _StoryBubbleItem(
                  label: "'m",
                  initial: 'M',
                  hasBlueRing: true,
                  onTap: () => context.push('/chat/thread-1'),
                ),
                const SizedBox(width: 14),
                _StoryBubbleItem(
                  label: 'Zandos!',
                  initial: 'Z',
                  hasBlueRing: true,
                  streakDays: 14,
                  onTap: () => context.push('/chat/thread-2'),
                ),
                const SizedBox(width: 14),
                _StoryBubbleItem(
                  label: 'Cardi B',
                  initial: 'C',
                  hasBlueRing: true,
                  streakDays: 45,
                  onTap: () => context.push('/chat/thread-3'),
                ),
              ],
            ),
          ),
          const Divider(color: WsTokens.divider, height: 1),

          // 2. Activity & Notifications Section (Screenshot 1 inspired)
          _ActivityRowItem(
            iconData: Icons.person_add,
            iconBgColor: const Color(0xFF1976D2),
            title: 'Blockchain Bullhorn started following you',
            subtitle: 'Tap to see their profile',
            badgeCount: 1,
            badgeColor: WsTokens.tiktokPink,
            onTap: () {},
          ),
          _ActivityRowItem(
            iconData: Icons.bolt,
            iconBgColor: WsTokens.tiktokPink,
            title: 'Activity & new followers',
            subtitle: 'Auwal Alhaji, Danielle B. and 4 others...',
            badgeCount: 6,
            badgeColor: WsTokens.tiktokPink,
            onTap: () {},
          ),
          const Divider(color: WsTokens.divider, height: 1, indent: 64),

          // 3. Direct Messages List (DMs with streaks)
          _DirectMessageRow(
            avatarInitial: 'R',
            username: 'risss',
            streakCount: 32,
            isPinned: true,
            lastMessage: 'Reacted ❤️ to your message',
            timestamp: '4h',
            onTap: () => context.push('/chat/thread-risss'),
          ),
          _DirectMessageRow(
            avatarInitial: 'P',
            username: 'PEÅRL 💕',
            streakCount: 12,
            lastMessage: 'Let\'s drop W\'s on that video tonight!',
            timestamp: '1m ago',
            onTap: () => context.push('/chat/thread-pearl'),
          ),
          _DirectMessageRow(
            avatarInitial: 'K',
            username: 'KENY',
            streakCount: 7,
            lastMessage: 'shared a video',
            timestamp: '3h',
            onTap: () => context.push('/chat/thread-keny'),
          ),

          // System Notification Row
          _ActivityRowItem(
            iconData: Icons.timer,
            iconBgColor: const Color(0xFF0D47A1),
            title: 'System notifications',
            subtitle: 'Screen time: You spent 5h 42m on W\'s today',
            hasDotBadge: true,
            onTap: () {},
          ),

          _DirectMessageRow(
            avatarInitial: 'A',
            username: 'Adel 😊',
            streakCount: 105,
            lastMessage: 'shared a video',
            timestamp: '2d',
            unreadCount: 15,
            onTap: () => context.push('/chat/thread-adel'),
          ),
          _DirectMessageRow(
            avatarInitial: '-',
            username: 'crypto_bro',
            lastMessage: 'Liked a post you shared',
            timestamp: '3d',
            onTap: () => context.push('/chat/thread-bro'),
          ),
        ],
      ),
    );
  }
}

class _StoryBubbleItem extends StatelessWidget {
  const _StoryBubbleItem({
    required this.label,
    required this.initial,
    this.isCreate = false,
    this.hasBlueRing = false,
    this.streakDays,
    this.thoughtBubble,
    required this.onTap,
  });

  final String label;
  final String initial;
  final bool isCreate;
  final bool hasBlueRing;
  final int? streakDays;
  final String? thoughtBubble;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Bubble ring
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasBlueRing ? Border.all(color: WsTokens.tiktokCyan, width: 2.5) : null,
                  color: const Color(0xFF24242A),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Plus button if Create
              if (isCreate)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: WsTokens.tiktokCyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 16),
                  ),
                ),

              // Thought bubble overlay if present
              if (thoughtBubble != null)
                Positioned(
                  top: -12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      thoughtBubble!,
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActivityRowItem extends StatelessWidget {
  const _ActivityRowItem({
    required this.iconData,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.badgeCount,
    this.badgeColor,
    this.hasDotBadge = false,
    required this.onTap,
  });

  final IconData iconData;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final int? badgeCount;
  final Color? badgeColor;
  final bool hasDotBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: badgeCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? WsTokens.tiktokPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : (hasDotBadge
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: WsTokens.tiktokPink,
                    shape: BoxShape.circle,
                  ),
                )
              : null),
    );
  }
}

class _DirectMessageRow extends StatelessWidget {
  const _DirectMessageRow({
    required this.avatarInitial,
    required this.username,
    this.streakCount,
    this.isPinned = false,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount,
    required this.onTap,
  });

  final String avatarInitial;
  final String username;
  final int? streakCount;
  final bool isPinned;
  final String lastMessage;
  final String timestamp;
  final int? unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A36),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            avatarInitial,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            username,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (streakCount != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.local_fire_department, color: WsTokens.brandFlame, size: 16),
            Text(
              '$streakCount',
              style: const TextStyle(color: WsTokens.brandFlame, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
          if (isPinned) ...[
            const SizedBox(width: 4),
            const Icon(Icons.push_pin, color: Colors.white38, size: 14),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '• $timestamp',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      trailing: unreadCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: WsTokens.tiktokPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
