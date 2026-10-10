import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';
import '../view_models/monetization_view_model.dart';
import 'campaign_manager_view.dart';

class CreatorMonetizationView extends StatefulWidget {
  final MonetizationViewModel viewModel;

  const CreatorMonetizationView({super.key, required this.viewModel});

  @override
  State<CreatorMonetizationView> createState() => _CreatorMonetizationViewState();
}

class _CreatorMonetizationViewState extends State<CreatorMonetizationView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.fetchSummary();
    });
  }

  void _showPayoutDialog() {
    final amountController = TextEditingController();
    final accountController = TextEditingController();
    String selectedMethod = 'bank_transfer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
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
              Text('Request Cash Payout', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Minimum payout is \$20.00 USD. Funds arrive within 2-3 business days.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Amount (USD)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: accountController,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number / IBAN / PayPal Email',
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
                    final raw = double.tryParse(amountController.text) ?? 0.0;
                    final cents = (raw * 100).toInt();
                    if (cents < 2000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Minimum payout is \$20.00')),
                      );
                      return;
                    }
                    if (accountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter payout destination details')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    final success = await widget.viewModel.requestPayout(
                      amountCents: cents,
                      method: selectedMethod,
                      account: accountController.text.trim(),
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payout request submitted successfully!')),
                      );
                    }
                  },
                  child: const Text('Confirm Cash Payout', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Creator Monetization Hub', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign, color: AppColors.neonGold),
            tooltip: 'Ad Campaign Manager',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampaignManagerView(viewModel: widget.viewModel),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading && widget.viewModel.summary == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.neonGold));
          }

          final summary = widget.viewModel.summary;
          if (summary == null) {
            return Center(
              child: Text('Unable to load monetization data', style: AppTypography.bodyMedium),
            );
          }

          final prog = summary.progress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invariant disclosure banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.neonGold, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Community W\'s cannot be cashed out for fiat money to protect liquidity pools. Creator monetization pays real USD generated from in-app ads and viewer engagement.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                if (prog.isApproved) ...[
                  // Monetized Creator USD Dashboard
                  _buildApprovedCard(summary),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Earnings History', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLedgerList(summary),
                ] else ...[
                  // 5-Point Gate Checklist
                  _buildGateSection(prog),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovedCard(dynamic summary) {
    final availableUsd = (summary.availableBalanceCents / 100.0).toStringAsFixed(2);
    final lifetimeUsd = (summary.lifetimeEarnedCents / 100.0).toStringAsFixed(2);
    final withdrawnUsd = (summary.totalWithdrawnCents / 100.0).toStringAsFixed(2);
    final rpmUsd = summary.estimatedRpmUsd.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.neonGold.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.neonGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Fiat Cash', style: AppTypography.bodySmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSuccess.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.emeraldSuccess),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.emeraldSuccess, size: 14),
                    const SizedBox(width: 4),
                    Text('Monetized', style: TextStyle(color: AppColors.emeraldSuccess, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\$$availableUsd USD',
            style: AppTypography.displayMedium.copyWith(color: AppColors.emeraldSuccess),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol('Lifetime Earned', '\$$lifetimeUsd'),
              _buildStatCol('Withdrawn', '\$$withdrawnUsd'),
              _buildStatCol('Estimated RPM', '\$$rpmUsd'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldSuccess,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Request Cash Payout', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _showPayoutDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGateSection(dynamic prog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monetization Eligibility Gate', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Achieve all 5 criteria to unlock native ad revenue and engagement payouts.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        // 1. Premium Check
        _buildChecklistTile(
          title: 'Premium Membership',
          current: prog.isPremium ? 'Active' : 'Not Subscribed',
          target: 'Required',
          isMet: prog.isPremium,
          actionButton: !prog.isPremium
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    final ok = await widget.viewModel.buyPremium();
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upgraded to Premium!')),
                      );
                    }
                  },
                  child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              : null,
        ),

        // 2. Verified Followers (>= 500)
        _buildProgressTile(
          title: 'Verified Followers',
          current: prog.verifiedFollowers,
          target: prog.reqVerifiedFollowers,
          icon: Icons.verified_user,
        ),

        // 3. Total Followers (>= 2,000)
        _buildProgressTile(
          title: 'Total Followers',
          current: prog.totalFollowers,
          target: prog.reqTotalFollowers,
          icon: Icons.people,
        ),

        // 4. Watch Minutes (>= 5,000,000)
        _buildProgressTile(
          title: 'Watch Minutes',
          current: prog.totalWatchMinutes,
          target: prog.reqTotalWatchMinutes,
          icon: Icons.timer,
          isFormatted: true,
        ),

        // 5. Total Views (>= 5,000,000)
        _buildProgressTile(
          title: 'Total Views',
          current: prog.totalViews,
          target: prog.reqTotalViews,
          icon: Icons.play_circle_outline,
          isFormatted: true,
        ),

        const SizedBox(height: AppSpacing.lg),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: prog.isEligible ? AppColors.neonGold : AppColors.surface,
              foregroundColor: prog.isEligible ? AppColors.background : AppColors.textTertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(
                  color: prog.isEligible ? AppColors.neonGold : AppColors.surfaceBorder,
                ),
              ),
            ),
            onPressed: prog.isEligible
                ? () async {
                    final ok = await widget.viewModel.applyForMonetization();
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Congratulations! Monetization approved!')),
                      );
                    }
                  }
                : null,
            child: Text(
              prog.isEligible ? 'Apply For Monetization' : 'Complete All 5 Criteria To Apply',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistTile({
    required String title,
    required String current,
    required String target,
    required bool isMet,
    Widget? actionButton,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? AppColors.emeraldSuccess : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                Text('$current • Target: $target', style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }

  Widget _buildProgressTile({
    required String title,
    required num current,
    required num target,
    required IconData icon,
    bool isFormatted = false,
  }) {
    final double pct = (current / target).clamp(0.0, 1.0).toDouble();
    final isMet = current >= target;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: isMet ? AppColors.emeraldSuccess : AppColors.neonGold),
                  const SizedBox(width: 8),
                  Text(title, style: AppTypography.titleSmall),
                ],
              ),
              Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isMet ? AppColors.emeraldSuccess : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceBorder,
              color: isMet ? AppColors.emeraldSuccess : AppColors.neonGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFormatted
                ? '${_formatNum(current)} / ${_formatNum(target)}'
                : '$current / $target',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatNum(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildLedgerList(dynamic summary) {
    if (summary.ledgerHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('No ad revenue transactions recorded yet.', style: AppTypography.bodySmall),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summary.ledgerHistory.length,
      itemBuilder: (ctx, i) {
        final entry = summary.ledgerHistory[i];
        final isCredit = entry.amountCents > 0;
        final formattedUsd = (entry.amountCents.abs() / 100.0).toStringAsFixed(2);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.description, style: AppTypography.titleSmall),
                    const SizedBox(height: 2),
                    Text(entry.createdAt.toString().substring(0, 16), style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : '-'}\$$formattedUsd',
                style: TextStyle(
                  color: isCredit ? AppColors.emeraldSuccess : AppColors.crimsonError,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
