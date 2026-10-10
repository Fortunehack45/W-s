import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens.dart';

class SearchDiscoveryView extends StatefulWidget {
  const SearchDiscoveryView({super.key});

  @override
  State<SearchDiscoveryView> createState() => _SearchDiscoveryViewState();
}

class _SearchDiscoveryViewState extends State<SearchDiscoveryView> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _trendingHashtags = [
    '#WsViral',
    '#BondingCurveGainz',
    '#DailyStreak100',
    '#NFTCards',
    '#CreatorEconomy',
    '#SolidityDev',
  ];

  final List<Map<String, dynamic>> _trendingPools = [
    {
      'title': 'Autonomous AI Agents on Mobile',
      'creator': 'nerd_eth',
      'wCount': '145.2K W',
      'views': '2.1M',
    },
    {
      'title': 'Lagos Robotics Showcase 🤖',
      'creator': 'htx_singapore',
      'wCount': '98.4K W',
      'views': '1.4M',
    },
    {
      'title': 'Top 5 Web3 Staking Secrets',
      'creator': 'crypto_bro',
      'wCount': '42.0K W',
      'views': '620K',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white38, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search creators, videos, hashtags...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Search', style: TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trending Hashtags
          const Text('Trending Hashtags', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingHashtags.map((tag) {
              return Chip(
                backgroundColor: const Color(0xFF1E1E28),
                side: const BorderSide(color: Color(0xFF2E2E3E)),
                label: Text(tag, style: const TextStyle(color: WsTokens.tiktokCyan, fontWeight: FontWeight.w600, fontSize: 12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Top Surging W's Pools
          const Text('Top Surging Video Pools ⚡', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._trendingPools.map((pool) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161620),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF282838)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222232),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_circle_fill, color: WsTokens.brandGold, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pool['title'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${pool['creator']} • ${pool['views']} views',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: WsTokens.brandGold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      pool['wCount'] as String,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
