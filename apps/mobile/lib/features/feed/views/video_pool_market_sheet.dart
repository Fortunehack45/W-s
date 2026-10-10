import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../../moderation/view_models/moderation_view_model.dart';
import '../models/video_pool_models.dart';
import '../view_models/feed_view_model.dart';

/// Giggles-inspired full Video Momentum Pool & Chat Sheet.
/// Features live bonding curve visualization, instant W backing,
/// top backers carousel, real-time community chat, and related video clips.
class VideoPoolMarketSheet extends ConsumerStatefulWidget {
  const VideoPoolMarketSheet({
    required this.video,
    super.key,
  });

  final VideoFeedItem video;

  @override
  ConsumerState<VideoPoolMarketSheet> createState() => _VideoPoolMarketSheetState();
}

class _VideoPoolMarketSheetState extends ConsumerState<VideoPoolMarketSheet>
    with SingleTickerProviderStateMixin {
  int _selectedStake = 10;
  String _selectedRange = 'LIVE';
  bool _isStaking = false;
  bool _isUnstaking = false;

  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      author: 'whale_investor',
      badge: '👑 #1 Backer',
      text: 'Dropped 100 Ws early! Holding until this pool crosses 50k 🚀',
      timeAgo: '8m ago',
      color: WsTokens.brandGold,
    ),
    _ChatMessage(
      author: 'skate_fanatic',
      badge: '🔥 Top 5 Backer',
      text: 'Insane creative clip. The 2% royalty split is so deserved!',
      timeAgo: '4m ago',
      color: WsTokens.brandEmerald,
    ),
    _ChatMessage(
      author: 'crypto_kai',
      badge: '⚡ Staker',
      text: 'Just backed 25 Ws. Let’s push this pool to the moon!',
      timeAgo: '1m ago',
      color: WsTokens.tiktokCyan,
    ),
  ];

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final modState = ref.read(moderationViewModelProvider);
    if (modState.status?.isRestricted ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Account in Passive Preview Mode: Comments are disabled.'),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          author: 'you',
          badge: '⚡ Backer',
          text: text,
          timeAgo: 'Just now',
          color: WsTokens.brandGold,
        ),
      );
      _chatController.clear();
    });
  }

  Future<void> _handleStake() async {
    final modState = ref.read(moderationViewModelProvider);
    if (modState.status?.isRestricted ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Account in Passive Preview Mode: Staking is disabled.'),
        ),
      );
      return;
    }

    setState(() => _isStaking = true);
    HapticFeedback.mediumImpact();

    await ref
        .read(feedViewModelProvider.notifier)
        .stakeW(widget.video.id, _selectedStake);

    if (mounted) {
      setState(() => _isStaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: WsTokens.brandEmerald,
          content: Row(
            children: [
              const WsGlyph(size: 18, color: Colors.black, hasGlow: false),
              const SizedBox(width: 8),
              Text(
                'Successfully backed $_selectedStake W\'s! ⚡',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleUnstake(int shares) async {
    setState(() => _isUnstaking = true);
    HapticFeedback.lightImpact();

    await ref
        .read(feedViewModelProvider.notifier)
        .unstakeW(widget.video.id, shares);

    if (mounted) {
      setState(() => _isUnstaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: WsTokens.brandGold,
          content: Text('Cashed out active stake back to your W wallet.', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedViewModelProvider);
    final pool = state.selectedPool ??
        VideoWPool(
          videoId: widget.video.id,
          currentWCount: widget.video.wCount,
          reserveBalance: widget.video.wCount,
          totalShares: max(1, (widget.video.wCount * 0.8).toInt()),
          basePriceW: 1,
          creatorRoyaltyBps: 200,
        );
    final position = state.currentPosition;
    final currentPoolW = pool.currentWCount;
    final userShares = position?.sharesOwned ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: WsTokens.surfaceCard,
                  child: Text(
                    widget.video.creatorUsername.isNotEmpty
                        ? widget.video.creatorUsername[0].toUpperCase()
                        : 'W',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${widget.video.creatorUsername}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: WsTokens.brandEmerald,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "W's momentum",
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E1E26), height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // 1. Massive Hero Currency Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const WsGlyph(size: 32, color: WsTokens.brandGold, strokeWidth: 3.2),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat('#,##0.0').format(currentPoolW),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 14, color: WsTokens.brandEmerald),
                    const SizedBox(width: 4),
                    Text(
                      '+118.2% momentum gain since upload',
                      style: const TextStyle(
                        color: WsTokens.brandEmerald,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Interactive Bonding Curve Graph Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF222230)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _BondingCurveChartPainter(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Time Filter Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['LIVE', '1H', '1D', '1W', '1M', 'ALL'].map((range) {
                          final isSel = _selectedRange == range;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedRange = range),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel ? Colors.white.withOpacity(0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (range == 'LIVE') ...[
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: WsTokens.brandEmerald,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    range,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : Colors.white54,
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. User's Position Banner (if shares owned)
                if (userShares > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WsTokens.brandGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR ACTIVE STAKE', style: TextStyle(fontSize: 10, color: WsTokens.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '$userShares Shares (${WsCurrency.format(userShares * pool.pricePerShareW)})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF282835),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: _isUnstaking ? null : () => _handleUnstake(userShares),
                          child: _isUnstaking
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Cash Out ₩', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Quick Stake Selector Chips
                const Text(
                  "Drop W's on this clip:",
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [5, 10, 25, 50, 100].map((amt) {
                    final isSel = _selectedStake == amt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedStake = amt);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isSel ? WsTokens.brandGold : const Color(0xFF161620),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? WsTokens.brandGold : const Color(0xFF252535),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+$amt ₩',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // 5. Big Vibrant Action Button (Giggles style)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WsTokens.brandEmerald,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      shadowColor: WsTokens.brandEmerald.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isStaking ? null : _handleStake,
                    child: _isStaking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const WsGlyph(size: 20, color: Colors.black, hasGlow: false, strokeWidth: 2.8),
                              const SizedBox(width: 8),
                              Text(
                                "Back with $_selectedStake W's",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                // 6. Top Backers Carousel (Image 5 style)
                const Text(
                  'Top Backers & Shareholders',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _BackerAvatarPill(name: 'Kai', amount: '₩59', color: Color(0xFF2979FF)),
                      _BackerAvatarPill(name: 'Pearl', amount: '₩50', color: Color(0xFF2979FF)),
                      _BackerAvatarPill(name: 'Zando', amount: '₩35', color: Color(0xFF2979FF)),
                      _BackerAvatarPill(name: 'Leo', amount: '₩20', color: Color(0xFF2979FF)),
                      _BackerAvatarPill(name: 'Auwai', amount: '₩15', color: Color(0xFF2979FF)),
                      _BackerAvatarPill(name: 'Crypto', amount: '₩3', color: Color(0xFF2979FF)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E1E26)),
                const SizedBox(height: 10),

                // 7. Live Video Backer Chat Stream
                const Text(
                  'Video Backer Room & Chat',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._messages.map((m) => _ChatMessageBubble(message: m)),

                const SizedBox(height: 16),

                // Chat Input Field
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF282835)),
                        ),
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Share a thought with backers...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendChatMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: WsTokens.brandGold, size: 24),
                      onPressed: _sendChatMessage,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 8. "Similar W's" Recommendations Grid
                const Text(
                  "Similar W's Clips",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SimilarVideoCard(
                        title: 'POV: your brain not functioning',
                        wPool: '₩131K',
                        isCurrent: true,
                        gradientColor: Colors.deepPurple.shade900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SimilarVideoCard(
                        title: 'How different cultures laugh',
                        wPool: '₩308',
                        isCurrent: false,
                        gradientColor: Colors.blueGrey.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackerAvatarPill extends StatelessWidget {
  const _BackerAvatarPill({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF222230),
            child: Text(
              name.isNotEmpty ? name[0] : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              amount,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.badge,
    required this.text,
    required this.timeAgo,
    required this.color,
  });

  final String author;
  final String badge;
  final String text;
  final String timeAgo;
  final Color color;
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: message.color.withOpacity(0.2),
            child: Text(
              message.author[0].toUpperCase(),
              style: TextStyle(color: message.color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${message.author}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: message.color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        message.badge,
                        style: TextStyle(color: message.color, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(message.timeAgo, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarVideoCard extends StatelessWidget {
  const _SimilarVideoCard({
    required this.title,
    required this.wPool,
    required this.isCurrent,
    required this.gradientColor,
  });

  final String title;
  final String wPool;
  final bool isCurrent;
  final Color gradientColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: gradientColor,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent ? Border.all(color: WsTokens.brandGold, width: 1.5) : null,
      ),
      child: Stack(
        children: [
          if (isCurrent)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: WsTokens.brandGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'THIS VIDEO',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  wPool,
                  style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the Giggles-inspired neon bonding curve chart.
class _BondingCurveChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw grid horizontal subtle lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E1E28)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), gridPaint);
    canvas.drawLine(Offset(0, h * 0.50), Offset(w, h * 0.50), gridPaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), gridPaint);

    // Curve Path
    final curvePath = Path()
      ..moveTo(0, h * 0.85)
      ..cubicTo(w * 0.15, h * 0.82, w * 0.25, h * 0.50, w * 0.35, h * 0.60)
      ..cubicTo(w * 0.45, h * 0.70, w * 0.55, h * 0.75, w * 0.65, h * 0.55)
      ..cubicTo(w * 0.75, h * 0.68, w * 0.85, h * 0.65, w * 0.90, h * 0.35)
      ..lineTo(w, h * 0.15);

    // Area Fill Gradient
    final fillPath = Path.from(curvePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.35),
          const Color(0xFF2979FF).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Neon Curve Stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(curvePath, strokePaint);

    // Tip indicator node
    final tipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final tipRing = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(w, h * 0.15), 5, tipRing);
    canvas.drawCircle(Offset(w, h * 0.15), 3, tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
