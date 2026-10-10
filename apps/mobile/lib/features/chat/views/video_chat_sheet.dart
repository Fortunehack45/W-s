import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../../moderation/view_models/moderation_view_model.dart';
import '../models/chat_models.dart';

class VideoChatSheet extends ConsumerStatefulWidget {
  const VideoChatSheet({required this.videoId, super.key});
  final String videoId;

  @override
  ConsumerState<VideoChatSheet> createState() => _VideoChatSheetState();
}

class _VideoChatSheetState extends ConsumerState<VideoChatSheet> {
  final _controller = TextEditingController();
  final List<CanonicalChatMessage> _messages = [
    CanonicalChatMessage(
      id: 'm-1',
      authorUsername: 'whale_investor',
      content: 'Bought 100 Ws early! Holding until this video hits 50k Ws 🚀',
      badge: '⚡ Top 1 Backer',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    CanonicalChatMessage(
      id: 'm-2',
      authorUsername: 'skate_fanatic',
      content: 'Cleanest tre flip ever posted on this app. Creator deserves the royalties!',
      badge: '🔥 Top 5 Backer',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    CanonicalChatMessage(
      id: 'm-3',
      authorUsername: 'crypto_kai',
      content: 'Just put in 5 Ws. Let’s push this pool higher!',
      badge: 'Backer',
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        CanonicalChatMessage(
          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
          authorUsername: 'you',
          content: text,
          badge: 'Backer',
          createdAt: DateTime.now(),
        ),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modState = ref.watch(moderationViewModelProvider);
    final isRestricted = modState.status?.isRestricted ?? false;
    final timeFormat = DateFormat('h:mm a');

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121218),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: WsTokens.brandGold, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Video Discussion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: WsTokens.brandEmerald.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, color: WsTokens.brandEmerald, size: 6),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(color: WsTokens.brandEmerald, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),

          // Live Chat Messages List
          Expanded(
            child: ListView.separated(
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E1E28),
                      child: Text(
                        msg.authorUsername[0].toUpperCase(),
                        style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '@${msg.authorUsername}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (msg.badge.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: msg.badge.contains('Top 1')
                                        ? WsTokens.brandGold.withOpacity(0.15)
                                        : WsTokens.brandEmerald.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: msg.badge.contains('Top 1')
                                          ? WsTokens.brandGold.withOpacity(0.5)
                                          : WsTokens.brandEmerald.withOpacity(0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    msg.badge,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: msg.badge.contains('Top 1') ? WsTokens.brandGold : WsTokens.brandEmerald,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(timeFormat.format(msg.createdAt), style: const TextStyle(fontSize: 10, color: Colors.white38)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(msg.content, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !isRestricted,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isRestricted ? 'Chat disabled in preview mode' : 'Add to discussion...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: isRestricted ? null : _sendMessage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: WsTokens.brandGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
