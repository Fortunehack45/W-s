import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system/tokens.dart';
import '../core/network/api_client.dart';
import '../features/admin/views/admin_console_view.dart';
import '../features/chat/views/direct_message_chat_view.dart';
import '../features/chat/views/inbox_view.dart';
import '../features/collectibles/views/cards_collection_view.dart';
import '../features/feed/views/friends_feed_view.dart';
import '../features/feed/views/video_feed_view.dart';
import '../features/monetization/view_models/monetization_view_model.dart';
import '../features/monetization/views/campaign_manager_view.dart';
import '../features/monetization/views/creator_monetization_view.dart';
import '../features/monetization/views/premium_subscription_view.dart';
import '../features/predictions/view_models/prediction_view_model.dart';
import '../features/predictions/views/call_it_predictions_view.dart';
import '../features/profiles/views/profile_view.dart';
import '../features/search/views/search_discovery_view.dart';
import '../features/upload/views/create_video_view.dart';
import '../features/wallet/views/wallet_dashboard_view.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithTikTokNavBar(navigationShell: navigationShell);
      },
      branches: [
        // 1. Home / FYP Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const VideoFeedView(),
            ),
          ],
        ),

        // 2. Friends / Community Branch (Screenshot 5)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/friends',
              builder: (context, state) => const FriendsFeedView(),
            ),
          ],
        ),

        // 3. Create / Upload Branch (Screenshot 3)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreateVideoView(),
            ),
          ],
        ),

        // 4. Inbox & DMs Branch (Screenshot 1)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (context, state) => const InboxView(),
            ),
          ],
        ),

        // 5. User Profile Branch (Screenshot 4)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    ),

    // Sub-Routes & Deep Links
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchDiscoveryView(),
    ),
    GoRoute(
      path: '/chat/:threadId',
      builder: (context, state) {
        final threadId = state.pathParameters['threadId'] ?? 'thread-general';
        return DirectMessageChatView(threadId: threadId);
      },
    ),
    GoRoute(
      path: '/studio',
      builder: (context, state) => CreatorMonetizationView(
        viewModel: MonetizationViewModel(apiClient: ApiClient()),
      ),
    ),
    GoRoute(
      path: '/monetization',
      builder: (context, state) => CreatorMonetizationView(
        viewModel: MonetizationViewModel(apiClient: ApiClient()),
      ),
    ),
    GoRoute(
      path: '/ads',
      builder: (context, state) => CampaignManagerView(
        viewModel: MonetizationViewModel(apiClient: ApiClient()),
      ),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const CardsCollectionView(),
    ),
    GoRoute(
      path: '/predictions',
      builder: (context, state) => CallItPredictionsView(
        viewModel: PredictionViewModel(apiClient: ApiClient()),
      ),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletDashboardView(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumSubscriptionView(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminConsoleView(),
    ),
  ],
);

/// TikTok-Style 5-Tab Bottom Navigation Bar (Screenshots 1, 2, 4, 5 inspired)
class ScaffoldWithTikTokNavBar extends StatelessWidget {
  const ScaffoldWithTikTokNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: Colors.black,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Color(0xFF1F1F24), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Home
            _NavTabButton(
              icon: Icons.home_filled,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => _onTap(0),
            ),

            // 2. Friends
            _NavTabButton(
              icon: Icons.people_alt_outlined,
              label: 'Friends',
              isSelected: currentIndex == 1,
              onTap: () => _onTap(1),
            ),

            // 3. Iconic Center (+) Button with TikTok cyan/pink border styling
            GestureDetector(
              onTap: () => _onTap(2),
              child: Container(
                width: 48,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cyan offset shadow
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: WsTokens.tiktokCyan,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // Pink offset shadow
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: WsTokens.tiktokPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // Center White Pill
                    Container(
                      width: 38,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Inbox (with unread badge)
            _NavTabButton(
              icon: Icons.chat_bubble_outline,
              label: 'Inbox',
              isSelected: currentIndex == 3,
              badgeCount: 24,
              onTap: () => _onTap(3),
            ),

            // 5. Profile
            _NavTabButton(
              icon: Icons.person_outline,
              label: 'Profile',
              isSelected: currentIndex == 4,
              onTap: () => _onTap(4),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 24,
              ),
              if (badgeCount != null)
                Positioned(
                  top: -4,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: WsTokens.tiktokPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
