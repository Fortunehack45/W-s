import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens.dart';

class DirectMessageChatView extends StatefulWidget {
  const DirectMessageChatView({
    required this.threadId,
    this.recipientUsername = 'risss',
    this.initialStreakDays = 32,
    super.key,
  });

  final String threadId;
  final String recipientUsername;
  final int initialStreakDays;

  @override
  State<DirectMessageChatView> createState() => _DirectMessageChatViewState();
}

class _DirectMessageChatViewState extends State<DirectMessageChatView> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': 'Yo! Did you see the new video trending on the FYP with 500k Ws pool?',
      'time': '3:45 PM',
    },
    {
      'isMe': true,
      'text': 'Yeah! I staked 250 Ws on it when it was at 10 Ws. Cashed out 120 Ws profit already 🔥',
      'time': '3:47 PM',
    },
    {
      'isMe': false,
      'text': 'Insane gains!! Also we just hit 32 days streak today! 🚀',
      'time': '4:02 PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: WsTokens.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A38),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.recipientUsername[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '@${widget.recipientUsername}',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: WsTokens.brandGold, size: 14),
                  ],
                ),
                Text(
                  'Active now',
                  style: const TextStyle(color: Colors.emerald, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Active Streak Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: WsTokens.brandFlame.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WsTokens.brandFlame, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: WsTokens.brandFlame, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${widget.initialStreakDays} Days',
                  style: const TextStyle(color: WsTokens.brandFlame, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily Streak Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF181822),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: WsTokens.brandFlame, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day ${widget.initialStreakDays} Streak Active! 🔥',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text(
                        '18h 12m remaining today to message and keep streak alive.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WsTokens.brandGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WsTokens.brandGold, width: 0.8),
                  ),
                  child: const Text(
                    'Card #0032',
                    style: TextStyle(color: WsTokens.brandGold, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Message Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? WsTokens.brandGold : const Color(0xFF262632),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['text'] as String,
                          style: TextStyle(
                            color: isMe ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['time'] as String,
                          style: TextStyle(
                            color: isMe ? Colors.black54 : Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Composer Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: WsTokens.surfaceDark,
                border: Border(top: BorderSide(color: WsTokens.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22222E),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Send a message...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: WsTokens.brandGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_upward, color: Colors.black, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'time': 'Just now',
      });
      _msgController.clear();
    });
  }
}
