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
      id: 'th-risss',
      otherUsername: 'risss',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      currentStreakDays: 32,
      longestStreakDays: 32,
      lastMessageSnippet: 'Sent 1h ago · Reacted 😂',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    DirectMessageThread(
      id: 'th-pearl',
      otherUsername: 'PEÅRL 💖',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
      currentStreakDays: 12,
      longestStreakDays: 12,
      lastMessageSnippet: 'Are we backing that video tonight? 🔥',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DirectMessageThread(
      id: 'th-keny',
      otherUsername: 'KENY',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      currentStreakDays: 7,
      longestStreakDays: 7,
      lastMessageSnippet: 'Tomorrow we hit our 7-day streak card! ⚡',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    DirectMessageThread(
      id: 'th-adel',
      otherUsername: 'Adel 😊',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
      currentStreakDays: 105,
      longestStreakDays: 105,
      lastMessageSnippet: 'Century Blaze card unlocked! 🏆',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    DirectMessageThread(
      id: 'th-marcus',
      otherUsername: 'marcus_skate',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      currentStreakDays: 14,
      longestStreakDays: 14,
      lastMessageSnippet: 'Did you see that video hit 10k Ws?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    DirectMessageThread(
      id: 'th-zen',
      otherUsername: 'zen_creator',
      otherAvatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      currentStreakDays: 98,
      longestStreakDays: 98,
      lastMessageSnippet: 'Only 2 more days to Century Blaze Epic Card! ⚡',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<Map<String, dynamic>> _stories = [
    {
      'name': 'Create',
      'isUser': true,
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
    },
    {
      'name': "'m",
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      'ringColor': [Colors.purpleAccent, Colors.pinkAccent],
    },
    {
      'name': 'Zandos!',
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'ringColor': [Colors.deepOrangeAccent, Colors.amber],
    },
    {
      'name': 'Cardi B',
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
      'ringColor': [Colors.cyanAccent, Colors.blueAccent],
    },
    {
      'name': 'Kayla',
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
      'ringColor': [Colors.greenAccent, Colors.tealAccent],
    },
    {
      'name': 'Tobi',
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      'ringColor': [WsTokens.brandGold, Colors.orangeAccent],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // User avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Blue plus story badge
              Positioned(
                bottom: 0,
                right: 28,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1877F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 10),
                  ),
                ),
              ),
              // Thought bubble "What's up?"
              Positioned(
                top: -8,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26262E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    "What's up?",
                    style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Inbox',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Stories Horizontal Avatar Carousel (Giggles Image 1 style)
          SliverToBoxAdapter(
            child: Container(
              height: 102,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _stories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  final isUser = story['isUser'] as bool;
                  final name = story['name'] as String;
                  final avatarUrl = story['avatar'] as String;
                  final ringColors = story['ringColor'] as List<Color>? ?? [Colors.transparent, Colors.transparent];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isUser
                                  ? null
                                  : LinearGradient(colors: ringColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(avatarUrl),
                              ),
                            ),
                          ),
                          if (isUser)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1877F2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser ? Colors.white70 : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(color: Color(0xFF1F1F24), height: 1),
          ),

          // 2. Activities Pill (Giggles Image 1 style)
          SliverToBoxAdapter(
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5A623),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.notifications, color: Colors.black, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Activities',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'System updates & video pool milestone alerts',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(color: Color(0xFF1F1F24), height: 1),
          ),

          // 3. Messages Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Requests (2)',
                    style: TextStyle(
                      color: WsTokens.brandGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Message Threads with Flame Streaks & Pinned Status
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final thread = _threads[index];
                final isPinned = index == 0;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _ConversationScreen(thread: thread)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(thread.otherAvatarUrl),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    thread.otherUsername,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Flame Streak Count Badge (Matching Image 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 10)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${thread.currentStreakDays}',
                                          style: const TextStyle(
                                            color: Colors.deepOrangeAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPinned) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.push_pin, color: Colors.white38, size: 14),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                thread.lastMessageSnippet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white38,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _threads.length,
            ),
          ),
        ],
      ),
    );
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
    DirectChatMessage(
      id: '1',
      senderUsername: 'other',
      content: 'Hey! Ready for today’s streak?',
      isMe: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    DirectChatMessage(
      id: '2',
      senderUsername: 'me',
      content: 'Always! Let’s keep this alive. 🔥',
      isMe: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 17, backgroundImage: NetworkImage(widget.thread.otherAvatarUrl)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.thread.otherUsername, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
              children: const [
                Icon(Icons.stars, color: WsTokens.brandGold, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily streak active. Send a message every 24 hours to earn collectible NFT cards!',
                    style: TextStyle(fontSize: 11, color: WsTokens.brandGold),
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
                      color: m.isMe ? WsTokens.brandGold : const Color(0xFF26262E),
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
                            color: m.isMe ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeFormat.format(m.createdAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: m.isMe ? Colors.black54 : Colors.white38,
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
            color: const Color(0xFF141418),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message to keep streak alive...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF222228),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
