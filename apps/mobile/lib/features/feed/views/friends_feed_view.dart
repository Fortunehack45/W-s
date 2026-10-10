import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';

class FriendsFeedView extends StatefulWidget {
  const FriendsFeedView({super.key});

  @override
  State<FriendsFeedView> createState() => _FriendsFeedViewState();
}

class _FriendsFeedViewState extends State<FriendsFeedView> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _mockFriendsVideos = [
    {
      'creator': 'sandra_codes',
      'location': 'UNIVERSITY LIBRARY • 36.6 mi',
      'caption': 'Final year engineering sprint #techlife #engineering 🇳🇬',
      'sound': 'Original Audio - sandra_codes',
      'likes': 71,
      'comments': 5,
      'saves': 1,
      'shares': 2,
      'wCount': 4200,
      'streak': 14,
    },
    {
      'creator': 'auwal_alhaj',
      'location': 'LAGOS TECH HUB • 12 mi',
      'caption': 'Deploying our smart contracts to testnet! Who backed the pool? 🚀 #crypto #build',
      'sound': 'Viral Track - STORM II',
      'likes': 342,
      'comments': 48,
      'saves': 19,
      'shares': 15,
      'wCount': 18500,
      'streak': 28,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical Video PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _mockFriendsVideos.length,
            itemBuilder: (context, index) {
              final item = _mockFriendsVideos[index];
              return _FriendsVideoCard(item: item);
            },
          ),

          // Top Header & Stories Bar (Screenshot 5 inspired)
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Story Quick Heads
                      Row(
                        children: [
                          _QuickStoryAvatar(initial: '+', label: '', isAdd: true),
                          const SizedBox(width: 8),
                          _QuickStoryAvatar(initial: 'S', label: '', hasBorder: true),
                          const SizedBox(width: 8),
                          _QuickStoryAvatar(initial: 'A', label: '', hasBorder: true),
                        ],
                      ),
                      const Text(
                        'Friends',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white, size: 26),
                        onPressed: () => context.push('/search'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStoryAvatar extends StatelessWidget {
  const _QuickStoryAvatar({
    required this.initial,
    required this.label,
    this.isAdd = false,
    this.hasBorder = false,
  });

  final String initial;
  final String label;
  final bool isAdd;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasBorder ? Border.all(color: WsTokens.tiktokCyan, width: 2) : null,
        color: WsTokens.surfaceCard,
      ),
      child: Center(
        child: isAdd
            ? const Icon(Icons.add, color: Colors.white, size: 20)
            : Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
      ),
    );
  }
}

class _FriendsVideoCard extends StatefulWidget {
  const _FriendsVideoCard({required this.item});
  final Map<String, dynamic> item;

  @override
  State<_FriendsVideoCard> createState() => _FriendsVideoCardState();
}

class _FriendsVideoCardState extends State<_FriendsVideoCard> with SingleTickerProviderStateMixin {
  late AnimationController _discAnim;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _discAnim = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _discAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final numFmt = NumberFormat.compact();

    return Stack(
      children: [
        // Backdrop
        Container(
          color: Colors.black,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1F1A24),
                  Colors.black,
                ],
                radius: 0.9,
              ),
            ),
            child: Center(
              child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.2), size: 72),
            ),
          ),
        ),

        // Bottom Gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 260,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          bottom: 24,
          right: 84,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location Tag Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      item['location'],
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              // Floating Frosted W's Momentum Pill (Giggles Image 4 style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14141A).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WsTokens.brandGold.withOpacity(0.55), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: WsTokens.brandGold.withOpacity(0.22),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WsGlyph(size: 14, color: WsTokens.brandGold, hasGlow: true),
                    const SizedBox(width: 6),
                    Text(
                      '${numFmt.format(item['wCount'])} W\'s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: WsTokens.brandGold, size: 16),
                  ],
                ),
              ),
              // Handle
              Row(
                children: [
                  Text(
                    '@${item['creator']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: WsTokens.brandFlame.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WsTokens.brandFlame, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: WsTokens.brandFlame, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${item['streak']}d',
                          style: const TextStyle(color: WsTokens.brandFlame, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Caption
              Text(
                item['caption'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 6),

              // Sound ticker
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item['sound'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Right Action Rail (Screenshot 5 inspired)
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: WsTokens.tiktokCyan, width: 2),
                  color: WsTokens.surfaceCard,
                ),
                child: Center(
                  child: Text(
                    (item['creator'] as String)[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // W's Reaction Button (Replaces Heart/Like with signature W's Sign)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isLiked = !_isLiked);
                },
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isLiked ? WsTokens.brandGold.withOpacity(0.22) : Colors.black.withOpacity(0.35),
                        border: Border.all(
                          color: _isLiked ? WsTokens.brandGold : Colors.white24,
                          width: _isLiked ? 1.5 : 1.0,
                        ),
                        boxShadow: _isLiked
                            ? [
                                BoxShadow(
                                  color: WsTokens.brandGold.withOpacity(0.55),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: WsGlyph(
                          size: 24,
                          color: _isLiked ? WsTokens.brandGold : Colors.white,
                          hasGlow: _isLiked,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      numFmt.format(item['likes'] + (_isLiked ? 1 : 0)),
                      style: TextStyle(
                        color: _isLiked ? WsTokens.brandGold : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Comment
              Column(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    numFmt.format(item['comments']),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Save / Bookmark
              Column(
                children: [
                  const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    numFmt.format(item['saves']),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Share
              Column(
                children: [
                  const Icon(Icons.share_outlined, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    numFmt.format(item['shares']),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Spinning Disc
              RotationTransition(
                turns: _discAnim,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E1E),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: WsTokens.brandGold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
