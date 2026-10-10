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
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: WsTokens.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: WsTokens.divider, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.forum, color: WsTokens.brandGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Canonical Video Chat Room',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: WsTokens.textMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: WsTokens.divider),

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
                      backgroundColor: WsTokens.surfaceCard,
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
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
                              ),
                              if (msg.badge.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: msg.badge.contains('Top 1')
                                        ? WsTokens.brandGold.withOpacity(0.2)
                                        : WsTokens.brandEmerald.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: msg.badge.contains('Top 1') ? WsTokens.brandGold : WsTokens.brandEmerald,
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
                              Text(timeFormat.format(msg.createdAt), style: const TextStyle(fontSize: 10, color: WsTokens.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(msg.content, style: const TextStyle(fontSize: 13, color: WsTokens.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Composer
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isRestricted,
                  style: const TextStyle(color: WsTokens.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isRestricted ? 'Chat disabled in preview mode' : 'Chat with backers...',
                    hintStyle: const TextStyle(color: WsTokens.textMuted),
                    filled: true,
                    fillColor: WsTokens.surfaceBlack,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: WsTokens.divider)),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: WsTokens.brandGold),
                onPressed: isRestricted ? null : _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
