import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/network/api_client.dart';
import '../../chat/models/chat_models.dart';
import '../../chat/views/direct_messages_view.dart';
import '../models/auction_models.dart';
import '../view_models/auction_view_model.dart';

class CardsCollectionView extends ConsumerStatefulWidget {
  const CardsCollectionView({super.key});

  @override
  ConsumerState<CardsCollectionView> createState() => _CardsCollectionViewState();
}

class _CardsCollectionViewState extends ConsumerState<CardsCollectionView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuctionViewModel _auctionViewModel;

  final List<StreakRewardCard> _myCards = [
    const StreakRewardCard(
      id: 'c-1',
      name: 'Streak Spark',
      description: 'Awarded for completing a 7-day messaging streak.',
      rarity: CardRarity.common,
      artworkUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
      serialNumber: 1,
      streakMilestoneDays: 7,
    ),
    const StreakRewardCard(
      id: 'c-2',
      name: 'Flame Keeper',
      description: 'Awarded for sustaining a 30-day messaging streak.',
      rarity: CardRarity.rare,
      artworkUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400',
      serialNumber: 14,
      streakMilestoneDays: 30,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _auctionViewModel = AuctionViewModel(apiClient: ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auctionViewModel.fetchActiveAuctions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _auctionViewModel.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color(0xFFA855F7); // Purple
      case 'rare':
        return const Color(0xFF3B82F6); // Blue
      case 'common':
      default:
        return const Color(0xFF10B981); // Emerald
    }
  }

  void _showListCardModal(StreakRewardCard card) {
    final bidController = TextEditingController(text: '30');
    int selectedDurationMinutes = 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WsTokens.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('List ${card.name} for Auction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('#${card.serialNumber.toString().padLeft(4, '0')}', style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'English auction with instant outbid release and 5% platform fee upon settlement.',
                style: TextStyle(fontSize: 12, color: WsTokens.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bidController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Minimum Starting Bid (W's)",
                  suffixText: "W's",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDurationMinutes,
                dropdownColor: WsTokens.surfaceElevated,
                decoration: const InputDecoration(
                  labelText: 'Auction Duration',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 60, child: Text('1 Hour')),
                  DropdownMenuItem(value: 360, child: Text('6 Hours')),
                  DropdownMenuItem(value: 1440, child: Text('24 Hours')),
                  DropdownMenuItem(value: 4320, child: Text('3 Days')),
                ],
                onChanged: (val) {
                  if (val != null) selectedDurationMinutes = val;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WsTokens.brandGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final minBid = int.tryParse(bidController.text) ?? 10;
                    Navigator.pop(ctx);
                    final ok = await _auctionViewModel.createListing(
                      cardInstanceId: card.id,
                      minimumBidW: minBid,
                      durationMinutes: selectedDurationMinutes,
                    );
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card listed in auction marketplace!')),
                      );
                      _tabController.animateTo(1);
                    }
                  },
                  child: const Text('Start Live Auction', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaceBidModal(AuctionListingItem listing) {
    final minNextBid = listing.currentHighestBidW > 0
        ? listing.currentHighestBidW + 5
        : listing.minimumBidW;
    final bidController = TextEditingController(text: minNextBid.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WsTokens.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bid on ${listing.cardName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                'Current Highest Bid: ${listing.currentHighestBidW > 0 ? "${listing.currentHighestBidW} W's" : "None (Starting at ${listing.minimumBidW} W's)"}',
                style: const TextStyle(color: WsTokens.brandGold, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your W balance is reserved in authoritative escrow. If another user outbids you, your W\'s are instantly released back to your available balance.',
                style: TextStyle(fontSize: 12, color: WsTokens.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bidController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Your Bid (Minimum $minNextBid W's)",
                  suffixText: "W's",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WsTokens.brandGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final amount = int.tryParse(bidController.text) ?? minNextBid;
                    if (amount < minNextBid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Bid must be at least $minNextBid W's")),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    final ok = await _auctionViewModel.placeBid(
                      listingId: listing.id,
                      bidAmountW: amount,
                    );
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bid placed successfully with escrow reservation!')),
                      );
                    }
                  },
                  child: const Text('Confirm Escrow Bid', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WsTokens.surfaceBlack,
      appBar: AppBar(
        backgroundColor: WsTokens.surfaceBlack,
        elevation: 0,
        title: const Text('NFT Cards & Marketplace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WsTokens.brandGold,
          labelColor: WsTokens.brandGold,
          unselectedLabelColor: WsTokens.textMuted,
          tabs: const [
            Tab(text: 'My Cards'),
            Tab(text: 'Live Auctions'),
            Tab(text: 'Streaks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: My Cards Collection
          _buildMyCardsTab(),

          // Tab 2: Live Auction Marketplace
          _buildLiveAuctionsTab(),

          // Tab 3: Embedded Direct Messages / Streaks View
          const DirectMessagesView(),
        ],
      ),
    );
  }

  Widget _buildMyCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WsTokens.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WsTokens.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: WsTokens.brandGold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Milestone Streak Cards (NFT)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WsTokens.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Messaging daily mints serial-numbered collectible cards at 7d, 30d, 100d, and 200d. You can list cards for English auction anytime!',
                        style: TextStyle(fontSize: 11, color: WsTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Earned Cards (${_myCards.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemCount: _myCards.length,
            itemBuilder: (context, index) {
              final card = _myCards[index];
              final color = _getRarityColor(card.rarity.name);

              return Container(
                decoration: BoxDecoration(
                  color: WsTokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(
                        card.artworkUrl,
                        height: 125,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  card.rarity.name.toUpperCase(),
                                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '#${card.serialNumber.toString().padLeft(4, '0')}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WsTokens.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(card.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WsTokens.textPrimary)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WsTokens.brandGold,
                                side: const BorderSide(color: WsTokens.brandGold),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _showListCardModal(card),
                              child: const Text('List Auction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAuctionsTab() {
    return ListenableBuilder(
      listenable: _auctionViewModel,
      builder: (context, _) {
        if (_auctionViewModel.isLoading && _auctionViewModel.activeListings.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: WsTokens.brandGold));
        }

        final listings = _auctionViewModel.activeListings;
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel, color: WsTokens.textMuted, size: 48),
                const SizedBox(height: 12),
                const Text('No live card auctions right now.', style: TextStyle(color: WsTokens.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _auctionViewModel.fetchActiveAuctions(),
                  child: const Text('Refresh Listings', style: TextStyle(color: WsTokens.brandGold)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: WsTokens.brandGold,
          onRefresh: () => _auctionViewModel.fetchActiveAuctions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final color = _getRarityColor(listing.cardRarity);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: WsTokens.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          listing.artworkUrl,
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  listing.cardName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: WsTokens.textPrimary),
                                ),
                                Text(
                                  '#${listing.serialNumber.toString().padLeft(4, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: WsTokens.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.currentHighestBidW > 0
                                  ? "High Bid: ${listing.currentHighestBidW} W's (${listing.bidCount} bids)"
                                  : "Starting Bid: ${listing.minimumBidW} W's",
                              style: const TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ends: ${listing.endsAt.toLocal().toString().substring(11, 16)} • Anti-sniping active',
                              style: const TextStyle(color: WsTokens.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WsTokens.brandGold,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.gavel, size: 16),
                                label: const Text('Place Bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _showPlaceBidModal(listing),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
