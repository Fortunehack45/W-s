import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../../moderation/views/appeal_modal.dart';
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

        // Floating Frosted-Glass W's Momentum Pill (Giggles Image 4 aesthetic)
        Positioned(
          left: 16,
          bottom: video.isSponsored ? 190 : 155,
          child: GestureDetector(
            onTap: onOpenPool,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF14141A).withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: WsTokens.brandGold.withOpacity(0.55), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: WsTokens.brandGold.withOpacity(0.22),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WsGlyph(size: 15, color: WsTokens.brandGold, hasGlow: true),
                  const SizedBox(width: 7),
                  Text(
                    '${numberFormat.format(video.wCount)} W\'s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: WsTokens.brandGold, size: 16),
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

              // 2. Official W's Sign Reaction Button (Replaces Like/Heart with W's Sign)
              _WsReactionButton(
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

/// Official W's Sign Reaction Button:
/// Replaces hearts/likes with the signature W's Sign (WsGlyph),
/// featuring an animated scale bounce, glowing gold radiance, and haptic feedback.
class _WsReactionButton extends StatefulWidget {
  const _WsReactionButton({
    required this.initialCount,
  });

  final int initialCount;

  @override
  State<_WsReactionButton> createState() => _WsReactionButtonState();
}

class _WsReactionButtonState extends State<_WsReactionButton> with SingleTickerProviderStateMixin {
  late bool _isReacted;
  late int _count;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isReacted = false;
    _count = widget.initialCount;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleReaction() {
    HapticFeedback.lightImpact();
    _animController.forward(from: 0.0);
    setState(() {
      _isReacted = !_isReacted;
      if (_isReacted) {
        _count += 1;
      } else {
        _count = max(0, _count - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();

    return GestureDetector(
      onTap: _toggleReaction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isReacted
                    ? WsTokens.brandGold.withOpacity(0.22)
                    : Colors.black.withOpacity(0.35),
                border: Border.all(
                  color: _isReacted ? WsTokens.brandGold : Colors.white24,
                  width: _isReacted ? 1.5 : 1.0,
                ),
                boxShadow: _isReacted
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
                  color: _isReacted ? WsTokens.brandGold : Colors.white,
                  hasGlow: _isReacted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            numberFormat.format(_count),
            style: TextStyle(
              color: _isReacted ? WsTokens.brandGold : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
