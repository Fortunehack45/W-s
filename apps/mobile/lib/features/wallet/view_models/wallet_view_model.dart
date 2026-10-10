import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/wallet_models.dart';


class WalletRepository {
  WalletRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<WalletSummary> fetchSummary() async {
    final response = await apiClient.client.get('/wallet');
    return WalletSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<LedgerItem>> fetchLedger() async {
    final response = await apiClient.client.get('/wallet/ledger');
    final data = response.data as Map<String, dynamic>;
    final list = data['entries'] as List<dynamic>? ?? [];
    return list.map((e) => LedgerItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(apiClient: ref.watch(apiClientProvider));
});

class WalletState {
  const WalletState({
    this.summary,
    this.ledger = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final WalletSummary? summary;
  final List<LedgerItem> ledger;
  final bool isLoading;
  final String? errorMessage;

  WalletState copyWith({
    WalletSummary? summary,
    List<LedgerItem>? ledger,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      summary: summary ?? this.summary,
      ledger: ledger ?? this.ledger,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WalletViewModel extends StateNotifier<WalletState> {
  WalletViewModel({required this.repository}) : super(const WalletState()) {
    loadWallet();
  }

  final WalletRepository repository;

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await repository.fetchSummary();
      final ledger = await repository.fetchLedger();
      state = state.copyWith(
        summary: summary,
        ledger: ledger,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        summary: state.summary ?? const WalletSummary(
          availableW: 2500,
          reservedW: 100,
          earnedWBalance: 600,
          purchasedWBalance: 2000,
        ),
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  bool spendW(int amount) {
    final current = state.summary ?? const WalletSummary(
      availableW: 2500,
      reservedW: 100,
      earnedWBalance: 600,
      purchasedWBalance: 2000,
    );
    if (current.availableW >= amount) {
      state = state.copyWith(
        summary: WalletSummary(
          availableW: current.availableW - amount,
          reservedW: current.reservedW,
          purchasedWBalance: current.purchasedWBalance,
          earnedWBalance: current.earnedWBalance,
        ),
      );
      return true;
    }
    return false;
  }
}

final walletViewModelProvider = StateNotifierProvider<WalletViewModel, WalletState>((ref) {
  return WalletViewModel(repository: ref.watch(walletRepositoryProvider));
});
