import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../../chat/views/video_chat_sheet.dart';
import '../../moderation/view_models/moderation_view_model.dart';
import '../../moderation/views/appeal_modal.dart';

class CommentItem {
  const CommentItem({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
  });

  final String id;
  final String username;
  final String content;
  final DateTime createdAt;
  final int likeCount;
}

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({required this.videoId, super.key});
  final String videoId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _commentController = TextEditingController();
  final List<CommentItem> _comments = [
    CommentItem(
      id: 'c-1',
      username: 'crypto_skater',
      content: 'This trick was insane! Dropped 25 Ws on this clip early 🔥',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      likeCount: 14,
    ),
    CommentItem(
      id: 'c-2',
      username: 'tech_vision',
      content: 'Clean landing. Expecting this video pool to surge past 1k Ws today!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      likeCount: 6,
    ),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(
        0,
        CommentItem(
          id: 'c-${DateTime.now().millisecondsSinceEpoch}',
          username: 'you',
          content: text,
          createdAt: DateTime.now(),
          likeCount: 0,
        ),
      );
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modState = ref.watch(moderationViewModelProvider);
    final isRestricted = modState.status?.isRestricted ?? false;
    final timeFormat = DateFormat('h:mm a');

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: WsTokens.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              Text(
                '${_comments.length} Comments',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: WsTokens.brandGold,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.forum_outlined, size: 16),
                    label: const Text('Chat Room', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => VideoChatSheet(videoId: widget.videoId),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: WsTokens.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: WsTokens.divider),

          // Restricted Notice
          if (isRestricted) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Account in Passive Preview Mode. Commenting is disabled.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: WsTokens.surfaceElevated,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => const AppealBottomSheet(),
                      );
                    },
                    child: const Text('Appeal', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // Comments List
          Expanded(
            child: ListView.separated(
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _comments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: WsTokens.surfaceCard,
                      child: Text(c.username[0].toUpperCase(), style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('@${c.username}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WsTokens.textPrimary)),
                              const SizedBox(width: 8),
                              Text(timeFormat.format(c.createdAt), style: const TextStyle(fontSize: 10, color: WsTokens.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c.content, style: const TextStyle(fontSize: 13, color: WsTokens.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.favorite_border, size: 16, color: WsTokens.textMuted),
                        if (c.likeCount > 0)
                          Text('${c.likeCount}', style: const TextStyle(fontSize: 10, color: WsTokens.textMuted)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Comment Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: !isRestricted,
                  style: const TextStyle(color: WsTokens.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isRestricted ? 'Comments disabled in preview mode' : 'Add a comment...',
                    hintStyle: const TextStyle(color: WsTokens.textMuted),
                    filled: true,
                    fillColor: WsTokens.surfaceBlack,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: WsTokens.divider)),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: WsTokens.brandGold),
                onPressed: isRestricted ? null : _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
