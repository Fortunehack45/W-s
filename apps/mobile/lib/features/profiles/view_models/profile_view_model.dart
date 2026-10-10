import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/profile_model.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.selectedTab = 0,
  });

  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final int selectedTab; // 0: Videos, 1: Backed Pools, 2: Reposts, 3: Saved, 4: Liked

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    int? selectedTab,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel({required this.apiClient}) : super(const ProfileState()) {
    loadCurrentUserProfile();
  }

  final ApiClient apiClient;

  Future<void> loadCurrentUserProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await apiClient.client.get('/users/me/profile');
      final data = res.data as Map<String, dynamic>;
      state = state.copyWith(
        profile: UserProfile.fromJson(data),
        isLoading: false,
      );
    } catch (_) {
      // Mock / fallback profile for standalone dev/demo
      state = state.copyWith(
        profile: UserProfile(
          id: 'usr-creator-001',
          username: 'creator_kai',
          displayName: 'Kai Vance ⚡',
          bio: 'Building the future of vertical video & real-time creator bonding curves. Drop Ws on my clips!',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          isVerified: true,
          netLifetimeWEarned: 84250,
          followerCount: 2450,
          verifiedFollowerCount: 620,
          totalWatchMinutes: 5200000,
          totalViews: 5800000,
          isRestricted: false,
          joinedAt: DateTime(2026, 1, 15),
        ),
        isLoading: false,
      );
    }
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTab: index);
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel(apiClient: ref.watch(apiClientProvider));
});
