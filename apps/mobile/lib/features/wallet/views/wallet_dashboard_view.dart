import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens.dart';
import '../view_models/wallet_view_model.dart';

class WalletDashboardView extends ConsumerWidget {
  const WalletDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletViewModelProvider);

    return Scaffold(
      backgroundColor: WColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "W's Vault",
          style: TextStyle(fontWeight: FontWeight.bold, color: WColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: WColors.textSecondary),
            onPressed: () => ref.read(walletViewModelProvider.notifier).loadWallet(),
          ),
        ],
      ),
      body: state.isLoading && state.summary == null
          ? const Center(child: CircularProgressIndicator(color: WColors.brandPrimary))
          : RefreshIndicator(
              color: WColors.brandPrimary,
              onRefresh: () => ref.read(walletViewModelProvider.notifier).loadWallet(),
              child: ListView(
                padding: const EdgeInsets.all(WSpacing.md),
                children: [
                  // Primary Balance Card
                  Container(
                    padding: const EdgeInsets.all(WSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF28140E), Color(0xFF14141E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(WRadius.lg),
                      border: Border.all(color: WColors.brandPrimary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "AVAILABLE BALANCE",
                          style: TextStyle(
                            color: WColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: WSpacing.sm),
                        Row(
                          children: [
                            Text(
                              "${state.summary?.availableW ?? 0}",
                              style: const TextStyle(
                                color: WColors.textPrimary,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: WSpacing.xs),
                            const Text(
                              "W's",
                              style: TextStyle(
                                color: WColors.brandPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSubStat(
                              "Reserved",
                              "${state.summary?.reservedW ?? 0} W's",
                            ),
                            _buildSubStat(
                              "Earned P&L",
                              "${state.summary?.earnedWBalance ?? 0} W's",
                              highlightColor: WColors.success,
                            ),
                            _buildSubStat(
                              "Purchased",
                              "${state.summary?.purchasedWBalance ?? 0} W's",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: WSpacing.lg),

                  // Transaction History Header
                  const Text(
                    "Recent Ledger Activity",
                    style: TextStyle(
                      color: WColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: WSpacing.sm),

                  if (state.ledger.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: WSpacing.xl),
                      child: Center(
                        child: Text(
                          "No transactions recorded yet.",
                          style: TextStyle(color: WColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...state.ledger.map((item) {
                      final isCredit = item.pointAmount > 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: WSpacing.sm),
                        padding: const EdgeInsets.all(WSpacing.md),
                        decoration: BoxDecoration(
                          color: WColors.surface,
                          borderRadius: BorderRadius.circular(WRadius.md),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(WSpacing.sm),
                              decoration: BoxDecoration(
                                color: isCredit
                                    ? WColors.success.withOpacity(0.1)
                                    : WColors.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isCredit ? WColors.success : WColors.error,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: WSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.eventType.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(
                                      color: WColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(item.createdAt),
                                    style: const TextStyle(
                                      color: WColors.textTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isCredit ? '+' : ''}${item.pointAmount} W's",
                              style: TextStyle(
                                color: isCredit ? WColors.success : WColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildSubStat(String label, String value, {Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: WColors.textTertiary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? WColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
