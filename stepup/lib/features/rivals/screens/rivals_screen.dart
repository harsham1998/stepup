import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rivals_provider.dart';
import '../../../shared/models/rival.dart';
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rivals', style: AppTheme.bigNum(28)),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_rounded,
                            size: 16, color: AppTheme.voltLime),
                        label: Text('Add Rival',
                            style: AppTheme.label(12,
                                color: AppTheme.voltLime)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.voltLime),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Active battles
                  battlesAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (battles) {
                      final active = battles
                          .where((b) => b.status == 'active')
                          .toList();
                      if (active.isEmpty) return const SizedBox();
                      return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTIVE BATTLES',
                              style: AppTheme.label(10,
                                      color: AppTheme.ink3)
                                  .copyWith(
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            ...active.map(
                                (b) => _BattleCard(battle: b)),
                            const SizedBox(height: 20),
                          ]);
                    },
                  ),

                  Text(
                    'YOUR RIVALS',
                    style: AppTheme.label(10, color: AppTheme.ink3)
                        .copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  rivalsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.voltLime)),
                    error: (e, _) => Text('$e',
                        style: const TextStyle(color: Colors.white)),
                    data: (rivals) => rivals.isEmpty
                        ? _EmptyRivals()
                        : Column(
                            children: rivals
                                .map((r) => _RivalCard(rival: r))
                                .toList()),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  final Battle battle;
  const _BattleCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final total =
        battle.challengerSteps + battle.opponentSteps;
    final challPct =
        total > 0 ? battle.challengerSteps / total : 0.5;
    final daysLeft = battle.endTime != null
        ? battle.endTime!.difference(DateTime.now()).inDays
        : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.voltLime.withOpacity(0.1),
          AppTheme.surface
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.voltLime.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BattleUser(
              name: battle.challengerName,
              steps: battle.challengerSteps,
              isLeading: battle.challengerSteps >=
                  battle.opponentSteps,
            ),
            Column(children: [
              Text('VS',
                  style: AppTheme.bigNum(18,
                      color: AppTheme.voltLime)),
              const SizedBox(height: 2),
              Text('$daysLeft days left',
                  style: AppTheme.label(10)),
            ]),
            _BattleUser(
              name: battle.opponentName,
              steps: battle.opponentSteps,
              isLeading: battle.opponentSteps >
                  battle.challengerSteps,
              reverse: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: challPct,
            minHeight: 6,
            backgroundColor: AppTheme.amber.withOpacity(0.4),
            valueColor:
                const AlwaysStoppedAnimation(AppTheme.voltLime),
          ),
        ),
      ]),
    );
  }
}

class _BattleUser extends StatelessWidget {
  final String name;
  final int steps;
  final bool isLeading;
  final bool reverse;
  const _BattleUser({
    required this.name,
    required this.steps,
    required this.isLeading,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: reverse
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTheme.label(12,
                    color: isLeading
                        ? AppTheme.voltLime
                        : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            _fmt(steps),
            style: AppTheme.bigNum(20,
                color: isLeading ? AppTheme.voltLime : Colors.white),
          ),
          Text('steps', style: AppTheme.label(10)),
        ],
      );

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},');
}

class _RivalCard extends StatelessWidget {
  final Rival rival;
  const _RivalCard({required this.rival});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface2,
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Text(
              rival.name.isNotEmpty
                  ? rival.name[0].toUpperCase()
                  : '?',
              style: AppTheme.bigNum(18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rival.name,
                  style: AppTheme.label(14, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_fmt(rival.weekSteps)} steps this week  •  🔥 ${rival.streakDays}',
                  style: AppTheme.label(11),
                ),
              ]),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.voltLime,
            foregroundColor: AppTheme.bg,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            'Battle',
            style: AppTheme.label(11, color: AppTheme.bg)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},');
}

class _EmptyRivals extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          const Icon(Icons.people_outline_rounded,
              color: AppTheme.ink3, size: 48),
          const SizedBox(height: 12),
          Text('No rivals yet',
              style: AppTheme.label(16, color: AppTheme.ink2)),
          const SizedBox(height: 4),
          Text('Add rivals to compete in weekly battles',
              style: AppTheme.label(12)),
        ]),
      );
}
