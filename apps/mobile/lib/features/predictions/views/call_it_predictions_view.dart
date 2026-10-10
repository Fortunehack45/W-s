import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';
import '../models/prediction_models.dart';
import '../view_models/prediction_view_model.dart';

class CallItPredictionsView extends StatefulWidget {
  final PredictionViewModel viewModel;

  const CallItPredictionsView({super.key, required this.viewModel});

  @override
  State<CallItPredictionsView> createState() => _CallItPredictionsViewState();
}

class _CallItPredictionsViewState extends State<CallItPredictionsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.fetchMarkets();
      widget.viewModel.fetchMyPredictions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPlacePredictionModal(PredictionMarketItem market) {
    if (market.options.isEmpty) return;
    String selectedOptionId = market.options.first.id;
    final pointsController = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.neonGold, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          market.title,
                          style: AppTypography.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Select Outcome:', style: AppTypography.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  ...market.options.map((opt) {
                    final isSelected = opt.id == selectedOptionId;
                    return InkWell(
                      onTap: () => setModalState(() => selectedOptionId = opt.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.neonGold.withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected ? AppColors.neonGold : AppColors.surfaceBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(opt.label, style: AppTypography.bodyMedium),
                            Text('${opt.totalPoints} pts', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Prediction Points',
                      suffixText: 'Points',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGold,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () async {
                        final pts = int.tryParse(pointsController.text) ?? 50;
                        Navigator.pop(ctx);
                        final ok = await widget.viewModel.placePrediction(
                          marketId: market.id,
                          optionId: selectedOptionId,
                          points: pts,
                        );
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Call It prediction placed! 🎯')),
                          );
                        }
                      },
                      child: const Text('Confirm Call It Prediction', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Call It • Predictions', style: AppTypography.titleLarge),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonGold,
          labelColor: AppColors.neonGold,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(text: 'Live Markets'),
            Tab(text: 'My Predictions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketsTab(),
          _buildMyPredictionsTab(),
        ],
      ),
    );
  }

  Widget _buildMarketsTab() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading && widget.viewModel.markets.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonGold));
        }

        final markets = widget.viewModel.markets;

        return RefreshIndicator(
          color: AppColors.neonGold,
          onRefresh: () => widget.viewModel.fetchMarkets(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Non-monetary disclaimer
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_esports, color: AppColors.neonGold, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Non-monetary community games. Prediction points are virtual entertainment rewards and cannot be exchanged for cash.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (markets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text('No open prediction markets right now.', style: AppTypography.bodySmall),
                    ),
                  )
                else
                  ...markets.map((m) => _buildMarketCard(m)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketCard(PredictionMarketItem market) {
    final totalPool = market.totalPoolPoints > 0 ? market.totalPoolPoints : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  market.category.toUpperCase(),
                  style: const TextStyle(color: AppColors.neonGold, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Pool: ${market.totalPoolPoints} pts',
                style: const TextStyle(color: AppColors.emeraldSuccess, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(market.title, style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(market.description, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),

          // Options breakdown
          ...market.options.map((opt) {
            final double pct = (opt.totalPoints / totalPool).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(opt.label, style: AppTypography.bodySmall),
                      Text('${(pct * 100).toStringAsFixed(0)}% (${opt.totalPoints} pts)', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceBorder,
                      color: AppColors.neonGold,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGold,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text('Call It Now', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showPlacePredictionModal(market),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPredictionsTab() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final list = widget.viewModel.myPredictions;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.textTertiary, size: 48),
                const SizedBox(height: 12),
                Text('You haven\'t made any predictions yet.', style: AppTypography.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            final isWon = p.status == 'won';

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stake: ${p.points} Points', style: AppTypography.titleSmall),
                      const SizedBox(height: 2),
                      Text('Status: ${p.status.toUpperCase()}', style: AppTypography.bodySmall),
                    ],
                  ),
                  if (isWon)
                    Text(
                      '+${p.payoutWon} pts',
                      style: const TextStyle(color: AppColors.emeraldSuccess, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  else
                    Text(
                      '${p.points} pts',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
