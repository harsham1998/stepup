import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/activities_provider.dart';
import '../../../core/theme.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(activitiesSummaryProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activities', style: AppTheme.bigNum(26)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text('Today', style: AppTheme.label(12, color: AppTheme.ink2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Tap a category to log', style: AppTheme.label(13, color: AppTheme.ink2)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: summaryAsync.when(
              loading: () => _ActivityList(summary: {}),
              error: (_, __) => _ActivityList(summary: {}),
              data: (summary) => _ActivityList(summary: summary),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _ActivityList({required this.summary});

  static const _activities = [
    ['Walking', 'walk', Icons.directions_walk_rounded],
    ['Gym', 'gym', Icons.fitness_center_rounded],
    ['Yoga', 'yoga', Icons.self_improvement_rounded],
    ['Running', 'run', Icons.directions_run_rounded],
    ['Sport', 'sport', Icons.sports_rounded],
    ['Cycling', 'cycle', Icons.directions_bike_rounded],
    ['Mindfulness', 'mindfulness', Icons.spa_rounded],
  ];

  String _subLabel(String type, Map<String, dynamic> summary) {
    final data = summary[type] as Map<String, dynamic>?;
    if (data == null) return 'Not logged';
    final sessions = data['sessions'] as int;
    final duration = data['duration'] as int;
    if (sessions == 0) return 'Not logged';
    return '$sessions session${sessions > 1 ? 's' : ''} · $duration min';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final name = _activities[i][0] as String;
        final type = _activities[i][1] as String;
        final icon = _activities[i][2] as IconData;
        final logged = summary.containsKey(type) &&
            (summary[type] as Map<String, dynamic>)['sessions'] as int > 0;
        return GestureDetector(
          onTap: () => context.push('/activities/log?type=$type'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: logged
                  ? AppTheme.voltLime.withValues(alpha: 0.06)
                  : AppTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: logged
                    ? AppTheme.voltLime.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: logged
                      ? AppTheme.voltLime.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: logged ? AppTheme.voltLime : AppTheme.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTheme.label(14, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_subLabel(type, summary),
                        style: AppTheme.label(11, color: AppTheme.ink2)),
                  ],
                ),
              ),
              Icon(
                logged ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                color: logged ? AppTheme.voltLime : AppTheme.ink3,
                size: 20,
              ),
            ]),
          ),
        );
      },
    );
  }
}
