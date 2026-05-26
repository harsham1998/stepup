import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (_, __) => const _LeagueBody(
            season: 4,
            tierLabel: 'GOLD III',
            tierColor: Color(0xFFD9A93A),
            rank: 142,
            total: 8420,
            xp: 1840,
            xpForNext: 2500,
            tierLadder: [],
          ),
          data: (league) => _LeagueBody(
            season: league.season,
            tierLabel: league.label.toUpperCase(),
            tierColor: _parseColor(league.colorHex),
            rank: league.rankInTier,
            total: league.totalInTier,
            xp: league.xp,
            xpForNext: league.xpForNext,
            tierLadder: league.tierLadder,
          ),
        ),
      ),
    );
  }
}

class _LeagueBody extends StatelessWidget {
  final int season, rank, total, xp, xpForNext;
  final String tierLabel;
  final Color tierColor;
  final List<LeagueTier> tierLadder;
  const _LeagueBody({
    required this.season,
    required this.tierLabel,
    required this.tierColor,
    required this.rank,
    required this.total,
    required this.xp,
    required this.xpForNext,
    required this.tierLadder,
  });

  @override
  Widget build(BuildContext context) {
    final xpPct = xpForNext > 0 ? (xp / xpForNext).clamp(0.0, 1.0) : 0.73;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('League', style: AppTheme.bigNum(28)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text('Season $season', style: AppTheme.label(11, color: AppTheme.ink2)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Current tier hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.4,
              colors: [tierColor.withValues(alpha: 0.16), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _TierBadge(color: tierColor, size: 88),
            const SizedBox(height: 24),
            Text(tierLabel,
                style: AppTheme.bigNum(28, color: tierColor)
                    .copyWith(letterSpacing: 1)),
            const SizedBox(height: 2),
            Text('Rank $rank of $total in your league',
                style: AppTheme.label(12, color: AppTheme.ink2)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$xp XP', style: AppTheme.label(12, color: tierColor)),
                Text('→ Platinum ($xpForNext XP)',
                    style: AppTheme.label(12, color: AppTheme.ink2)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: xpPct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(tierColor),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        Text('TIER LADDER',
            style: AppTheme.label(10, color: AppTheme.ink2)
                .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        // If we have live tier data, use it; else show mock
        if (tierLadder.isNotEmpty)
          ...tierLadder.map((t) {
            final c = _parseColor(t.colorHex);
            return _TierRow(
              label: t.label,
              color: c,
              size: 36,
              sub: '${t.xpMin}+ XP',
              isPaidGate: t.paidOnly,
              isCurrent: t.isCurrent,
              isLocked: t.locked,
            );
          })
        else
          ..._mockTiers.map((t) => _TierRow(
                label: t[0] as String,
                color: Color(int.parse((t[1] as String).replaceFirst('#', '0xFF'))),
                size: 36,
                sub: t[4] as String,
                isPaidGate: t[2] as bool,
                isCurrent: t[3] as bool,
                isLocked: (t[5] as bool) && !(t[3] as bool),
              )),
      ]),
    );
  }

  static const _mockTiers = [
    ['Bronze', '#a86a3a', false, false, 'Tier I–III', false],
    ['Silver', '#9aa3ad', false, false, 'Tier I–III', false],
    ['Gold', '#d9a93a', false, true, 'Tier I–III', false],
    ['Platinum', '#7ed4d4', true, false, 'Premium only', true],
    ['Diamond', '#a8c4ff', false, false, 'Top 10%', true],
    ['Elite', '#d4ff3a', false, false, 'Top 1%', true],
  ];
}

class _TierRow extends StatelessWidget {
  final String label, sub;
  final Color color;
  final double size;
  final bool isPaidGate, isCurrent, isLocked;
  const _TierRow({
    required this.label,
    required this.color,
    required this.size,
    required this.sub,
    required this.isPaidGate,
    required this.isCurrent,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(children: [
        _TierBadge(color: color, size: size),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: AppTheme.label(14,
                          color: isCurrent ? color : Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
              if (isPaidGate) ...[
                const SizedBox(width: 6),
                _SmallChip('PRO', AppTheme.amber),
              ],
              if (isCurrent) ...[
                const SizedBox(width: 6),
                _SmallChip('YOU', AppTheme.voltLime),
              ],
            ]),
            Text(sub, style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),
        if (isLocked)
          const Icon(Icons.lock_rounded, color: AppTheme.ink3, size: 16),
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
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 0.9,
            colors: [color, color.withValues(alpha: 0.4)],
          ),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(Icons.military_tech_rounded,
            color: const Color(0xFF0A0A14), size: size * 0.45),
      );
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: AppTheme.label(9, color: color)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );
}

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppTheme.amber;
  }
}
