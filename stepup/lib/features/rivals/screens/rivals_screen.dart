import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/rivals_provider.dart';
import '../../../core/theme.dart';

class RivalsScreen extends ConsumerWidget {
  const RivalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rivalsAsync = ref.watch(rivalsProvider);
    final battlesAsync = ref.watch(battlesProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rivals', style: AppTheme.bigNum(28)),
                const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text('Compete head-to-head this week',
                style: AppTheme.label(13, color: AppTheme.ink2)),
            const SizedBox(height: 12),

            // Active battle card
            battlesAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => _MockActiveBattle(),
              data: (battles) {
                final active = battles.where((b) => b.status == 'active').toList();
                if (active.isEmpty) return _MockActiveBattle();
                final b = active.first;
                final daysLeft = b.endTime != null
                    ? b.endTime!.difference(DateTime.now()).inDays
                    : 0;
                return _ActiveBattleCard(
                  yourName: b.challengerName,
                  yourSteps: b.challengerSteps,
                  opponentName: b.opponentName,
                  opponentSteps: b.opponentSteps,
                  timeLeft: '${daysLeft}d left',
                  onTap: () => context.push('/rivals/battle/${b.id}'),
                );
              },
            ),
            const SizedBox(height: 16),

            Text('YOUR RIVALS',
                style: AppTheme.label(10, color: AppTheme.ink2)
                    .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            rivalsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (_, __) => _MockRivalsList(),
              data: (rivals) => rivals.isEmpty
                  ? _MockRivalsList()
                  : Column(
                      children: rivals.map((r) {
                        return _RivalRow(
                          name: r.name,
                          sub: '${_fmt(r.weekSteps)} steps this week',
                          status: 'View stats',
                          statusKind: 'neutral',
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),

            // Find a rival CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12),
                    style: BorderStyle.solid),
              ),
              child: Row(children: [
                const Icon(Icons.sports_kabaddi_rounded,
                    color: AppTheme.voltLime, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Find a rival',
                        style: AppTheme.label(13, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Match with someone your level for a weekly battle',
                        style: AppTheme.label(11, color: AppTheme.ink2)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _ActiveBattleCard extends StatelessWidget {
  final String yourName, opponentName, timeLeft;
  final int yourSteps, opponentSteps;
  final VoidCallback onTap;
  const _ActiveBattleCard({
    required this.yourName,
    required this.yourSteps,
    required this.opponentName,
    required this.opponentSteps,
    required this.timeLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.voltLime.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('LIVE BATTLE',
                  style: AppTheme.label(10, color: AppTheme.voltLime)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(timeLeft, style: AppTheme.label(11, color: AppTheme.ink2)),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          // You
          Expanded(
            child: Column(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.voltLime.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    yourName.isNotEmpty ? yourName[0].toUpperCase() : 'Y',
                    style: AppTheme.bigNum(20, color: AppTheme.voltLime),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('You', style: AppTheme.label(12, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
              Text(_fmtK(yourSteps),
                  style: AppTheme.bigNum(24, color: AppTheme.voltLime)),
            ]),
          ),
          Text('VS',
              style: AppTheme.bigNum(18, color: AppTheme.ink3)),
          Expanded(
            child: Column(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Center(
                  child: Text(
                    opponentName.isNotEmpty ? opponentName[0].toUpperCase() : '?',
                    style: AppTheme.bigNum(20),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(opponentName, style: AppTheme.label(12, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
              Text(_fmtK(opponentSteps), style: AppTheme.bigNum(24)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.voltLime,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('View battle →',
                  style: AppTheme.label(13, color: AppTheme.bg)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  static String _fmtK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _MockActiveBattle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ActiveBattleCard(
        yourName: 'Riya',
        yourSteps: 4200,
        opponentName: 'Aarav',
        opponentSteps: 3800,
        timeLeft: '2d 14h left',
        onTap: () => context.push('/rivals/battle/demo'),
      );
}

class _RivalRow extends StatelessWidget {
  final String name, sub, status, statusKind;
  const _RivalRow({
    required this.name,
    required this.sub,
    required this.status,
    required this.statusKind,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = statusKind == 'win'
        ? AppTheme.voltLime
        : statusKind == 'lose'
            ? const Color(0xFFC97B4E)
            : AppTheme.ink2;
    final statusBg = statusKind == 'win'
        ? AppTheme.voltLime.withValues(alpha: 0.12)
        : statusKind == 'lose'
            ? const Color(0xFFC97B4E).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTheme.label(14, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTheme.label(13, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600)),
            Text(sub, style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status,
              style: AppTheme.label(11, color: statusColor)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _MockRivalsList extends StatelessWidget {
  static const _rows = [
    ['Priya S', '12d streak', 'You lead +840', 'win'],
    ['Karthik N', 'Gold II', 'Behind by 220', 'lose'],
    ['Megha T', 'Yoga master', 'Tied', 'tie'],
    ['Vikram R', 'Platinum I', 'Behind by 1.4K', 'lose'],
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: _rows
            .map((r) => _RivalRow(
                  name: r[0],
                  sub: r[1],
                  status: r[2],
                  statusKind: r[3],
                ))
            .toList(),
      );
}
