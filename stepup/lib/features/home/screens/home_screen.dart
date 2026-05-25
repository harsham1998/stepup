import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../challenges/providers/challenges_provider.dart';
import '../../steps/step_sync_service.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../league/providers/league_provider.dart';
import '../../missions/providers/missions_provider.dart';
import '../providers/home_provider.dart';
import '../../../shared/models/mission.dart';
import '../../../shared/widgets/challenge_card.dart';
import '../../../core/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await StepSyncService.instance.requestPermissions();
      } catch (_) {}
    });
  }

  String _formattedDate() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(dailyStepsProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final challengesAsync = ref.watch(activeChallengesProvider);
    final leagueAsync = ref.watch(leagueStatusProvider);
    final missionsAsync = ref.watch(dailyMissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formattedDate(),
                              style:
                                  AppTheme.label(11, color: AppTheme.ink3),
                            ),
                            stepsAsync.when(
                              loading: () =>
                                  Text('StepUp', style: AppTheme.bigNum(24)),
                              error: (_, __) =>
                                  Text('StepUp', style: AppTheme.bigNum(24)),
                              data: (_) => Text('Hey there 👋',
                                  style: AppTheme.bigNum(24)),
                            ),
                          ]),
                      Row(children: [
                        // streak chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text('0d',
                                    style: AppTheme.label(12,
                                        color: AppTheme.ink2)),
                              ]),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22),
                          onPressed: () {},
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Step ring hero
                  stepsAsync.when(
                    loading: () =>
                        const _StepRingCard(steps: 0, goal: 10000),
                    error: (_, __) =>
                        const _StepRingCard(steps: 0, goal: 10000),
                    data: (steps) =>
                        _StepRingCard(steps: steps, goal: 10000),
                  ),
                  const SizedBox(height: 10),

                  // Distance / Kcal / Min chips row
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _InfoChip(label: '5.4 Km'),
                    const SizedBox(width: 8),
                    _InfoChip(label: '412 Kcal'),
                    const SizedBox(width: 8),
                    _InfoChip(label: '52 Min'),
                  ]),
                  const SizedBox(height: 16),

                  // Stats strip: league | streak | coins
                  Row(children: [
                    leagueAsync.when(
                      loading: () => _StatChip(
                          label: 'League',
                          value: '—',
                          color: AppTheme.amber),
                      error: (_, __) => _StatChip(
                          label: 'League',
                          value: 'Bronze',
                          color: AppTheme.amber),
                      data: (l) => _StatChip(
                        label: l.label,
                        value: '#${l.rankInTier}',
                        color: _parseColor(l.colorHex),
                      ),
                    ),
                    const SizedBox(width: 10),
                    walletAsync.when(
                      loading: () => _StatChip(
                          label: 'Streak',
                          value: '🔥 0',
                          color: AppTheme.voltLime),
                      error: (_, __) => _StatChip(
                          label: 'Streak',
                          value: '🔥 0',
                          color: AppTheme.voltLime),
                      data: (_) => _StatChip(
                          label: 'Streak',
                          value: '🔥 0',
                          color: AppTheme.voltLime),
                    ),
                    const SizedBox(width: 10),
                    walletAsync.when(
                      loading: () => _StatChip(
                          label: 'Coins',
                          value: '0¢',
                          color: AppTheme.amber),
                      error: (_, __) => _StatChip(
                          label: 'Coins',
                          value: '0¢',
                          color: AppTheme.amber),
                      data: (w) => _StatChip(
                        label: 'Coins',
                        value: '${w['coin_balance'] ?? 0}¢',
                        color: AppTheme.amber,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Daily missions strip
                  missionsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (missions) => missions.isEmpty
                        ? const SizedBox()
                        : _MissionsStrip(missions: missions),
                  ),

                  // Challenges header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LIVE CHALLENGES',
                        style: AppTheme.label(10, color: AppTheme.ink3)
                            .copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/challenges'),
                        child: Text('See all',
                            style: AppTheme.label(11,
                                color: AppTheme.voltLime)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Active challenges
                  challengesAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (challenges) => Column(
                      children: challenges
                          .take(3)
                          .map((c) => ChallengeCard(
                                challenge: c,
                                onTap: () =>
                                    context.push('/challenges/${c.id}'),
                              ))
                          .toList(),
                    ),
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

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppTheme.amber;
  }
}

class _StepRingCard extends StatelessWidget {
  final int steps, goal;
  const _StepRingCard({required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct = (steps / goal).clamp(0.0, 1.0);
    final remaining = goal - steps;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
        width: 130,
        height: 130,
        child: CustomPaint(
          painter: _RingPainter(pct, AppTheme.voltLime),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_fmt(steps), style: AppTheme.bigNum(28)),
                Text('steps', style: AppTheme.label(11)),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'TODAY',
            style: AppTheme.label(9, color: AppTheme.ink3)
                .copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            remaining > 0
                ? '${_fmt(remaining)} more to goal'
                : 'Goal reached!',
            style: AppTheme.label(13,
                color: remaining > 0 ? AppTheme.ink2 : AppTheme.voltLime),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
          const SizedBox(height: 8),
          Text('Goal: ${_fmt(goal)} steps',
              style: AppTheme.label(11, color: AppTheme.ink3)),
        ]),
      ),
    ]);
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    if (progress > 0) {
      final fg = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: AppTheme.bigNum(16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.label(10, color: AppTheme.ink3)),
        ]),
      );
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(label, style: AppTheme.label(12, color: AppTheme.ink2)),
      );
}

class _MissionsStrip extends StatelessWidget {
  final List<Mission> missions;
  const _MissionsStrip({required this.missions});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          'DAILY MISSIONS',
          style: AppTheme.label(10, color: AppTheme.ink3).copyWith(
              letterSpacing: 1.2, fontWeight: FontWeight.w700),
        ),
        GestureDetector(
          onTap: () => context.push('/missions'),
          child: Text('View all',
              style: AppTheme.label(11, color: AppTheme.voltLime)),
        ),
      ]),
      const SizedBox(height: 10),
      Row(
        children: missions
            .take(3)
            .map((m) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MissionPill(mission: m),
                  ),
                ))
            .toList(),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

class _MissionPill extends StatelessWidget {
  final Mission mission;
  const _MissionPill({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: mission.completed
            ? AppTheme.voltLime.withValues(alpha: 0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mission.completed
              ? AppTheme.voltLime.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          mission.title,
          style: AppTheme.label(10,
              color: mission.completed ? AppTheme.voltLime : Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: mission.progressPct,
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(
                mission.completed ? AppTheme.voltLime : AppTheme.amber),
          ),
        ),
        const SizedBox(height: 4),
        Text('+${mission.coinReward}¢',
            style: AppTheme.label(9, color: AppTheme.amber)),
      ]),
    );
  }
}
