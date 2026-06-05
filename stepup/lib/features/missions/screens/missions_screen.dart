import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../providers/health_missions_provider.dart';
import '../../profile/providers/xp_level_provider.dart';
import '../../league/providers/league_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

// Tracks which health missions have been reported to the API this session.
// Server-side Redis prevents double-awarding across sessions.
final _reportedMissionsProvider = StateProvider<Set<String>>((ref) => <String>{});

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthMissionsProvider);

    // Compute hours until midnight for reset label
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final hoursLeft = midnight.difference(now).inHours;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                  async.maybeWhen(
                    data: (missions) {
                      final done = missions.where((m) => m.completed).length;
                      final total = missions.length;
                      final totalReward = missions
                          .where((m) => !m.completed)
                          .fold(0, (s, m) => s + m.coinReward);
                      return _Badge(
                        label: '$done / $total',
                        rewardLeft: totalReward,
                      );
                    },
                    orElse: () => const _Badge(label: '– / 5', rewardLeft: 70),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Daily Missions', style: AppTheme.bigNum(28)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.access_time_rounded, color: AppTheme.ink3, size: 13),
                const SizedBox(width: 5),
                async.maybeWhen(
                  data: (missions) {
                    final remaining = missions
                        .where((m) => !m.completed)
                        .fold(0, (s, m) => s + m.coinReward);
                    return Text(
                      'Resets in ${hoursLeft}h · finish all for +$remaining ¢',
                      style: AppTheme.label(12, color: AppTheme.ink2),
                    );
                  },
                  orElse: () => Text(
                    'Resets in ${hoursLeft}h · finish all for bonus',
                    style: AppTheme.label(12, color: AppTheme.ink2),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ]),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppTheme.ink3, size: 36),
                  const SizedBox(height: 8),
                  Text('Could not load health data',
                      style: AppTheme.label(13, color: AppTheme.ink2)),
                ]),
              ),
              data: (missions) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: missions.length,
                itemBuilder: (_, i) => _MissionCard(mission: missions[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final int rewardLeft;
  const _Badge({required this.label, required this.rewardLeft});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(label, style: AppTheme.label(12, color: Colors.white)
            .copyWith(fontWeight: FontWeight.w700)),
      );
}

class _MissionCard extends ConsumerWidget {
  final HealthMission mission;
  const _MissionCard({required this.mission});

  static const _icons = {
    'walk':    Icons.directions_walk_rounded,
    'gym':     Icons.fitness_center_rounded,
    'yoga':    Icons.self_improvement_rounded,
    'run':     Icons.directions_run_rounded,
    'droplet': Icons.water_drop_rounded,
    'moon':    Icons.bedtime_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = _icons[mission.activity] ?? Icons.directions_walk_rounded;
    final done = mission.completed;

    if (done) {
      final reported = ref.read(_reportedMissionsProvider);
      if (!reported.contains(mission.id)) {
        ref.read(_reportedMissionsProvider.notifier).state = {...reported, mission.id};
        Future.microtask(() async {
          try {
            await ApiClient.instance.post('/missions/health/complete', {'missionId': mission.id});
            ref.invalidate(xpLevelProvider);
            ref.invalidate(leagueStatusProvider);
            ref.invalidate(walletBalanceProvider);
          } catch (_) {}
        });
      }
    }

    final isWater = mission.id == 'water';
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.voltLime.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppTheme.voltLime.withValues(alpha: 0.55)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: done
                ? AppTheme.voltLime.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22,
              color: done ? AppTheme.voltLime : Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(mission.title,
                      style: AppTheme.label(14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text('+${mission.coinReward} ¢',
                    style: AppTheme.label(13, color: AppTheme.amber)
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: mission.progressPct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                valueColor: AlwaysStoppedAnimation(
                    done ? AppTheme.voltLime : AppTheme.amber),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              mission.progressLabel,
              style: AppTheme.label(11, color: AppTheme.ink2),
            ),
          ]),
        ),
      ]),
    );
    if (isWater) {
      return GestureDetector(
        onTap: () => context.push('/water'),
        child: card,
      );
    }
    return card;
  }
}
