import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/missions_provider.dart';
import '../../../shared/models/mission.dart';
import '../../../core/theme.dart';

// Type alias to avoid direct dependency on ProviderListenable which
// is not exported by default from flutter_riverpod 3.x public API.
typedef _MissionsProvider
    = FutureProvider<List<Mission>>;

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text('Missions', style: AppTheme.bigNum(26)),
                  ]),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tab,
                    labelColor: AppTheme.bg,
                    unselectedLabelColor: AppTheme.ink3,
                    labelStyle: AppTheme.label(13)
                        .copyWith(fontWeight: FontWeight.w700),
                    indicator: BoxDecoration(
                      color: AppTheme.voltLime,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Daily'),
                      Tab(text: 'Weekly'),
                      Tab(text: 'Seasonal'),
                    ],
                  ),
                ]),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MissionsList(provider: dailyMissionsProvider),
                _MissionsList(provider: weeklyMissionsProvider),
                _MissionsList(provider: seasonalMissionsProvider),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _MissionsList extends ConsumerWidget {
  final _MissionsProvider provider;
  const _MissionsList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.voltLime)),
      error: (e, _) =>
          Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
      data: (missions) => missions.isEmpty
          ? Center(
              child: Text('No missions available',
                  style: AppTheme.label(14)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              itemCount: missions.length,
              itemBuilder: (_, i) =>
                  _MissionRow(mission: missions[i]),
            ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Mission mission;
  const _MissionRow({required this.mission});

  static const _activityIcons = {
    'walk': Icons.directions_walk_rounded,
    'gym': Icons.fitness_center_rounded,
    'yoga': Icons.self_improvement_rounded,
    'run': Icons.directions_run_rounded,
    'cycle': Icons.directions_bike_rounded,
    'sport': Icons.sports_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon =
        _activityIcons[mission.activity] ?? Icons.directions_walk_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mission.completed
            ? AppTheme.voltLime.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mission.completed
              ? AppTheme.voltLime.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mission.completed
                ? AppTheme.voltLime.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            mission.completed ? Icons.check_circle_rounded : icon,
            color: mission.completed ? AppTheme.voltLime : AppTheme.ink2,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTheme.label(14, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(mission.description, style: AppTheme.label(11)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: mission.progressPct,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          mission.completed
                              ? AppTheme.voltLime
                              : AppTheme.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(mission.progressPct * 100).toInt()}%',
                    style: AppTheme.label(10),
                  ),
                ]),
              ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+${mission.coinReward}¢',
              style: AppTheme.bigNum(14, color: AppTheme.amber)),
          Text('+${mission.xpReward} XP',
              style: AppTheme.label(10, color: AppTheme.ink3)),
        ]),
      ]),
    );
  }
}
