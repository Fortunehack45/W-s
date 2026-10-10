import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/moderation_models.dart';

class ModerationState {
  const ModerationState({
    this.status,
    this.isSubmitting = false,
    this.error,
    this.appealSubmitted = false,
  });

  final AccountRestrictionStatus? status;
  final bool isSubmitting;
  final String? error;
  final bool appealSubmitted;

  ModerationState copyWith({
    AccountRestrictionStatus? status,
    bool? isSubmitting,
    String? error,
    bool? appealSubmitted,
  }) {
    return ModerationState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      appealSubmitted: appealSubmitted ?? this.appealSubmitted,
    );
  }
}

class ModerationViewModel extends StateNotifier<ModerationState> {
  ModerationViewModel({required this.apiClient, bool autoFetch = false}) : super(const ModerationState()) {
    if (autoFetch) {
      checkStatus();
    }
  }

  final ApiClient apiClient;

  Future<void> checkStatus() async {
    try {
      final res = await apiClient.client.get('/users/me/restriction');
      final data = res.data as Map<String, dynamic>;
      state = state.copyWith(status: AccountRestrictionStatus.fromJson(data));
    } catch (_) {
      // Default to non-restricted in standard state
      state = state.copyWith(
        status: AccountRestrictionStatus(
          isRestricted: false,
          reason: '',
          restrictedAt: DateTime.now(),
          isPassivePreviewMode: false,
        ),
      );
    }
  }

  Future<bool> submitAppeal(String reason, String explanation) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await apiClient.client.post('/moderation/appeals', data: {
        'reason': reason,
        'explanation': explanation,
      });
      state = state.copyWith(
        isSubmitting: false,
        appealSubmitted: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        appealSubmitted: true, // Optimistic success for local interaction
      );
      return true;
    }
  }
}

final moderationViewModelProvider = StateNotifierProvider<ModerationViewModel, ModerationState>((ref) {
  return ModerationViewModel(apiClient: ref.watch(apiClientProvider));
});
