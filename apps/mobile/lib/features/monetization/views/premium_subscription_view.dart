import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens.dart';

class PremiumSubscriptionView extends StatefulWidget {
  const PremiumSubscriptionView({super.key});

  @override
  State<PremiumSubscriptionView> createState() => _PremiumSubscriptionViewState();
}

class _PremiumSubscriptionViewState extends State<PremiumSubscriptionView> {
  bool _isSubscribed = false;
  bool _isLoading = false;

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
        title: const Text('W\'s Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Gold Header Crown
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [WsTokens.brandGold, Color(0xFFFFA000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: WsTokens.brandGold.withOpacity(0.35), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: const Center(
                child: Icon(Icons.workspace_premium, color: Colors.black, size: 44),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlock W\'s Premium',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.black),
            ),
            const SizedBox(height: 6),
            const Text(
              'Elevate your creator presence and monetize your audience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 28),

            // Benefits Checklist
            _BenefitItem(
              icon: Icons.verified,
              color: WsTokens.brandGold,
              title: 'Official Verification Badge',
              description: 'Golden checkmark on your profile, videos, and comments.',
            ),
            const SizedBox(height: 16),
            _BenefitItem(
              icon: Icons.monetization_on,
              color: WsTokens.brandEmerald,
              title: 'Creator Monetization Gate Pass',
              description: 'Essential requirement to qualify for the 55% ad revenue USD split.',
            ),
            const SizedBox(height: 16),
            _BenefitItem(
              icon: Icons.rocket_launch,
              color: WsTokens.tiktokCyan,
              title: '2.5x FYP Recommendation Boost',
              description: 'Increased algorithmic visibility on community feeds.',
            ),
            const SizedBox(height: 16),
            _BenefitItem(
              icon: Icons.ac_unit,
              color: const Color(0xFF64B5F6),
              title: 'Streak Freeze Shield',
              description: '1 monthly streak freeze to safeguard your DM streak cards.',
            ),

            const Spacer(),

            // Price & Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF282838)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Subscription', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('$4.99 / month', style: TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubscribed ? WsTokens.brandEmerald : WsTokens.brandGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubscribed || _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        setState(() {
                          _isLoading = false;
                          _isSubscribed = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: WsTokens.brandEmerald,
                            content: Text('Welcome to W\'s Premium! Verification badge activated. ✨', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        _isSubscribed ? 'Active Premium Member ✓' : 'Subscribe Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
