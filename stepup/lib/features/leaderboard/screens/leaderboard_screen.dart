import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/leaderboard_provider.dart';
import '../../../shared/models/leaderboard_entry.dart';
import '../../../core/theme.dart';

// ── Orbit clock positions (dx, dy fractions × radius) ─────────────────────
const _kRadius = 62.0;
const _kPositions = [
  Offset(0, -1),       // 12 — rank 1  (gold)
  Offset(-0.866, -0.5), // 10 — rank 2  (silver)
  Offset(0.866, -0.5),  //  2 — rank 3  (bronze)
  Offset(1, 0),         //  3 — rank 5  (right)
  Offset(0.866, 0.5),   //  4 — rank 8  (lower-right)
  Offset(-1, 0),        //  9 — cutoff  (left, amber)
  Offset(-0.866, 0.5),  //  8 — below cutoff (lower-left, red)
];

// Maps position index → entry index in the sorted entries list
const _kEntryIndexes = [0, 1, 2, 4, 7, -1, -2];
// -1 = cutoff entry, -2 = one below cutoff

// ── Formatting helpers ─────────────────────────────────────────────────────
String _fmtRank(int rank) {
  if (rank <= 0) return '--';
  if (rank >= 10000) return '${(rank / 1000).round()}K';
  if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(1)}K';
  return '$rank';
}

String _pctStr(int steps, int maxSteps) {
  if (maxSteps <= 0 || steps <= 0) return '--';
  return '${(steps * 100 / maxSteps).round().clamp(0, 100)}%';
}

