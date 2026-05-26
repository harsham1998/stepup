import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/league_provider.dart';
import '../../../core/theme.dart';

class LeagueStandingsScreen extends ConsumerWidget {
  const LeagueStandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(leagueStandingsProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: standingsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (_, __) => const _StandingsBody(entries: [], total: 0),
          data: (data) {
            final entries = data['entries'] as List? ?? [];
            final total = data['total_in_league'] as int? ?? 0;
            return _StandingsBody(entries: entries, total: total);
          },
        ),
      ),
    );
  }
}

class _StandingsBody extends StatelessWidget {
  final List entries;
  final int total;
  const _StandingsBody({required this.entries, required this.total});

  @override
  Widget build(BuildContext context) {
    final promoteCount = total > 0 ? (total * 0.25).floor() : 0;
    final relegateStart = total > 0 ? total - (total * 0.15).floor() : 0;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(children: [
                  const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text('Back', style: AppTheme.label(13, color: AppTheme.ink2)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9A93A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('GOLD III',
                    style: AppTheme.label(10, color: const Color(0xFFD9A93A))
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Standings', style: AppTheme.bigNum(28)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.access_time_rounded,
                color: AppTheme.ink3, size: 14),
            const SizedBox(width: 6),
            Text('Resets in 4d 12h · top 25% promote · bottom 15% relegate',
                style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
          const SizedBox(height: 12),
        ]),
      ),
      Expanded(
        child: entries.isEmpty
            ? _MockStandings(promoteCount: promoteCount)
            : _LiveStandings(
                entries: entries,
                promoteCount: promoteCount,
                relegateStart: relegateStart,
              ),
      ),
    ]);
  }
}

class _LiveStandings extends StatelessWidget {
  final List entries;
  final int promoteCount, relegateStart;
  const _LiveStandings({
    required this.entries,
    required this.promoteCount,
    required this.relegateStart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i] as Map<String, dynamic>;
        final rank = (e['rank'] as num).toInt();
        final isMe = e['is_me'] as bool? ?? false;
        final name = e['name'] as String? ?? 'Unknown';
        final xp = e['xp'] as int? ?? 0;
        final inPromote = promoteCount > 0 && rank <= promoteCount;
        final inRelegate = relegateStart > 0 && rank > relegateStart;

        if (inRelegate && i > 0) {
          final prevRank = ((entries[i - 1] as Map)['rank'] as num).toInt();
          if (prevRank <= relegateStart) {
            return Column(children: [
              _CutLine('Relegation zone'),
              _StandingRow(
                rank: '#$rank', name: name, xp: '$xp XP',
                isMe: isMe, inPromote: inPromote,
              ),
            ]);
          }
        }
        return _StandingRow(
          rank: '#$rank', name: name, xp: '$xp XP',
          isMe: isMe, inPromote: inPromote,
        );
      },
    );
  }
}

class _MockStandings extends StatelessWidget {
  final int promoteCount;
  const _MockStandings({required this.promoteCount});

  static const _rows = [
    ['#1', 'Aarav M', '4,820 XP', false, true],
    ['#2', 'Sneha R', '4,610 XP', false, true],
    ['#3', 'Vikram K', '4,480 XP', false, true],
    ['#142', 'You', '1,840 XP', true, false],
    ['#143', 'Karthik N', '1,820 XP', false, false],
    ['#144', 'Priya S', '1,795 XP', false, false],
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          // You card
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppTheme.voltLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.voltLime.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text('#142',
                      style: AppTheme.bigNum(24, color: AppTheme.voltLime)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('You · Riya',
                        style: AppTheme.label(13, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text('1,840 XP this week',
                        style: AppTheme.label(11, color: AppTheme.ink2)),
                  ]),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('▲ 12',
                      style: AppTheme.label(12, color: AppTheme.voltLime)),
                  Text('since yest.',
                      style: AppTheme.label(10, color: AppTheme.ink2)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._rows.map((r) => _StandingRow(
                rank: r[0] as String,
                name: r[1] as String,
                xp: r[2] as String,
                isMe: r[3] as bool,
                inPromote: r[4] as bool,
              )),
          _CutLine('Relegation zone'),
          _StandingRow(
              rank: '#7156', name: 'Drift Zone', xp: '',
              isMe: false, inPromote: false),
        ],
      );
}

class _StandingRow extends StatelessWidget {
  final String rank, name, xp;
  final bool isMe, inPromote;
  const _StandingRow({
    required this.rank,
    required this.name,
    required this.xp,
    required this.isMe,
    required this.inPromote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.voltLime.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Text(rank,
              style: AppTheme.bigNum(16,
                  color: inPromote ? AppTheme.voltLime : AppTheme.ink3)),
        ),
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              style: AppTheme.label(13, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w500)),
        ),
        Text(xp, style: AppTheme.label(13, color: AppTheme.ink2)),
      ]),
    );
  }
}

class _CutLine extends StatelessWidget {
  final String label;
  const _CutLine(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 1,
                  color: const Color(0xFFC97B4E).withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: AppTheme.label(10, color: const Color(0xFFC97B4E))
                    .copyWith(letterSpacing: 0.6)),
          ),
          Expanded(
              child: Container(
                  height: 1,
                  color: const Color(0xFFC97B4E).withValues(alpha: 0.5))),
        ]),
      );
}
