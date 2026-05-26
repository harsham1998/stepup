import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/health_data_provider.dart' show healthCategoryProvider, healthDaySummaryProvider, selectedDateProvider, CategoryStats;
import '../../../core/theme.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final catAsync = ref.watch(healthCategoryProvider(selectedDate));
    final summaryAsync = ref.watch(healthDaySummaryProvider(selectedDate));
    final isToday = _isToday(selectedDate);

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
                Row(children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(selectedDateProvider.notifier)
                        .setDate(selectedDate.subtract(const Duration(days: 1))),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      isToday ? 'Today' : _fmtDate(selectedDate),
                      style: AppTheme.label(12, color: AppTheme.ink2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: isToday
                        ? null
                        : () => ref
                            .read(selectedDateProvider.notifier)
                            .setDate(selectedDate.add(const Duration(days: 1))),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(Icons.chevron_right_rounded,
                          color: isToday ? AppTheme.ink3 : Colors.white,
                          size: 16),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Summary strip (steps + calories + active)
          summaryAsync.when(
            loading: () => const SizedBox(height: 32),
            error: (_, __) => const SizedBox(height: 32),
            data: (s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _SummaryChip(
                  icon: Icons.bolt_rounded,
                  label: _fmtSteps(s.steps),
                  sub: 'steps',
                  color: AppTheme.voltLime,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${s.calories}',
                  sub: 'kcal',
                  color: AppTheme.amber,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  icon: Icons.timer_rounded,
                  label: '${s.activeMins}',
                  sub: 'min',
                  color: const Color(0xFF38BDF8),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Activity feed button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => context.push('/activities/feed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.timeline_rounded,
                          color: AppTheme.voltLime, size: 15),
                      const SizedBox(width: 8),
                      Text('View activity timeline',
                          style: AppTheme.label(13, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ]),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppTheme.ink2, size: 15),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SectionLabel('ACTIVITY BREAKDOWN'),
            ),
          ),
          const SizedBox(height: 10),

          // Category list
          Expanded(
            child: catAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.voltLime)),
              error: (_, __) => _CategoryList(categories: const {}),
              data: (cats) => _CategoryList(categories: cats),
            ),
          ),
        ]),
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _fmtSteps(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _CategoryList extends StatelessWidget {
  final Map<String, CategoryStats> categories;
  const _CategoryList({required this.categories});

  static const _defs = [
    ['Walking', 'walk', Icons.directions_walk_rounded, 0xFFD4FF3A],
    ['Running', 'run', Icons.directions_run_rounded, 0xFFD4FF3A],
    ['Gym', 'gym', Icons.fitness_center_rounded, 0xFFFFB547],
    ['Yoga', 'yoga', Icons.self_improvement_rounded, 0xFF818CF8],
    ['Cycling', 'cycle', Icons.directions_bike_rounded, 0xFF38BDF8],
    ['Swimming', 'swim', Icons.pool_rounded, 0xFF38BDF8],
    ['Sport', 'sport', Icons.sports_rounded, 0xFFFFB547],
    ['Other', 'other', Icons.directions_walk_rounded, 0xFF9AA3AD],
  ];

  @override
  Widget build(BuildContext context) {
    final active = _defs.where((d) => categories.containsKey(d[1])).toList();
    final inactive = _defs.where((d) => !categories.containsKey(d[1])).toList();
    final all = [...active, ...inactive];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final def = all[i];
        final name = def[0] as String;
        final key = def[1] as String;
        final icon = def[2] as IconData;
        final colorVal = def[3] as int;
        final color = Color(colorVal);
        final stats = categories[key];
        final hasData = stats != null;

        String sub;
        if (stats != null) {
          if (key == 'walk' && stats.steps > 0) {
            sub = '${_fmtSteps(stats.steps)} steps'
                '${stats.totalKm > 0 ? ' · ${stats.totalKm.toStringAsFixed(1)} km' : ''}';
          } else {
            sub = '${stats.sessions} session${stats.sessions != 1 ? 's' : ''} · ${stats.totalMins} min';
          }
        } else {
          sub = 'No data';
        }

        return GestureDetector(
          onTap: hasData ? () => context.push('/activities/feed') : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasData
                  ? color.withValues(alpha: 0.06)
                  : AppTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasData
                    ? color.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasData
                      ? color.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: hasData ? color : AppTheme.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTheme.label(14, color: hasData ? Colors.white : AppTheme.ink2)
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(sub, style: AppTheme.label(11, color: AppTheme.ink2)),
                  ],
                ),
              ),
              if (hasData)
                Icon(Icons.chevron_right_rounded,
                    color: color.withValues(alpha: 0.7), size: 18)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('—',
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                ),
            ]),
          ),
        );
      },
    );
  }

  static String _fmtSteps(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: AppTheme.label(12, color: color)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          Text(sub, style: AppTheme.label(10, color: AppTheme.ink2)),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTheme.label(10, color: AppTheme.ink2)
          .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700));
}
