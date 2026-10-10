import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';
import '../view_models/monetization_view_model.dart';

class CampaignManagerView extends StatefulWidget {
  final MonetizationViewModel viewModel;

  const CampaignManagerView({super.key, required this.viewModel});

  @override
  State<CampaignManagerView> createState() => _CampaignManagerViewState();
}

class _CampaignManagerViewState extends State<CampaignManagerView> {
  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _ctaUrlController = TextEditingController();
  final _budgetController = TextEditingController(text: '50.00');
  final _cpmController = TextEditingController(text: '10.00');
  String _ctaLabel = 'Learn More';

  final List<String> _ctaOptions = [
    'Learn More',
    'Shop Now',
    'Claim Deal',
    'Download',
    'Sign Up',
  ];

  void _createCampaign() async {
    final name = _nameController.text.trim();
    final headline = _headlineController.text.trim();
    final ctaUrl = _ctaUrlController.text.trim();
    final budgetVal = double.tryParse(_budgetController.text) ?? 0.0;
    final cpmVal = double.tryParse(_cpmController.text) ?? 0.0;

    if (name.isEmpty || ctaUrl.isEmpty || budgetVal <= 0 || cpmVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all campaign fields validly')),
      );
      return;
    }

    final success = await widget.viewModel.createCampaign(
      videoId: 'sample-promo-clip',
      name: name,
      headline: headline,
      ctaUrl: ctaUrl,
      ctaLabel: _ctaLabel,
      budgetCents: (budgetVal * 100).toInt(),
      cpmBidCents: (cpmVal * 100).toInt(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad Campaign launched successfully!')),
      );
      _nameController.clear();
      _headlineController.clear();
      _ctaUrlController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Self-Serve Ad Manager', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.neonGold, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Promote your videos natively across FYP feeds. No third-party network: pay per verified view with direct conversion tracking.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Create New Campaign', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Campaign Name',
                hintText: 'e.g. Summer Drop Launch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _headlineController,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Headline Text',
                hintText: 'e.g. Get 20% off all hoodies this week only!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _ctaUrlController,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Destination URL',
                hintText: 'https://brand.com/store',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              value: _ctaLabel,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Call To Action Button',
                border: OutlineInputBorder(),
              ),
              items: _ctaOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTypography.bodyMedium)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _ctaLabel = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Total Budget (USD)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _cpmController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'CPM Bid (USD)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGold,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Launch Native Ad Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _createCampaign,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Active Campaigns', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),

            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (ctx, _) {
                final list = widget.viewModel.myCampaigns;
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text('No active campaigns running right now.', style: AppTypography.bodySmall),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (c, idx) {
                    final camp = list[idx];
                    final budgetUsd = (camp.budgetCents / 100.0).toStringAsFixed(2);
                    final spentUsd = (camp.spentCents / 100.0).toStringAsFixed(2);

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
                              Text(camp.campaignName, style: AppTypography.titleSmall),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSuccess.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  camp.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.emeraldSuccess,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(camp.headline, style: AppTypography.bodySmall),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Spent: \$$spentUsd / \$$budgetUsd', style: AppTypography.bodySmall),
                              Text('${camp.impressionCount} views • ${camp.clickCount} clicks', style: AppTypography.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
