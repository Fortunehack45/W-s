import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../../moderation/views/appeal_modal.dart';
import '../view_models/feed_view_model.dart';
import 'comments_sheet.dart';

class VideoFeedView extends ConsumerStatefulWidget {
  const VideoFeedView({super.key});

  @override
  ConsumerState<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends ConsumerState<VideoFeedView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

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
              setState(() => _currentIndex = index);
              ref.read(feedViewModelProvider.notifier).fetchPoolAndPosition(videos[index].id);
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return _VideoFeedCard(
                video: video,
                onOpenPool: () => _openPoolBottomSheet(context, video.id),
                onOpenComments: () => _openComments(context, video.id),
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
                          const SizedBox(width: 14),
                          _FeedTab(label: 'Following', isSelected: false, onTap: () {}),
                          const SizedBox(width: 14),
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

  void _openComments(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(videoId: videoId),
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

  void _openPoolBottomSheet(BuildContext context, String videoId) {
    ref.read(feedViewModelProvider.notifier).fetchPoolAndPosition(videoId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WsTokens.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _VideoPoolBottomSheet(videoId: videoId),
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
                    Colors.deepPurple.shade900.withOpacity(0.4),
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.25), size: 72),
              ),
            ),
          ),
        ),

        // Bottom Gradient Overlay for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Video Info (Creator, Title, Description)
        Positioned(
          left: 16,
          bottom: 30,
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
              const SizedBox(height: 8),
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

        // Right Action Bar
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

              // 2. Like Button
              _ActionButton(
                icon: Icons.favorite,
                iconColor: Colors.white,
                label: numberFormat.format(video.repostCount > 0 ? video.repostCount * 12 : 1420),
                onTap: () {},
              ),
              const SizedBox(height: 14),

              // 3. Comments / Live Chat
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: numberFormat.format(video.commentCount),
                onTap: onOpenComments,
              ),
              const SizedBox(height: 14),

              // 4. Dynamic W's Counter Button (The core momentum indicator)
              GestureDetector(
                onTap: onOpenPool,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: WsTokens.brandGold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: WsTokens.brandGold.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bolt, color: Colors.black, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        '${numberFormat.format(video.wCount)} W',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Bookmark / Save
              _ActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: onSave,
              ),
              const SizedBox(height: 14),

              // 6. Share
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: onShare,
              ),
              const SizedBox(height: 16),

              // 7. Spinning Disc
              _SpinningMusicDisc(initial: video.creatorUsername.isNotEmpty ? video.creatorUsername[0] : 'W'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 30),
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

/// Dynamic W's Momentum Pool Bottom Sheet:
/// Displays the bonding curve price, total W pool (surging or falling),
/// and supports dropping W's or cashing out back to wallet.
class _VideoPoolBottomSheet extends ConsumerStatefulWidget {
  const _VideoPoolBottomSheet({required this.videoId});
  final String videoId;

  @override
  ConsumerState<_VideoPoolBottomSheet> createState() => _VideoPoolBottomSheetState();
}

class _VideoPoolBottomSheetState extends ConsumerState<_VideoPoolBottomSheet> {
  int _stakeInput = 10;
  bool _isCashingOut = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedViewModelProvider);
    final pool = state.selectedPool;
    final position = state.currentPosition;
    final numberFormat = NumberFormat('#,###');

    if (state.isLoading && pool == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: WsTokens.brandGold)),
      );
    }

    final currentW = pool?.currentWCount ?? 0;
    final userShares = position?.sharesOwned ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: WsTokens.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bolt, color: WsTokens.brandGold, size: 26),
                  SizedBox(width: 8),
                  Text(
                    "Video W's Momentum Pool",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WsTokens.brandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WsTokens.brandGold.withOpacity(0.3)),
                ),
                child: Text(
                  '${numberFormat.format(currentW)} W POOL',
                  style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Community members stake Ws to back this video. As backing surges, price rises. When backers cash out, pool size decreases. 2% royalty paid to creator on every trade.',
            style: TextStyle(fontSize: 12, color: WsTokens.textSecondary),
          ),
          const SizedBox(height: 16),

          // User's Position Widget
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WsTokens.surfaceBlack,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WsTokens.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR ACTIVE STAKE', style: TextStyle(fontSize: 11, color: WsTokens.textMuted, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$userShares Shares Owned',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
                    ),
                  ],
                ),
                if (userShares > 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isCashingOut
                        ? null
                        : () async {
                            setState(() => _isCashingOut = true);
                            await ref.read(feedViewModelProvider.notifier).unstakeW(widget.videoId, userShares);
                            if (mounted) setState(() => _isCashingOut = false);
                          },
                    child: _isCashingOut
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Cash Out W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Preset Stake Selector
          const Text("Back this video with W's:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WsTokens.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [5, 10, 25, 50, 100].map((amount) {
              final isSelected = _stakeInput == amount;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () => setState(() => _stakeInput = amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? WsTokens.brandGold : WsTokens.surfaceBlack,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? WsTokens.brandGold : WsTokens.divider),
                      ),
                      child: Center(
                        child: Text(
                          '$amount W',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : WsTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WsTokens.brandEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await ref.read(feedViewModelProvider.notifier).stakeW(widget.videoId, _stakeInput);
                if (mounted) Navigator.pop(context);
              },
              child: Text(
                'Drop $_stakeInput W\'s  ⚡',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
