import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class UpgradePromptScreen extends StatelessWidget {
  const UpgradePromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('Close',
                      style: AppTheme.label(13, color: AppTheme.ink2)),
                ),
              ],
            ),
            const Spacer(flex: 2),

            // Lock icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.amber, width: 2),
              ),
              child: const Center(
                child: Text('◆',
                    style: TextStyle(
                        fontSize: 32, color: AppTheme.amber)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock\nCoin Rewards',
              textAlign: TextAlign.center,
              style: AppTheme.bigNum(28),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Paid challenges reward you with coins for staying consistent',
                textAlign: TextAlign.center,
                style: AppTheme.label(14, color: AppTheme.ink2),
              ),
            ),
            const SizedBox(height: 24),

            // Plan card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.voltLime.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Beginner plan', style: AppTheme.bigNum(20)),
                      Row(children: [
                        Text('₹149',
                            style: AppTheme.bigNum(20, color: AppTheme.amber)),
                        Text(' / Mo',
                            style: AppTheme.label(12, color: AppTheme.ink2)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    '2 Paid challenges / month',
                    'Consistency-based coin rewards',
                    'Top 50% earn extra coins',
                    'Redeem coins for gift cards',
                  ].map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(Icons.check_rounded,
                          color: AppTheme.voltLime, size: 14),
                      const SizedBox(width: 8),
                      Text(f, style: AppTheme.label(13, color: Colors.white)),
                    ]),
                  )),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/profile/subscription'),
                child: const Text('Upgrade — ₹149/mo'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Maybe later',
                    style: AppTheme.label(14, color: AppTheme.ink2)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
