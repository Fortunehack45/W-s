import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../../moderation/views/appeal_modal.dart';
import '../../wallet/view_models/wallet_view_model.dart';
import '../view_models/feed_view_model.dart';
import 'video_pool_market_sheet.dart';

class VideoFeedView extends ConsumerStatefulWidget {
  const VideoFeedView({super.key});

  @override
  ConsumerState<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends ConsumerState<VideoFeedView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedViewModelProvider);
    final videos = state.videos;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full Screen Vertical Video PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) {
              ref.read(feedViewModelProvider.notifier).fetchPoolAndPosition(videos[index].id);
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return _VideoFeedCard(
                video: video,
                onOpenPool: () => _openPoolBottomSheet(context, video),
                onOpenComments: () => _openPoolBottomSheet(context, video),
                onRepost: () => _repostVideo(context, video.id),
                onSave: () => _saveVideo(context, video.id),
                onShare: () => _shareVideo(context, video.id),
              );
            },
          ),

          // Top Header & Passive Restriction Banner
          SafeArea(
            child: Column(
              children: [
                const PassiveRestrictionBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeedTab(label: "Top W's", isSelected: false, onTap: () {}),
                          const SizedBox(width: 16),
                          _FeedTab(label: 'Following', isSelected: false, onTap: () {}),
                          const SizedBox(width: 16),
                          _FeedTab(label: 'For You', isSelected: true, onTap: () {}),
                        ],
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

  void _repostVideo(BuildContext context, String videoId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: WsTokens.brandGold,
        content: Text("Video reposted to your followers' FYP feed! ⚡", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _saveVideo(BuildContext context, String videoId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: WsTokens.brandEmerald,
        content: Text("Saved to your bookmarks! 🔖", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _shareVideo(BuildContext context, String videoId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Video share link copied to clipboard! 🔗"),
      ),
    );
  }

  void _openPoolBottomSheet(BuildContext context, VideoFeedItem video) {
    ref.read(feedViewModelProvider.notifier).fetchPoolAndPosition(video.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoPoolMarketSheet(video: video),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(width: 28, height: 2.5, decoration: BoxDecoration(color: WsTokens.brandGold, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

class _VideoFeedCard extends StatelessWidget {
  const _VideoFeedCard({
    required this.video,
    required this.onOpenPool,
    required this.onOpenComments,
    required this.onRepost,
    required this.onSave,
    required this.onShare,
  });

  final VideoFeedItem video;
  final VoidCallback onOpenPool;
  final VoidCallback onOpenComments;
  final VoidCallback onRepost;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();

    return Stack(
      children: [
        // Video Mock Backdrop
        Container(
          color: Colors.black,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.deepPurple.shade900.withOpacity(0.35),
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.2), size: 72),
              ),
            ),
          ),
        ),

        // Bottom Gradient Overlay for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Floating Frosted-Glass W's Momentum Pill (Clean, Dark OLED aesthetic)
        Positioned(
          left: 16,
          bottom: video.isSponsored ? 190 : 155,
          child: GestureDetector(
            onTap: onOpenPool,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                  const WsGlyph(size: 14, color: WsTokens.brandGold, hasGlow: false),
                  const SizedBox(width: 6),
                  Text(
                    '${numberFormat.format(video.wCount)} W\'s',
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
          ),
        ),

        // Video Creator Info (Username, Title, Description, Sponsored Badge)
        Positioned(
          left: 16,
          bottom: 28,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (video.isSponsored) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: WsTokens.brandGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: WsTokens.brandGold),
                  ),
                  child: const Text(
                    'SPONSORED',
                    style: TextStyle(
                      color: WsTokens.brandGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
              Row(
                children: [
                  Text(
                    '@${video.creatorUsername}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: WsTokens.brandGold, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                video.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                video.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              if (video.isSponsored && video.adCtaUrl != null) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${video.adCtaUrl}...')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: WsTokens.brandGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          video.adCtaLabel ?? 'Learn More',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Right Action Bar (Super Clean Giggles-inspired Layout)
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Creator Avatar with + follow badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: WsTokens.surfaceCard,
                    ),
                    child: Center(
                      child: Text(
                        video.creatorUsername.isNotEmpty ? video.creatorUsername[0].toUpperCase() : 'W',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: WsTokens.tiktokPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Freestanding W's Continuous Tap-To-Drop Action (No circular container!)
              _WsFreestandingAction(
                videoId: video.id,
                initialCount: video.wCount > 0 ? video.wCount : 52000,
              ),
              const SizedBox(height: 16),

              // 3. Comments / Community Chat (Opens VideoPoolMarketSheet)
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: numberFormat.format(video.commentCount > 0 ? video.commentCount : 242),
                onTap: onOpenComments,
              ),
              const SizedBox(height: 16),

              // 4. Repost Button
              _ActionButton(
                icon: Icons.repeat,
                label: numberFormat.format(video.repostCount > 0 ? video.repostCount : 599),
                onTap: onRepost,
              ),
              const SizedBox(height: 16),

              // 5. Bookmark / Save
              _ActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: onSave,
              ),
              const SizedBox(height: 16),

              // 6. Share
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: onShare,
              ),
              const SizedBox(height: 18),

              // 7. Spinning Disc
              _SpinningMusicDisc(initial: video.creatorUsername.isNotEmpty ? video.creatorUsername[0] : 'W'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Freestanding W's Continuous Tap-To-Drop Action (No circular container!)
/// Supports rapid continuous taps and long-press streaming as long as user has W's.
/// Spawns cascading upward floating +1 ₩ badges with spring punch motion.
class _WsFreestandingAction extends ConsumerStatefulWidget {
  const _WsFreestandingAction({
    required this.videoId,
    required this.initialCount,
  });

  final String videoId;
  final int initialCount;

  @override
  ConsumerState<_WsFreestandingAction> createState() => _WsFreestandingActionState();
}

class _WsFreestandingActionState extends ConsumerState<_WsFreestandingAction> with SingleTickerProviderStateMixin {
  late int _count;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final List<_FloatingParticleData> _particles = [];
  int _particleCounter = 0;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _dropSingleW() {
    // 1. Check & debit from user wallet balance
    final success = ref.read(walletViewModelProvider.notifier).spendW(1);
    if (!success) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.bolt, color: WsTokens.brandGold, size: 18),
              SizedBox(width: 8),
              Text(
                "You're out of W's! Top up in your Vault",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1F1F28),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(milliseconds: 1800),
        ),
      );
      return;
    }

    // 2. Increment video momentum live
    HapticFeedback.lightImpact();
    _animController.forward(from: 0.0);
    setState(() {
      _count += 1;
      _particleCounter += 1;
      _particles.add(
        _FloatingParticleData(
          id: _particleCounter,
          dx: (Random().nextDouble() * 28) - 14,
        ),
      );
    });

    // 3. Dispatch to backend/state
    ref.read(feedViewModelProvider.notifier).stakeW(widget.videoId, 1);
  }

  void _startContinuousStream() {
    _dropSingleW();
    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 110), (_) {
      _dropSingleW();
    });
  }

  void _stopContinuousStream() {
    _streamTimer?.cancel();
    _streamTimer = null;
  }

  void _removeParticle(int id) {
    if (mounted) {
      setState(() {
        _particles.removeWhere((p) => p.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();

    return GestureDetector(
      onTap: _dropSingleW,
      onLongPressStart: (_) => _startContinuousStream(),
      onLongPressEnd: (_) => _stopContinuousStream(),
      onLongPressCancel: _stopContinuousStream,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Standalone Freestanding W's Glyph (NO circular container!)
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Floating Upward +1 ₩ Badges Fountain
                for (final p in _particles)
                  _FloatingWBadge(
                    key: ValueKey(p.id),
                    dx: p.dx,
                    onComplete: () => _removeParticle(p.id),
                  ),

                // Pure Freestanding W's Sign with spring punch
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
          // Tabular count with subtle drop shadow for high contrast
          Text(
            numberFormat.format(_count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingParticleData {
  _FloatingParticleData({required this.id, required this.dx});
  final int id;
  final double dx;
}

class _FloatingWBadge extends StatefulWidget {
  const _FloatingWBadge({
    required this.dx,
    required this.onComplete,
    super.key,
  });

  final double dx;
  final VoidCallback onComplete;

  @override
  State<_FloatingWBadge> createState() => _FloatingWBadgeState();
}

class _FloatingWBadgeState extends State<_FloatingWBadge> with SingleTickerProviderStateMixin {
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinningMusicDisc extends StatefulWidget {
  const _SpinningMusicDisc({required this.initial});
  final String initial;

  @override
  State<_SpinningMusicDisc> createState() => _SpinningMusicDiscState();
}

class _SpinningMusicDiscState extends State<_SpinningMusicDisc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E22),
          border: Border.all(color: Colors.white30, width: 2),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: WsTokens.brandGold,
            ),
            child: Center(
              child: Text(
                widget.initial.toUpperCase(),
                style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
