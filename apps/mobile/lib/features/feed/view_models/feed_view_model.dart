import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../wallet/view_models/wallet_view_model.dart';
import '../models/video_pool_models.dart';

class VideoFeedItem {
  const VideoFeedItem({
    required this.id,
    required this.creatorUsername,
    required this.title,
    required this.description,
    required this.wCount,
    required this.repostCount,
    required this.commentCount,
    this.isSponsored = false,
    this.adHeadline,
    this.adCtaUrl,
    this.adCtaLabel,
  });

  final String id;
  final String creatorUsername;
  final String title;
  final String description;
  final int wCount;
  final int repostCount;
  final int commentCount;
  final bool isSponsored;
  final String? adHeadline;
  final String? adCtaUrl;
  final String? adCtaLabel;

  VideoFeedItem copyWith({int? wCount}) {
    return VideoFeedItem(
      id: id,
      creatorUsername: creatorUsername,
      title: title,
      description: description,
      wCount: wCount ?? this.wCount,
      repostCount: repostCount,
      commentCount: commentCount,
      isSponsored: isSponsored,
      adHeadline: adHeadline,
      adCtaUrl: adCtaUrl,
      adCtaLabel: adCtaLabel,
    );
  }
}

class FeedState {
  const FeedState({
    this.videos = const [],
    this.selectedPool,
    this.currentPosition,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<VideoFeedItem> videos;
  final VideoWPool? selectedPool;
  final UserPosition? currentPosition;
  final bool isLoading;
  final String? errorMessage;

  FeedState copyWith({
    List<VideoFeedItem>? videos,
    VideoWPool? selectedPool,
    UserPosition? currentPosition,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FeedState(
      videos: videos ?? this.videos,
      selectedPool: selectedPool ?? this.selectedPool,
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FeedViewModel extends StateNotifier<FeedState> {
  FeedViewModel({required this.apiClient, required this.ref}) : super(const FeedState()) {
    _loadSampleFeed();
  }

  final ApiClient apiClient;
  final Ref ref;

  void _loadSampleFeed() {
    state = state.copyWith(videos: [
      const VideoFeedItem(
        id: 'vid-001',
        creatorUsername: 'alex_skater',
        title: 'Kickflip over 8 stairs first try! 🛹',
        description: 'First day back after the injury. Drop Ws if you think this is clean!',
        wCount: 42,
        repostCount: 12,
        commentCount: 88,
      ),
      const VideoFeedItem(
        id: 'vid-002',
        creatorUsername: 'tech_vision',
        title: 'New AI model running local on phone! 🔥',
        description: 'Zero latency text-to-video directly on Android. What do you think?',
        wCount: 1420,
        repostCount: 310,
        commentCount: 520,
      ),
    ]);
  }

  Future<void> fetchPoolAndPosition(String videoId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final poolRes = await apiClient.client.get('/videos/$videoId/w/pool');
      final posRes = await apiClient.client.get('/videos/$videoId/w/position');
      state = state.copyWith(
        selectedPool: VideoWPool.fromJson(poolRes.data as Map<String, dynamic>),
        currentPosition: UserPosition.fromJson(posRes.data as Map<String, dynamic>),
        isLoading: false,
      );
    } catch (_) {
      // In local dev without live network, fallback to simulation
      state = state.copyWith(
        selectedPool: VideoWPool(
          videoId: videoId,
          currentWCount: 42,
          reserveBalance: 42,
          totalShares: 35,
          basePriceW: 1,
          creatorRoyaltyBps: 200,
        ),
        currentPosition: UserPosition(
          videoId: videoId,
          sharesOwned: 5,
          wCostBasis: 5,
          totalWRealizedPnL: 0,
        ),
        isLoading: false,
      );
    }
  }

  Future<void> stakeW(String videoId, int wAmount) async {
    try {
      await apiClient.client.post('/videos/$videoId/w/stake', data: {
        'wAmount': wAmount,
        'minSharesOut': 1,
        'idempotencyKey': 'stake-${DateTime.now().millisecondsSinceEpoch}',
      });
      // Refresh wallet & pool
      ref.read(walletViewModelProvider.notifier).loadWallet();
      await fetchPoolAndPosition(videoId);
      _updateLocalWCount(videoId, wAmount);
    } catch (e) {
      // Optimistic update for UI interaction testing
      _updateLocalWCount(videoId, wAmount);
    }
  }

  Future<void> unstakeW(String videoId, int sharesToBurn) async {
    try {
      await apiClient.client.post('/videos/$videoId/w/unstake', data: {
        'sharesAmount': sharesToBurn,
        'minWOut': 1,
        'idempotencyKey': 'unstake-${DateTime.now().millisecondsSinceEpoch}',
      });
      ref.read(walletViewModelProvider.notifier).loadWallet();
      await fetchPoolAndPosition(videoId);
      _updateLocalWCount(videoId, -sharesToBurn);
    } catch (_) {
      _updateLocalWCount(videoId, -sharesToBurn);
    }
  }

  void _updateLocalWCount(String videoId, int delta) {
    state = state.copyWith(
      videos: state.videos.map((v) {
        if (v.id == videoId) {
          final newCount = (v.wCount + delta) < 0 ? 0 : (v.wCount + delta);
          return v.copyWith(wCount: newCount);
        }
        return v;
      }).toList(),
    );
  }
}

final feedViewModelProvider = StateNotifierProvider<FeedViewModel, FeedState>((ref) {
  return FeedViewModel(
    apiClient: ref.watch(apiClientProvider),
    ref: ref,
  );
});