// ── Screen ─────────────────────────────────────────────────────────────────
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _tab = 0; // 0=challenge(global), 1=friends, 2=global

  static const _filterLabels = ['This challenge', 'Friends', 'Global'];

  AsyncValue<LeaderboardResult> get _currentAsync => _tab == 1
      ? ref.watch(friendsLeaderboardProvider)
      : ref.watch(globalLeaderboardProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContextBar(),
            _buildSwipeDots(),
            _currentAsync.when(
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator(
                    color: AppTheme.voltLime, strokeWidth: 2)),
              ),
              error: (err, _) => Expanded(child: _buildBody(_fallbackResult())),
              data: (result) => Expanded(child: _buildBody(result)),
            ),
          ],
        ),
      ),
    );
  }

  // ── fallback for error / empty ─────────────────────────────────────────
  LeaderboardResult _fallbackResult() => const LeaderboardResult(
        entries: [], myRank: 0, mySteps: 0);

  // ── Context bar ───────────────────────────────────────────────────────
  Widget _buildContextBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 4),
      child: Row(
        children: [
          // League quick-link pill
          GestureDetector(
            onTap: () => context.push('/leaderboard/league'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.voltLime.withValues(alpha: 0.28)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏆', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('League',
                    style: AppTheme.label(11, color: AppTheme.voltLime)
                        .copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          const Spacer(),
          // Filter selector
          GestureDetector(
            onTap: () => setState(() => _tab = (_tab + 1) % 3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_filterLabels[_tab],
                  style: AppTheme.label(12, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.ink2, size: 16),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Swipe dots ────────────────────────────────────────────────────────
  Widget _buildSwipeDots() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _tab == i ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _tab == i
                      ? AppTheme.voltLime
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 3),
          ],
          const SizedBox(width: 6),
          Text(
            _filterLabels
                .where((l) => l != _filterLabels[_tab])
                .join(' · '),
            style: AppTheme.label(9, color: AppTheme.ink3),
          ),
        ],
      ),
    );
  }

  // ── Full body (hero + radar + list) ──────────────────────────────────
  Widget _buildBody(LeaderboardResult result) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(result),
          const SizedBox(height: 6),
          _buildOrbitLabel(),
          _buildOrbitRadar(result),
          const SizedBox(height: 4),
          _buildRankList(result),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────
  Widget _buildHeroCard(LeaderboardResult r) {
    final rankStr = r.myRank > 0 ? '#${_fmtRank(r.myRank)}' : '--';
    final tierStr = r.myRank > 0 && r.total > 0
        ? 'Top ${r.myTopPct}% ★ · of ${r.total}'
        : 'Loading…';
    final progress = r.myProgress;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13),
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: AppTheme.voltLime.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.voltLime.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank + tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR RANK',
                        style: AppTheme.label(7,
                                color: AppTheme.ink3)
                            .copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                    Text(rankStr,
                        style: AppTheme.bigNum(26,
                            color: AppTheme.voltLime)),
                    Text(tierStr,
                        style: AppTheme.label(9,
                                color: AppTheme.ink2)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              // Coin badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.amber.withValues(alpha: 0.26)),
                ),
                child: Column(children: [
                  Text('+200¢',
                      style: AppTheme.label(10, color: AppTheme.amber)
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text('on track',
                      style: AppTheme.label(7,
                              color: AppTheme.amber.withValues(alpha: 0.6))
                          .copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                valueColor: AlwaysStoppedAnimation(AppTheme.voltLime),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── "ORBIT VIEW" label ─────────────────────────────────────────────────
  Widget _buildOrbitLabel() => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Center(
          child: Text('ORBIT VIEW',
              style: AppTheme.label(7, color: AppTheme.ink3)
                  .copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6)),
        ),
      );

  // ── Orbit radar ───────────────────────────────────────────────────────
  Widget _buildOrbitRadar(LeaderboardResult r) {
    final entries = r.entries;
    final cutoffIdx = r.cutoffRank - 1; // 0-based

    // Resolve entry for each orbit position
    LeaderboardEntry? entryFor(int posIdx) {
      final ei = _kEntryIndexes[posIdx];
      if (ei >= 0) return ei < entries.length ? entries[ei] : null;
      if (ei == -1) return cutoffIdx < entries.length ? entries[cutoffIdx] : null;
      if (ei == -2) return (cutoffIdx + 1) < entries.length ? entries[cutoffIdx + 1] : null;
      return null;
    }

    return SizedBox(
      height: 185,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Rings + sweep glow painter
          const SizedBox.expand(child: CustomPaint(painter: _RingsPainter())),

          // Orbit dots
          for (int i = 0; i < _kPositions.length; i++) ...[
            if (entryFor(i) != null)
              Transform.translate(
                offset: _kPositions[i] * _kRadius,
                child: _OrbitDot(
                  rank: entryFor(i)!.rank,
                  posIndex: i,
                  isCutoff: _kEntryIndexes[i] == -1,
                  isBelowCutoff: _kEntryIndexes[i] == -2,
                ),
              ),
          ],

          // You — center
          if (r.myRank > 0) _YouDot(rank: r.myRank),
        ],
      ),
    );
  }

  // ── Rank list ─────────────────────────────────────────────────────────
  Widget _buildRankList(LeaderboardResult r) {
    if (r.entries.isEmpty && r.myRank == 0) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('No data yet',
              style: AppTheme.label(13, color: AppTheme.ink3)),
        ),
      );
    }

    final entries = r.entries;
    final maxSteps = r.maxSteps;
    final cutoffRank = r.cutoffRank;

    // Build display rows: top 1, you, cutoff boundary, below cutoff
    final rows = <Widget>[];

    // Rank 1
    if (entries.isNotEmpty) {
      rows.add(_RankRow(
        rankLabel: '#1',
        name: entries.first.name,
        pct: _pctStr(entries.first.steps, maxSteps),
        style: _RowStyle.gold,
      ));
    }

    // You
    if (r.myRank > 0) {
      rows.add(_RankRow(
        rankLabel: '#${_fmtRank(r.myRank)}',
        name: 'You',
        pct: _pctStr(r.mySteps, maxSteps),
        style: _RowStyle.you,
      ));
    }

    // Last entry above cutoff
    final cutoffEntry = cutoffRank - 1 < entries.length
        ? entries[cutoffRank - 1]
        : null;
    if (cutoffEntry != null) {
      rows.add(_RankRow(
        rankLabel: '#${_fmtRank(cutoffEntry.rank)}',
        name: 'Last top 50%',
        pct: _pctStr(cutoffEntry.steps, maxSteps),
        style: _RowStyle.normal,
      ));
    }

    // Cutoff divider
    rows.add(_CutoffDivider(label: 'Top 50% cutoff · #${_fmtRank(cutoffRank)}'));

    // Below cutoff entries (2 rows, dimmed)
    for (int i = cutoffRank; i < (cutoffRank + 2) && i < entries.length; i++) {
      rows.add(_RankRow(
        rankLabel: '#${_fmtRank(entries[i].rank)}',
        name: entries[i].name,
        pct: _pctStr(entries[i].steps, maxSteps),
        style: _RowStyle.dim,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(children: rows),
    );
  }
}

