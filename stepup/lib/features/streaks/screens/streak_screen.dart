import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/streak_provider.dart';
import '../../../shared/models/streak_status.dart';
import '../../../core/theme.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStatusProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Streak Protection'),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: streakAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppTheme.voltLime)),
        error: (e, _) => Center(
            child: Text('$e',
                style: const TextStyle(color: Colors.white))),
        data: (streak) => _StreakContent(streak: streak),
      ),
    );
  }
}

class _StreakContent extends ConsumerWidget {
  final StreakStatus streak;
  const _StreakContent({required this.streak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.amber.withOpacity(0.2),
                    AppTheme.surface
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: streak.streakAtRisk
                      ? const Color(0xFFEF4444).withOpacity(0.4)
                      : AppTheme.amber.withOpacity(0.3),
                ),
              ),
              child: Column(children: [
                const Text('🔥',
                    style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text('${streak.streakDays}',
                    style: AppTheme.bigNum(64,
                        color: AppTheme.amber)),
                Text('day streak',
                    style: AppTheme.label(16,
                        color: AppTheme.amber)),
                if (streak.streakAtRisk) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⚠️  Streak at risk — log activity today!',
                      style: AppTheme.label(12,
                          color: const Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 24),

            Text(
              'PROTECTION OPTIONS',
              style: AppTheme.label(10, color: AppTheme.ink3)
                  .copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Shield card
            _ProtectionCard(
              title: 'Streak Shield',
              subtitle: streak.shieldAvailable
                  ? '1 available this month'
                  : 'Used this month',
              icon: Icons.shield_rounded,
              color: AppTheme.voltLime,
              available: streak.shieldAvailable,
              badge: 'PRO',
              onTap: streak.shieldAvailable
                  ? () => _useShield(context)
                  : null,
            ),
            const SizedBox(height: 10),

            // Revive card
            _ProtectionCard(
              title: 'Revive Streak',
              subtitle: streak.reviveAvailable
                  ? 'Costs ${streak.reviveCostCoins}¢ (you have ${streak.coinBalance}¢)'
                  : 'Used this month',
              icon: Icons.restore_rounded,
              color: AppTheme.amber,
              available: streak.reviveAvailable &&
                  streak.coinBalance >= streak.reviveCostCoins,
              badge: '${streak.reviveCostCoins}¢',
              onTap: streak.reviveAvailable
                  ? () => _revive(context)
                  : null,
            ),
            const Spacer(),

            // Upgrade prompt if no shield
            if (!streak.shieldAvailable && streak.streakAtRisk)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.voltLime.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.voltLime.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppTheme.voltLime),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upgrade to Pro for monthly streak shields',
                      style: AppTheme.label(13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        context.push('/profile/subscription'),
                    child: Text(
                      'Upgrade',
                      style: AppTheme.label(13,
                              color: AppTheme.voltLime)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
          ]),
    );
  }

  void _useShield(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Shield used — streak protected!')),
    );
  }

  void _revive(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Streak revived!')),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  final String title, subtitle, badge;
  final IconData icon;
  final Color color;
  final bool available;
  final VoidCallback? onTap;
  const _ProtectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.available,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: available
                ? color.withOpacity(0.08)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: available
                  ? color.withOpacity(0.3)
                  : AppTheme.border,
            ),
          ),
          child: Row(children: [
            Icon(icon,
                color: available ? color : AppTheme.ink3,
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.label(14,
                              color: available
                                  ? Colors.white
                                  : AppTheme.ink3)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(subtitle, style: AppTheme.label(11)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: available
                    ? color.withOpacity(0.15)
                    : AppTheme.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: AppTheme.label(11,
                        color: available ? color : AppTheme.ink3)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
      );
}
