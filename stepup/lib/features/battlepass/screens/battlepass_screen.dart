import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/battlepass_provider.dart';
import '../../../shared/models/battle_pass.dart';
import '../../../core/theme.dart';

class BattlePassScreen extends ConsumerWidget {
  const BattlePassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpAsync = ref.watch(battlePassProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: bpAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (_, __) => const _BattlePassBody(
            season: 4,
            daysLeft: 14,
            currentTier: 18,
            totalTiers: 50,
            xpCurrent: 360,
            xpForTier: 500,
            isPro: false,
          ),
          data: (bp) => bp == null
              ? const _BattlePassBody(
                  season: 4,
                  daysLeft: 14,
                  currentTier: 18,
                  totalTiers: 50,
                  xpCurrent: 360,
                  xpForTier: 500,
                  isPro: false,
                )
              : _BattlePassBody(
                  season: bp.season,
                  daysLeft: bp.daysRemaining,
                  currentTier: bp.tiers.where((t) => t.unlocked).length,
                  totalTiers: bp.tiers.isEmpty ? 50 : bp.tiers.length,
                  xpCurrent: bp.userXp,
                  xpForTier: bp.tiers.where((t) => !t.unlocked).isNotEmpty
                      ? bp.tiers.firstWhere((t) => !t.unlocked).xpRequired
                      : 500,
                  isPro: bp.isPremium,
                ),
        ),
      ),
    );
  }
}

class _BattlePassBody extends StatelessWidget {
  final int season, daysLeft, currentTier, totalTiers, xpCurrent, xpForTier;
  final bool isPro;
  const _BattlePassBody({
    required this.season,
    required this.daysLeft,
    required this.currentTier,
    required this.totalTiers,
    required this.xpCurrent,
    required this.xpForTier,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    final xpPct = xpForTier > 0 ? (xpCurrent / xpForTier).clamp(0.0, 1.0) : 0.36;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SEASON $season',
                style: AppTheme.bigNum(22)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${daysLeft}D LEFT',
                  style: AppTheme.label(11, color: AppTheme.voltLime)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress strip
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x1AD4FF3A), Color(0x0AFFB547)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TIER $currentTier / $totalTiers',
                    style: AppTheme.bigNum(24, color: AppTheme.voltLime)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isPro ? 'PRO' : 'FREE',
                      style: AppTheme.label(10, color: AppTheme.amber)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: xpPct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$xpCurrent / $xpForTier XP this tier',
                    style: AppTheme.label(10, color: AppTheme.ink2)),
                Text('Tier ${currentTier + 1} →',
                    style: AppTheme.label(10, color: AppTheme.ink2)),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),

        Text('REWARDS TRACK',
            style: AppTheme.label(10, color: AppTheme.ink2)
                .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        // Horizontal tier track
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (_, i) {
              final tier = currentTier - 2 + i;
              final isCurrent = tier == currentTier;
              final claimed = tier < currentTier;
              final icons = [
                Icons.monetization_on_rounded,
                Icons.star_rounded,
                Icons.monetization_on_rounded,
                Icons.shield_rounded,
                Icons.monetization_on_rounded,
                Icons.military_tech_rounded,
                Icons.star_rounded,
              ];
              final proIcons = [
                Icons.shield_rounded,
                Icons.shield_rounded,
                Icons.military_tech_rounded,
                Icons.shield_rounded,
                Icons.workspace_premium_rounded,
                Icons.shield_rounded,
                Icons.shield_rounded,
              ];
              return Container(
                width: 76,
                margin: const EdgeInsets.only(right: 8),
                child: Column(children: [
                  Text('T$tier',
                      style: AppTheme.label(12,
                              color: isCurrent ? AppTheme.voltLime : AppTheme.ink3)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  // Free row
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: claimed
                          ? AppTheme.voltLime.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.voltLime
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(children: [
                      Center(
                        child: Icon(icons[i], size: 26,
                            color: claimed ? AppTheme.voltLime : AppTheme.ink2),
                      ),
                      Positioned(
                        bottom: 4, left: 0, right: 0,
                        child: Text('+50 ¢',
                            textAlign: TextAlign.center,
                            style: AppTheme.label(9, color: AppTheme.ink2)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  // Pro row
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.amber.withValues(alpha: 0.2),
                          width: 1.5),
                    ),
                    child: Stack(children: [
                      Center(
                        child: Icon(proIcons[i], size: 26, color: AppTheme.amber),
                      ),
                      Positioned(
                        bottom: 4, left: 0, right: 0,
                        child: Text('Frame',
                            textAlign: TextAlign.center,
                            style: AppTheme.label(9, color: AppTheme.amber)),
                      ),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(
            color: AppTheme.voltLime, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('Free', style: AppTheme.label(11, color: AppTheme.voltLime)),
          const SizedBox(width: 12),
          Container(width: 8, height: 8, decoration: BoxDecoration(
            color: AppTheme.amber, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('Pro', style: AppTheme.label(11, color: AppTheme.amber)),
        ]),
        const Spacer(),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(
                  child: Text('Free Pass',
                      style: AppTheme.label(14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/profile/subscription'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text('Unlock Pro · ₹299',
                      style: AppTheme.label(14, color: AppTheme.amber)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
