import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class SeasonRewardsScreen extends StatelessWidget {
  const SeasonRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SEASON 1: FOUNDATION',
                  style: AppTheme.label(11, color: AppTheme.voltLime)
                      .copyWith(letterSpacing: 2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text('SEASON ENDED', style: AppTheme.bigNum(36)),
              const SizedBox(height: 8),
              Text('Your final rank', style: AppTheme.label(13, color: AppTheme.ink2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                ),
                child: Text('GOLD', style: AppTheme.bigNum(42, color: AppTheme.amber)),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(children: [
                  Text('Season Reward', style: AppTheme.label(11, color: AppTheme.ink2)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('250', style: AppTheme.bigNum(48, color: AppTheme.voltLime)),
                    const SizedBox(width: 8),
                    const Icon(Icons.monetization_on_rounded, color: AppTheme.amber, size: 36),
                  ]),
                  Text('Coins added to your wallet',
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                ]),
              ),
              const SizedBox(height: 28),
              Text('New season starting soon',
                  style: AppTheme.label(12, color: AppTheme.ink2)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('Continue →',
                        style: AppTheme.label(15, color: AppTheme.bg)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
