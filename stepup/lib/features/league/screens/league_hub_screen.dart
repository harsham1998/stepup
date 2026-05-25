import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/league_provider.dart';
import '../../../shared/models/league_status.dart';
import '../../../core/theme.dart';

class LeagueHubScreen extends ConsumerWidget {
  const LeagueHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueStatusProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: leagueAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(
              child:
                  Text('Error: $e', style: const TextStyle(color: Colors.white))),
          data: (league) => _LeagueContent(league: league),
        ),
      ),
    );
  }
}

class _LeagueContent extends StatelessWidget {
  final LeagueStatus league;
  const _LeagueContent({required this.league});

  @override
  Widget build(BuildContext context) {
    final tierColor = _parseColor(league.colorHex);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('League', style: AppTheme.bigNum(28)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text('Season ${league.season}',
                        style: AppTheme.label(11)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tier hero
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      tierColor.withOpacity(0.2),
                      Colors.transparent
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  _TierBadge(color: tierColor, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    league.label.toUpperCase(),
                    style: AppTheme.bigNum(32, color: tierColor)
                        .copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rank ${league.rankInTier} of ${league.totalInTier} in your league',
                    style: AppTheme.label(13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${league.xp} XP',
                          style: AppTheme.label(12, color: tierColor)),
                      Text('→ ${league.xpForNext} XP',
                          style: AppTheme.label(12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: league.xpProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(tierColor),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () =>
                    context.push('/leaderboard/standings'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View Standings',
                        style: AppTheme.label(13,
                            color: AppTheme.voltLime)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppTheme.voltLime, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'TIER LADDER',
                style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
                    letterSpacing: 1.4, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              ...league.tierLadder
                  .map((tier) => _TierRow(tier: tier)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TierRow extends StatelessWidget {
  final LeagueTier tier;
  const _TierRow({required this.tier});

  @override
  Widget build(BuildContext context) {
    final c = _parseColor(tier.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            tier.isCurrent ? c.withOpacity(0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tier.isCurrent
              ? c.withOpacity(0.5)
              : AppTheme.border,
        ),
      ),
      child: Row(children: [
        _TierBadge(color: c, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                tier.label,
                style: AppTheme.bigNum(16,
                    color: tier.isCurrent ? c : Colors.white),
              ),
              const SizedBox(width: 6),
              if (tier.paidOnly) _Chip('PRO', AppTheme.amber),
              if (tier.isCurrent) _Chip('YOU', AppTheme.voltLime),
            ]),
            Text(
              '${tier.xpMin}${tier.xpMax != null ? '–${tier.xpMax}' : '+'} XP',
              style: AppTheme.label(11),
            ),
          ]),
        ),
        if (tier.locked && !tier.isCurrent)
          const Icon(Icons.lock_rounded,
              color: AppTheme.ink3, size: 16),
      ]),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final Color color;
  final double size;
  const _TierBadge({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.3)
          ]),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(Icons.military_tech_rounded,
            color: Colors.black87, size: size * 0.5),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTheme.label(9, color: color).copyWith(
              fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      );
}

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppTheme.amber;
  }
}
