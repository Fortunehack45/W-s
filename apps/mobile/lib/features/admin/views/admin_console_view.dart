import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({super.key});

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for mobile admin view
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'usr-001',
      'username': 'nerd_eth',
      'isVerified': true,
      'isPremium': true,
      'status': 'normal',
      'followers': 89,
      'wEarned': 366000,
    },
    {
      'id': 'usr-002',
      'username': 'spambot99',
      'isVerified': false,
      'isPremium': false,
      'status': 'restricted',
      'followers': 0,
      'wEarned': 0,
    },
    {
      'id': 'usr-003',
      'username': 'sandra_codes',
      'isVerified': true,
      'isPremium': true,
      'status': 'normal',
      'followers': 420,
      'wEarned': 18400,
    },
  ];

  final List<Map<String, dynamic>> _mockComments = [
    {
      'id': 'c-101',
      'author': 'spambot99',
      'content': 'Check out my telegram link for free money!',
      'velocity': 142,
      'isFlagged': true,
    },
    {
      'id': 'c-102',
      'author': 'sandra_codes',
      'content': 'This bonding curve math is super clean 🔥',
      'velocity': 8,
      'isFlagged': false,
    },
  ];

  final List<Map<String, dynamic>> _mockChats = [
    {
      'author': 'top_backer_dan',
      'video': 'vid-robotics-01',
      'badge': 'Top Backer 🥇',
      'msg': 'Staked 10k Ws on this video!',
      'time': '2m ago',
    },
    {
      'author': 'crypto_queen',
      'video': 'vid-crypto-02',
      'badge': 'Backer 🥈',
      'msg': 'Linear curve is rocketing!',
      'time': '5m ago',
    },
  ];

  final List<Map<String, dynamic>> _mockDMs = [
    {
      'thread': 'thread-risss',
      'sender': 'risss',
      'content': 'We hit 32 days streak today! 🔥',
      'time': '4:02 PM',
    },
    {
      'thread': 'thread-pearl',
      'sender': 'PEÅRL 💕',
      'content': 'Let\'s drop W\'s on that video tonight!',
      'time': '4:15 PM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat.compact();

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
          children: const [
            Icon(Icons.admin_panel_settings, color: WsTokens.brandGold, size: 22),
            SizedBox(width: 8),
            Text('Super Admin Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: WsTokens.brandGold,
          labelColor: WsTokens.brandGold,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Comments'),
            Tab(text: 'Video Chats'),
            Tab(text: 'DMs & DNS'),
            Tab(text: 'Appeals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Users Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mockUsers.length,
            itemBuilder: (context, index) {
              final u = _mockUsers[index];
              final isRestr = u['status'] == 'restricted';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF282838)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '@${u['username']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (u['isVerified']) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: WsTokens.brandGold, size: 16),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isRestr ? Colors.red.withOpacity(0.2) : WsTokens.brandEmerald.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isRestr ? Colors.red : WsTokens.brandEmerald, width: 0.8),
                          ),
                          child: Text(
                            isRestr ? 'RESTRICTED (BOT)' : 'NORMAL',
                            style: TextStyle(
                              color: isRestr ? Colors.red : WsTokens.brandEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Followers: ${u['followers']} • Lifetime Earned: ${numFmt.format(u['wEarned'])} W',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRestr ? WsTokens.brandEmerald : Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              u['status'] = isRestr ? 'normal' : 'restricted';
                            });
                          },
                          child: Text(isRestr ? 'Unrestrict' : 'Restrict Bot'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Comments Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mockComments.length,
            itemBuilder: (context, index) {
              final c = _mockComments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF282838)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('@${c['author']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (c['isFlagged'])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: const Text('SPAM BOT FLAG', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c['content'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('Daily Velocity: ${c['velocity']} comments/day', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() => _mockComments.removeAt(index));
                          },
                          child: const Text('Delete Comment', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 3. Video Chats Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mockChats.length,
            itemBuilder: (context, index) {
              final chat = _mockChats[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF282838)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('@${chat['author']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(chat['badge'] as String, style: const TextStyle(color: WsTokens.brandGold, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(chat['msg'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('Video: ${chat['video']} • ${chat['time']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              );
            },
          ),

          // 4. DMs & DNS Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mockDMs.length,
            itemBuilder: (context, index) {
              final dm = _mockDMs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF282838)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sender: @${dm['sender']}', style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold)),
                        Text(dm['time'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(dm['content'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Thread ID: ${dm['thread']}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              );
            },
          ),

          // 5. Appeals Queue Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF282838)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User: @spambot99', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Reason: Automated high-frequency comments (>100/day)', style: TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('"Please unban me, my sister was tapping on the screen. It was not a bot!"', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: WsTokens.brandEmerald, foregroundColor: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appeal approved. Account restored.')));
                        },
                        child: const Text('Approve & Unban'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appeal rejected.')));
                        },
                        child: const Text('Deny'),
                      ),
                    ],
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
