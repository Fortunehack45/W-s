import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../view_models/profile_view_model.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _openNavigationDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      "W's Ecosystem & Navigation",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: Icons.monetization_on,
                    iconColor: WsTokens.brandEmerald,
                    title: "Creator Monetization Hub",
                    subtitle: "55% ad revenue share, watch minutes & payout",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/studio');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.campaign,
                    iconColor: WsTokens.brandGold,
                    title: "Ad Campaign Manager",
                    subtitle: "Self-serve in-feed ads & analytics",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/ads');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.style,
                    iconColor: WsTokens.tiktokCyan,
                    title: "Streak Card Marketplace",
                    subtitle: "Buy, sell, and auction rare serial streak cards",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/marketplace');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up,
                    iconColor: WsTokens.tiktokPink,
                    title: "Call It Predictions",
                    subtitle: "Stake W's on video viral milestones",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/predictions');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: WsTokens.brandGold,
                    title: "W's In-App Wallet",
                    subtitle: "Closed-loop balance, bonding stakes & ledger",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/wallet');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium,
                    iconColor: WsTokens.brandGold,
                    title: "W's VIP Premium Pass",
                    subtitle: "Gold verification badge, streak freeze & FYP boost",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/premium');
                    },
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _DrawerItem(
                    icon: Icons.admin_panel_settings,
                    iconColor: Colors.deepOrangeAccent,
                    title: "Super Admin Console",
                    subtitle: "Live activity audit, DMs, chats, comments & anti-bot",
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/admin');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final profile = state.profile;

    if (state.isLoading && profile == null) {
      return const Scaffold(
        backgroundColor: WsTokens.surfaceBlack,
        body: Center(child: CircularProgressIndicator(color: WsTokens.brandGold)),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: WsTokens.surfaceBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load profile', style: TextStyle(color: WsTokens.textMuted)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(profileViewModelProvider.notifier).loadCurrentUserProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final numberFormat = NumberFormat.compact();
    final fullNumberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
          onPressed: () {},
        ),
        title: GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@${profile.username}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
              if (profile.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: WsTokens.brandGold, size: 16),
              ],
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () => _openNavigationDrawer(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Status thought bubble (Natural vertical flow, immune to status bar or AppBar clipping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('⚡ ', style: TextStyle(fontSize: 11)),
                        Text(
                          'Spill the tea on Ws',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Avatar with clean gold ring and story plus badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: WsTokens.brandGold, width: 2.2),
                          image: DecorationImage(
                            image: NetworkImage(profile.avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Cyan/Pink Plus Button for stories
                      Positioned(
                        bottom: 0,
                        right: 2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [WsTokens.tiktokCyan, WsTokens.tiktokPink],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    profile.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),

                  const SizedBox(height: 16),

                  // Following | Followers | Total W's Earned (Screenshot 4 style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatColumn(title: 'Following', value: '248'),
                      const SizedBox(width: 32),
                      _StatColumn(title: 'Followers', value: numberFormat.format(profile.followerCount)),
                      const SizedBox(width: 32),
                      _StatColumn(
                        title: "Total W's Earned",
                        value: '₩ ${fullNumberFormat.format(profile.netLifetimeWEarned)}',
                        isGold: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Row: Edit profile, Share profile (Appllama iOS/Android HIG fidelity)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C1C24),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.white12, width: 0.8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Edit profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C1C24),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.white12, width: 0.8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Share profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // W's Creator Studio Card (Dark OLED with Emerald Split Badge)
                  GestureDetector(
                    onTap: () => context.push('/studio'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14141C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12, width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.video_library_outlined, color: WsTokens.brandGold, size: 20),
                              SizedBox(width: 10),
                              Text(
                                "W's Creator Studio",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: WsTokens.brandEmerald.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: WsTokens.brandEmerald.withOpacity(0.4), width: 0.8),
                                ),
                                child: const Text(
                                  '55% AD SPLIT',
                                  style: TextStyle(
                                    color: WsTokens.brandEmerald,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile 5-Tab Bar (Videos, Backed Pools, Reposts, Saved, Liked)
                  Row(
                    children: [
                      _ProfileTabIcon(
                        icon: Icons.grid_on,
                        isSelected: state.selectedTab == 0,
                        onTap: () => ref.read(profileViewModelProvider.notifier).selectTab(0),
                      ),
                      _ProfileTabIcon(
                        icon: Icons.bolt,
                        isSelected: state.selectedTab == 1,
                        onTap: () => ref.read(profileViewModelProvider.notifier).selectTab(1),
                      ),
                      _ProfileTabIcon(
                        icon: Icons.repeat,
                        isSelected: state.selectedTab == 2,
                        onTap: () => ref.read(profileViewModelProvider.notifier).selectTab(2),
                      ),
                      _ProfileTabIcon(
                        icon: Icons.bookmark_border,
                        isSelected: state.selectedTab == 3,
                        onTap: () => ref.read(profileViewModelProvider.notifier).selectTab(3),
                      ),
                      _ProfileTabIcon(
                        customIcon: WsGlyph(
                          size: 20,
                          color: state.selectedTab == 4 ? Colors.white : Colors.white38,
                          hasGlow: state.selectedTab == 4,
                        ),
                        isSelected: state.selectedTab == 4,
                        onTap: () => ref.read(profileViewModelProvider.notifier).selectTab(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Dynamic Tab Content (Grid of videos or backed pools)
          if (state.selectedTab == 0)
            SliverPadding(
              padding: const EdgeInsets.all(4.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final views = ['126', '1.2M', '34.5K', '580K', '89.2K', '2.4M'][index % 6];
                    final wEarned = ['₩ 1,240', '₩ 42,800', '₩ 3,100', '₩ 19,500', '₩ 8,200', '₩ 95,000'][index % 6];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: const Color(0xFF24242E),
                            child: Center(
                              child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.3), size: 36),
                            ),
                          ),
                          // Top Right W's Badge (Giggles Image 3 style)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: WsTokens.brandGold.withOpacity(0.5)),
                              ),
                              child: Text(
                                wEarned,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: WsTokens.brandGold),
                              ),
                            ),
                          ),
                          // Bottom Left View Count (Giggles Image 3 style)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  views,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: 6,
                ),
              ),
            )
          else if (state.selectedTab == 1)
            // Backed Pools Tab (User's active stakes on bonding curve)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _BackedPoolCard(
                      videoTitle: "Why Vertical AI is Eating Media",
                      creator: "@tech_guru",
                      stakedW: "₩ 2,500",
                      currentValue: "₩ 4,120",
                      gain: "+64.8%",
                    ),
                    const SizedBox(height: 10),
                    _BackedPoolCard(
                      videoTitle: "Night Tokyo Street Food Tour 4K",
                      creator: "@wanderlust_jp",
                      stakedW: "₩ 1,000",
                      currentValue: "₩ 1,450",
                      gain: "+45.0%",
                    ),
                  ],
                ),
              ),
            )
          else if (state.selectedTab == 4)
            // W's Reacted Videos Tab (Replacing Heart likes with W's Sign)
            SliverPadding(
              padding: const EdgeInsets.all(4.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final views = ['240K', '890K', '1.1M', '45.2K'][index % 4];
                    final wEarned = ['₩ 52,000', '₩ 130,965', '₩ 18,400', '₩ 9,500'][index % 4];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: const Color(0xFF24242E),
                            child: Center(
                              child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.3), size: 36),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: WsTokens.brandGold.withOpacity(0.5)),
                              ),
                              child: Text(
                                wEarned,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: WsTokens.brandGold),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  views,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: 4,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: Colors.white.withOpacity(0.2), size: 48),
                      const SizedBox(height: 8),
                      const Text('No items to display yet', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.title,
    required this.value,
    this.isGold = false,
  });

  final String title;
  final String value;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGold) ...[
              const Icon(Icons.bolt, color: WsTokens.brandGold, size: 16),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isGold ? WsTokens.brandGold : Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }
}

class _ProfileTabIcon extends StatelessWidget {
  const _ProfileTabIcon({
    this.icon,
    this.customIcon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: customIcon ??
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : Colors.white38,
                ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
      onTap: onTap,
    );
  }
}

class _BackedPoolCard extends StatelessWidget {
  const _BackedPoolCard({
    required this.videoTitle,
    required this.creator,
    required this.stakedW,
    required this.currentValue,
    required this.gain,
  });

  final String videoTitle;
  final String creator;
  final String stakedW;
  final String currentValue;
  final String gain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(videoTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                const SizedBox(height: 4),
                Text(creator, style: const TextStyle(color: WsTokens.brandGold, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currentValue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(gain, style: const TextStyle(color: WsTokens.brandEmerald, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
