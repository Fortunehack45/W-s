import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _FriendsVideoCardState extends State<_FriendsVideoCard> with TickerProviderStateMixin {
  late AnimationController _discAnim;
  late AnimationController _punchAnim;
  late Animation<double> _scaleAnimation;
  late int _likes;
  final List<Map<String, dynamic>> _particles = [];
  int _particleId = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.item['likes'] as int? ?? 71;
    _discAnim = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _punchAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _punchAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _discAnim.dispose();
    _punchAnim.dispose();
    super.dispose();
  }

  void _dropW() {
    HapticFeedback.lightImpact();
    _punchAnim.forward(from: 0.0);
    setState(() {
      _likes += 1;
      _particleId += 1;
      _particles.add({
        'id': _particleId,
        'dx': (Random().nextDouble() * 28) - 14,
      });
    });
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
              ),
              // Floating Frosted W's Momentum Pill (Clean Dark OLED)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xCC16161E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WsGlyph(size: 14, color: WsTokens.brandGold, hasGlow: false, hasDropShadow: true),
                    const SizedBox(width: 6),
                    Text(
                      '${numFmt.format(item['wCount'])} W\'s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.white60, size: 16),
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

              // Freestanding W's Continuous Tap-To-Drop Action (No circular container!)
              GestureDetector(
                onTap: _dropW,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          for (final p in _particles)
                            _FriendsFloatingBadge(
                              key: ValueKey(p['id']),
                              dx: p['dx'] as double,
                              onComplete: () {
                                if (mounted) {
                                  setState(() {
                                    _particles.removeWhere((item) => item['id'] == p['id']);
                                  });
                                }
                              },
                            ),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: const WsGlyph(
                              size: 34,
                              color: WsTokens.brandGold,
                              strokeWidth: 2.8,
                              hasGlow: false,
                              hasDropShadow: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      numFmt.format(_likes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Comment
              Column(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    numFmt.format(item['comments']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Save / Bookmark
              Column(
                children: [
                  const Icon(
                    Icons.bookmark_border,
                    color: Colors.white,
                    size: 28,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    numFmt.format(item['saves']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Share
              Column(
                children: [
                  const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 28,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    numFmt.format(item['shares']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
                    ),
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

class _FriendsFloatingBadge extends StatefulWidget {
  const _FriendsFloatingBadge({
    required this.dx,
    required this.onComplete,
    super.key,
  });

  final double dx;
  final VoidCallback onComplete;

  @override
  State<_FriendsFloatingBadge> createState() => _FriendsFloatingBadgeState();
}

class _FriendsFloatingBadgeState extends State<_FriendsFloatingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _translateY = Tween<double>(begin: 0.0, end: -65.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 70),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.dx, _translateY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xDD12121A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WsTokens.brandGold.withOpacity(0.6), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          '+1 ₩',
          style: TextStyle(
            color: WsTokens.brandGold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
