import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/tokens.dart';
import '../view_models/moderation_view_model.dart';

/// Top banner displayed across feeds and screens when an account is restricted.
class PassiveRestrictionBanner extends ConsumerWidget {
  const PassiveRestrictionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderationViewModelProvider);
    final status = state.status;

    if (status == null || !status.isRestricted) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.amber.shade900.withOpacity(0.9),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Account in Passive Preview Mode: Comments and staking are disabled; video views do not count.',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: WsTokens.surfaceElevated,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => const AppealBottomSheet(),
              );
            },
            child: const Text('Appeal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// In-app appeal bottom sheet to request review of automated bot restrictions.
class AppealBottomSheet extends ConsumerStatefulWidget {
  const AppealBottomSheet({super.key});

  @override
  ConsumerState<AppealBottomSheet> createState() => _AppealBottomSheetState();
}

class _AppealBottomSheetState extends ConsumerState<AppealBottomSheet> {
  final _textController = TextEditingController();
  String _selectedReason = 'Automated Commenting Misunderstanding';

  final List<String> _reasons = [
    'Automated Commenting Misunderstanding',
    'I am a human creator/viewer',
    'False positive bot detection',
    'Other reason',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modState = ref.watch(moderationViewModelProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WsTokens.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: WsTokens.brandGold, size: 24),
              SizedBox(width: 8),
              Text(
                'Submit Moderation Appeal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WsTokens.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your account was automatically restricted due to rapid comment frequency. You can still watch videos, but commenting, posting, and staking are restricted until reviewed.',
            style: TextStyle(fontSize: 13, color: WsTokens.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('Appeal Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WsTokens.textMuted)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: WsTokens.surfaceBlack,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: WsTokens.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReason,
                isExpanded: true,
                dropdownColor: WsTokens.surfaceBlack,
                style: const TextStyle(color: WsTokens.textPrimary, fontSize: 14),
                items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedReason = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Explanation / Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WsTokens.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _textController,
            maxLines: 4,
            style: const TextStyle(color: WsTokens.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Explain why this restriction was a misunderstanding...',
              hintStyle: const TextStyle(color: WsTokens.textMuted),
              filled: true,
              fillColor: WsTokens.surfaceBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: WsTokens.divider),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (modState.appealSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WsTokens.brandEmerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WsTokens.brandEmerald.withOpacity(0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: WsTokens.brandEmerald, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Appeal submitted successfully! Our trust team will review your account.',
                      style: TextStyle(color: WsTokens.brandEmerald, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WsTokens.brandGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: modState.isSubmitting || modState.appealSubmitted
                  ? null
                  : () async {
                      await ref
                          .read(moderationViewModelProvider.notifier)
                          .submitAppeal(_selectedReason, _textController.text);
                    },
              child: modState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Submit Appeal for Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
