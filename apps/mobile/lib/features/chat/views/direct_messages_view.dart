import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../models/chat_models.dart';

class DirectMessagesView extends ConsumerStatefulWidget {
  const DirectMessagesView({super.key});

  @override
  ConsumerState<DirectMessagesView> createState() => _DirectMessagesViewState();
}

class _DirectMessagesViewState extends ConsumerState<DirectMessagesView> {
  final List<DirectMessageThread> _threads = [
    DirectMessageThread(
      id: 'th-1',
      otherUsername: 'marcus_skate',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      currentStreakDays: 14,
      longestStreakDays: 14,
      lastMessageSnippet: 'Did you see that video hit 10k Ws?',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    DirectMessageThread(
      id: 'th-2',
      otherUsername: 'elena_artist',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      currentStreakDays: 6,
      longestStreakDays: 6,
      lastMessageSnippet: 'Tomorrow we hit our 7-day streak card! 🔥',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DirectMessageThread(
      id: 'th-3',
      otherUsername: 'zen_creator',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      currentStreakDays: 98,
      longestStreakDays: 98,
      lastMessageSnippet: 'Only 2 more days to Century Blaze Epic Card! ⚡',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WsTokens.surfaceBlack,
      appBar: AppBar(
        backgroundColor: WsTokens.surfaceBlack,
        elevation: 0,
        title: const Text('Direct Messages & Streaks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: WsTokens.brandGold),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _threads.length,
        separatorBuilder: (_, __) => const Divider(color: WsTokens.divider, height: 1),
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(thread.otherAvatarUrl),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department, size: 14, color: Colors.deepOrangeAccent),
                ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '@${thread.otherUsername}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: WsTokens.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepOrangeAccent.withOpacity(0.3), Colors.orangeAccent.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 10)),
                      Text(
                        '${thread.currentStreakDays}d',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  thread.lastMessageSnippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: WsTokens.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _getNextMilestoneText(thread.currentStreakDays),
                  style: const TextStyle(fontSize: 11, color: WsTokens.brandGold, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _ConversationScreen(thread: thread)),
              );
            },
          );
        },
      ),
    );
  }

  String _getNextMilestoneText(int current) {
    if (current < 7) {
      return '${7 - current} days to Common Card (Streak Spark)';
    } else if (current < 30) {
      return '${30 - current} days to Rare Card (Flame Keeper)';
    } else if (current < 100) {
      return '${100 - current} days to Epic Card (Century Blaze)';
    } else if (current < 200) {
      return '${200 - current} days to Legendary Card (Immortal Bond)';
    } else {
      return 'Max Milestone Achieved! 🏆';
    }
  }
}

class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen({required this.thread});
  final DirectMessageThread thread;

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _controller = TextEditingController();
  final List<DirectChatMessage> _messages = [
    DirectChatMessage(id: '1', senderUsername: 'other', content: 'Hey! Ready for today’s streak?', isMe: false, createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    DirectChatMessage(id: '2', senderUsername: 'me', content: 'Always! Let’s keep this alive.', isMe: true, createdAt: DateTime.now().subtract(const Duration(minutes: 50))),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        DirectChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderUsername: 'me',
          content: text,
          isMe: true,
          createdAt: DateTime.now(),
        ),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: WsTokens.surfaceBlack,
      appBar: AppBar(
        backgroundColor: WsTokens.surfaceBlack,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.thread.otherAvatarUrl)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${widget.thread.otherUsername}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('🔥 ${widget.thread.currentStreakDays} Days Streak', style: const TextStyle(fontSize: 11, color: Colors.deepOrangeAccent)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Streak Milestone Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.deepOrange.shade900.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.stars, color: WsTokens.brandGold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily streak active. Send a message every 24 hours to earn collectible NFT cards!',
                    style: const TextStyle(fontSize: 11, color: WsTokens.brandGold),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return Align(
                  alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isMe ? WsTokens.brandGold : WsTokens.surfaceCard,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: m.isMe ? const Radius.circular(2) : const Radius.circular(16),
                        bottomLeft: !m.isMe ? const Radius.circular(2) : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.content,
                          style: TextStyle(
                            color: m.isMe ? Colors.black : WsTokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeFormat.format(m.createdAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: m.isMe ? Colors.black54 : WsTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Composer
          Container(
            padding: const EdgeInsets.all(12),
            color: WsTokens.surfaceElevated,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: WsTokens.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message to keep streak alive...',
                        hintStyle: const TextStyle(color: WsTokens.textMuted),
                        filled: true,
                        fillColor: WsTokens.surfaceBlack,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: WsTokens.divider)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: WsTokens.brandGold),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
