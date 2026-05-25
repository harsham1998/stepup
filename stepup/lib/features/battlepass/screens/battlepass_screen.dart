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
              child: CircularProgressIndicator(
                  color: AppTheme.voltLime)),
          error: (e, _) => Center(
              child: Text('$e',
                  style:
                      const TextStyle(color: Colors.white))),
          data: (bp) => bp == null
              ? Center(
                  child: Text(
                      'No active Battle Pass season',
                      style: AppTheme.label(16)))
              : _BattlePassContent(bp: bp),
        ),
      ),
    );
  }
}

class _BattlePassContent extends StatelessWidget {
  final BattlePassProgress bp;
  const _BattlePassContent({required this.bp});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 4),
                Expanded(
                    child:
                        Text('Battle Pass', style: AppTheme.bigNum(26))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text('${bp.daysRemaining}d left',
                      style: AppTheme.label(11)),
                ),
              ]),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(bp.title,
                    style:
                        AppTheme.label(14, color: AppTheme.ink2)),
              ),
              const SizedBox(height: 20),

              // XP bar
              Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${bp.userXp} XP',
                        style: AppTheme.bigNum(20,
                            color: AppTheme.voltLime)),
                    if (!bp.isPremium)
                      ElevatedButton(
                        onPressed: () =>
                            context.push('/profile/subscription'),
                        child: Text(
                          'Go Premium',
                          style: AppTheme.label(12,
                                  color: AppTheme.bg)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ]),
              const SizedBox(height: 16),

              // Tier track — horizontal scroll
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: bp.tiers.length,
                  separatorBuilder: (_, __) => Container(
                    width: 24,
                    height: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 50),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  itemBuilder: (_, i) => _TierColumn(
                      tier: bp.tiers[i], isPremium: bp.isPremium),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'REWARDS PER TIER',
                style: AppTheme.label(10, color: AppTheme.ink3)
                    .copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...bp.tiers.map((t) =>
                  _TierRewardRow(tier: t, isPremium: bp.isPremium)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TierColumn extends StatelessWidget {
  final BattlePassTierData tier;
  final bool isPremium;
  const _TierColumn(
      {required this.tier, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = tier.unlocked;
    final c = isUnlocked ? AppTheme.voltLime : AppTheme.ink3;
    return SizedBox(
      width: 80,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppTheme.voltLime.withOpacity(0.15)
                    : AppTheme.surface,
                border: Border.all(
                  color: isUnlocked
                      ? AppTheme.voltLime
                      : AppTheme.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: tier.claimed
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.voltLime)
                    : Text('${tier.level}',
                        style: AppTheme.bigNum(18, color: c)),
              ),
            ),
            const SizedBox(height: 8),
            Text('${tier.xpRequired} XP',
                style: AppTheme.label(10, color: c)),
            const SizedBox(height: 4),
            Text(
              isPremium ? tier.paidReward : tier.freeReward,
              style: AppTheme.label(10,
                  color: isUnlocked ? Colors.white : AppTheme.ink3),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
    );
  }
}

class _TierRewardRow extends StatelessWidget {
  final BattlePassTierData tier;
  final bool isPremium;
  const _TierRewardRow(
      {required this.tier, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tier.unlocked
            ? AppTheme.voltLime.withOpacity(0.06)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tier.unlocked
              ? AppTheme.voltLime.withOpacity(0.25)
              : AppTheme.border,
        ),
      ),
      child: Row(children: [
        Text(
          'Level ${tier.level}',
          style: AppTheme.bigNum(14,
              color:
                  tier.unlocked ? AppTheme.voltLime : AppTheme.ink3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isPremium ? tier.paidReward : tier.freeReward,
            style: AppTheme.label(12,
                color: tier.unlocked ? Colors.white : AppTheme.ink3),
          ),
        ),
        if (tier.claimed)
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.voltLime, size: 18),
      ]),
    );
  }
}