// ── Orbit dot ──────────────────────────────────────────────────────────────
class _OrbitDot extends StatelessWidget {
  final int rank;
  final int posIndex;
  final bool isCutoff;
  final bool isBelowCutoff;

  const _OrbitDot({
    required this.rank,
    required this.posIndex,
    this.isCutoff = false,
    this.isBelowCutoff = false,
  });

  @override
  Widget build(BuildContext context) {
    final isGold = posIndex == 0;
    final isSilver = posIndex == 1;
    final isBronze = posIndex == 2;

    final double size = isGold
        ? 30
        : (isSilver || isBronze)
            ? 25
            : isBelowCutoff
                ? 18
                : 20;

    final Color borderColor = isGold
        ? const Color(0xFFFFD700)
        : isSilver
            ? const Color(0xFFC0C0C0)
            : isBronze
                ? const Color(0xFFCD7F32)
                : isCutoff
                    ? AppTheme.amber.withValues(alpha: 0.5)
                    : isBelowCutoff
                        ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.13);

    final Color bgColor = isGold
        ? const Color(0xFFFFD700).withValues(alpha: 0.13)
        : isSilver
            ? const Color(0xFFC0C0C0).withValues(alpha: 0.1)
            : isBronze
                ? const Color(0xFFCD7F32).withValues(alpha: 0.1)
                : isCutoff
                    ? AppTheme.amber.withValues(alpha: 0.07)
                    : isBelowCutoff
                        ? const Color(0xFFEF4444).withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.04);

    final Color textColor = isGold
        ? const Color(0xFFFFD700)
        : isSilver
            ? const Color(0xFFC0C0C0)
            : isBronze
                ? const Color(0xFFCD7F32)
                : isCutoff
                    ? AppTheme.amber.withValues(alpha: 0.7)
                    : isBelowCutoff
                        ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                        : AppTheme.ink3;

    final double glowAlpha = isGold ? 0.3 : (isSilver || isBronze) ? 0.15 : 0.0;
    final double fontSize = isGold
        ? 11
        : (isSilver || isBronze)
            ? 10
            : rank >= 1000
                ? 6
                : rank >= 100
                    ? 7
                    : 7.5;

    final rankStr = _fmtRank(rank);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow shadow
        if (glowAlpha > 0)
          Container(
            width: size + 8,
            height: size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: glowAlpha),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        // Dot
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: isGold ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              rankStr,
              style: AppTheme.bigNum(fontSize, color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Crown above gold dot
        if (isGold)
          const Positioned(
            top: -18,
            child: Text('👑', style: TextStyle(fontSize: 11)),
          ),
        // Cutoff label below left dot
        if (isCutoff)
          Positioned(
            bottom: -13,
            child: Text('cutoff',
                style: AppTheme.label(5.5,
                    color: AppTheme.amber.withValues(alpha: 0.5))
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

// ── You dot (center) ───────────────────────────────────────────────────────
class _YouDot extends StatelessWidget {
  final int rank;
  const _YouDot({required this.rank});

  @override
  Widget build(BuildContext context) {
    final rankStr = _fmtRank(rank);
    final fontSize = rank >= 1000 ? 9.0 : 12.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.voltLime.withValues(alpha: 0.15)),
          ),
        ),
        // Glow
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.voltLime.withValues(alpha: 0.3),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        // Dot
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.voltLime.withValues(alpha: 0.11),
            border: Border.all(
              color: AppTheme.voltLime.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rankStr,
                style: AppTheme.bigNum(fontSize, color: AppTheme.voltLime),
                textAlign: TextAlign.center,
              ),
              Text(
                'YOU',
                style: AppTheme.label(5.5,
                        color: AppTheme.voltLime.withValues(alpha: 0.65))
                    .copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Rings + sweep glow CustomPainter ──────────────────────────────────────
class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Sweep glow — bright at 12 o'clock, fades clockwise
    final sweepPaint = Paint()
      ..shader = ui.Gradient.sweep(
        c,
        [
          const Color(0xFFD4FF3A).withValues(alpha: 0.07),
          const Color(0xFFD4FF3A).withValues(alpha: 0.0),
          const Color(0xFFD4FF3A).withValues(alpha: 0.0),
        ],
        [0.0, 0.28, 1.0],
        TileMode.clamp,
        -math.pi / 2,
        -math.pi / 2 + math.pi * 2,
      );
    canvas.drawCircle(c, 69, sweepPaint);

    // Concentric rings
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    p.color = const Color(0xFFD4FF3A).withValues(alpha: 0.07);
    canvas.drawCircle(c, 69, p);

    p.color = const Color(0xFFD4FF3A).withValues(alpha: 0.06);
    canvas.drawCircle(c, 48, p);

    p.color = const Color(0xFFD4FF3A).withValues(alpha: 0.13);
    canvas.drawCircle(c, 26, p);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}

// ── Row style enum ─────────────────────────────────────────────────────────
enum _RowStyle { gold, you, normal, dim }

// ── Rank row ───────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final String rankLabel, name, pct;
  final _RowStyle style;

  const _RankRow({
    required this.rankLabel,
    required this.name,
    required this.pct,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isYou = style == _RowStyle.you;
    final isGold = style == _RowStyle.gold;
    final isDim = style == _RowStyle.dim;

    final rankColor = isGold
        ? const Color(0xFFFFD700)
        : isYou
            ? AppTheme.voltLime
            : AppTheme.ink3;

    final nameColor = isGold
        ? Colors.white
        : isYou
            ? AppTheme.voltLime
            : isDim
                ? AppTheme.ink3
                : AppTheme.ink2;

    final pctColor = isGold
        ? const Color(0xFFFFD700)
        : isYou
            ? AppTheme.voltLime
            : AppTheme.ink3;

    final avatarBg = isGold
        ? const Color(0xFFFFD700).withValues(alpha: 0.12)
        : isYou
            ? AppTheme.voltLime.withValues(alpha: 0.15)
            : AppTheme.surface2;

    final avatarColor = isGold
        ? const Color(0xFFFFD700)
        : isYou
            ? AppTheme.voltLime
            : AppTheme.ink2;

    return Opacity(
      opacity: isDim ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: isYou
              ? AppTheme.voltLime.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isYou
                ? AppTheme.voltLime.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
        ),
        child: Row(children: [
          SizedBox(
            width: 38,
            child: Text(rankLabel,
                style: AppTheme.bigNum(12, color: rankColor),
                overflow: TextOverflow.visible,
                softWrap: false),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: avatarBg),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTheme.label(9, color: avatarColor)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(name,
                style: AppTheme.label(10, color: nameColor)
                    .copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Text(pct,
              style: AppTheme.bigNum(11, color: pctColor)),
        ]),
      ),
    );
  }
}

// ── Cutoff divider ─────────────────────────────────────────────────────────
class _CutoffDivider extends StatelessWidget {
  final String label;
  const _CutoffDivider({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 1,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.28))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: AppTheme.label(6.5, color: const Color(0xFFEF4444))
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
              child: Container(
                  height: 1,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.28))),
        ]),
      );
}
