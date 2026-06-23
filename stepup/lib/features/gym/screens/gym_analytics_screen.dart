// stepup/lib/features/gym/screens/gym_analytics_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../models/gym_analytics.dart';
import '../models/gym_plan.dart';
import '../providers/gym_analytics_provider.dart';
import '../providers/gym_provider.dart';

class GymAnalyticsScreen extends ConsumerStatefulWidget {
  const GymAnalyticsScreen({super.key});

  @override
  ConsumerState<GymAnalyticsScreen> createState() => _GymAnalyticsScreenState();
}

class _GymAnalyticsScreenState extends ConsumerState<GymAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  PlanExercise? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(gymStatsProvider);
    final historyAsync = ref.watch(gymHistoryProvider);
    final weekAsync = ref.watch(gymWeekProvider);

    // Collect all exercises across the week for the exercise selector
    final allExercises = weekAsync.maybeWhen(
      data: (week) {
        final seen = <String>{};
        return week
          .where((d) => d.plan != null && !(d.plan!.isRest))
          .expand((d) => d.plan!.exercises)
          .where((e) => seen.add(e.id))
          .toList();
      },
      orElse: () => <PlanExercise>[],
    );

    if (_selectedExercise == null && allExercises.isNotEmpty) {
      _selectedExercise = allExercises.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ANALYTICS', style: AppTheme.bigNum(22)),
                Text('Gym Performance', style: AppTheme.label(12, color: AppTheme.ink2)),
              ]),
            ]),
          ),

          // ── Stats overview ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: statsAsync.when(
              loading: () => _StatsRowSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _StatsOverview(stats: stats),
            ),
          ),

          // ── Tabs ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppTheme.voltLime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.voltLime.withOpacity(0.4)),
                ),
                labelColor: AppTheme.voltLime,
                unselectedLabelColor: AppTheme.ink2,
                labelStyle: AppTheme.label(12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Calendar'),
                  Tab(text: 'Progress'),
                  Tab(text: 'Records'),
                ],
              ),
            ),
          ),

          // ── Tab content ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ── CALENDAR ─────────────────────────────────────────────
                RefreshIndicator(
                  color: AppTheme.voltLime,
                  backgroundColor: AppTheme.surface,
                  onRefresh: () async {
                    ref.invalidate(gymHistoryProvider);
                    ref.invalidate(gymStatsProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      historyAsync.when(
                        loading: () => _Skeleton(height: 220),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (history) => _WorkoutHeatmap(history: history),
                      ),
                      const SizedBox(height: 20),
                      historyAsync.when(
                        loading: () => _Skeleton(height: 200),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (history) => _WeeklyBarChart(history: history),
                      ),
                      const SizedBox(height: 20),
                      historyAsync.when(
                        loading: () => _Skeleton(height: 180),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (history) => _RecentSessions(history: history),
                      ),
                    ],
                  ),
                ),

                // ── PROGRESS ─────────────────────────────────────────────
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    if (allExercises.isNotEmpty) ...[
                      _SectionTitle('EXERCISE PROGRESSION'),
                      const SizedBox(height: 10),
                      _ExercisePicker(
                        exercises: allExercises,
                        selected: _selectedExercise,
                        onSelect: (e) => setState(() => _selectedExercise = e),
                      ),
                      const SizedBox(height: 14),
                      if (_selectedExercise != null)
                        _ExerciseProgressChart(exercise: _selectedExercise!),
                    ],
                  ],
                ),

                // ── RECORDS ──────────────────────────────────────────────
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    _SectionTitle('PERSONAL RECORDS'),
                    const SizedBox(height: 10),
                    if (allExercises.isNotEmpty)
                      ...allExercises.map((e) => _PRCard(exercise: e)),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Stats Overview ─────────────────────────────────────────────────────────────

class _StatsOverview extends StatelessWidget {
  final GymStats stats;
  const _StatsOverview({required this.stats});

  @override
  Widget build(BuildContext context) => Row(children: [
    _StatCard(
      label: 'WORKOUTS',
      value: '${stats.totalSessions}',
      icon: Icons.fitness_center_rounded,
      color: AppTheme.blue,
    ),
    const SizedBox(width: 8),
    _StatCard(
      label: 'GYM XP',
      value: '${stats.totalXp}',
      icon: Icons.bolt_rounded,
      color: AppTheme.voltLime,
    ),
    const SizedBox(width: 8),
    _StatCard(
      label: 'VOLUME',
      value: stats.totalVolumeKg >= 1000
        ? '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}t'
        : '${stats.totalVolumeKg}kg',
      icon: Icons.scale_rounded,
      color: AppTheme.amber,
    ),
    const SizedBox(width: 8),
    _StatCard(
      label: 'STREAK',
      value: '${stats.streak}🔥',
      icon: Icons.local_fire_department_rounded,
      color: AppTheme.pink,
    ),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 5),
        Text(value, style: AppTheme.bigNum(15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.label(8, color: AppTheme.ink3), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Workout Heatmap ────────────────────────────────────────────────────────────

class _WorkoutHeatmap extends StatelessWidget {
  final List<SessionHistoryItem> history;
  const _WorkoutHeatmap({required this.history});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final map = {for (final s in history) s.date: s};

    // Monday of 8 weeks ago
    final daysSinceMonday = now.weekday - 1; // Mon=0
    final startDate = now.subtract(Duration(days: daysSinceMonday + 49)); // 7 prior weeks + this week

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WORKOUT FREQUENCY', style: AppTheme.label(11, color: AppTheme.ink3)),
        const SizedBox(height: 4),
        Text('Last 8 weeks', style: AppTheme.label(12, color: Colors.white)),
        const SizedBox(height: 14),

        // Day-of-week labels (column headers = days, but we rotate: rows=days, cols=weeks)
        Row(children: [
          const SizedBox(width: 16),
          ...List.generate(8, (w) {
            final weekStartDate = startDate.add(Duration(days: w * 7));
            final month = _shortMonth(weekStartDate.month);
            return Expanded(child: Center(
              child: Text(
                w % 2 == 0 ? month : '',
                style: AppTheme.label(8, color: AppTheme.ink3),
              ),
            ));
          }),
        ]),
        const SizedBox(height: 6),

        // Grid: 7 rows (days), 8 columns (weeks)
        ...List.generate(7, (d) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            SizedBox(
              width: 16,
              child: Text(_dayLabels[d], style: AppTheme.label(8, color: AppTheme.ink3)),
            ),
            ...List.generate(8, (w) {
              final cellDate = startDate.add(Duration(days: w * 7 + d));
              final dateStr = '${cellDate.year}-${cellDate.month.toString().padLeft(2,'0')}-${cellDate.day.toString().padLeft(2,'0')}';
              final session = map[dateStr];
              final isFuture = cellDate.isAfter(now);
              final isCompleted = session?.completed ?? false;
              final isToday = dateStr == '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

              Color cell;
              if (isFuture) cell = AppTheme.surface3;
              else if (isCompleted) cell = AppTheme.voltLime;
              else if (session != null) cell = AppTheme.surface3; // has session, not completed
              else cell = const Color(0xFF111122);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 22,
                  decoration: BoxDecoration(
                    color: cell,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday ? Border.all(color: Colors.white.withOpacity(0.5), width: 1) : null,
                  ),
                ),
              );
            }),
          ]),
        )),

        const SizedBox(height: 10),
        // Legend
        Row(children: [
          _LegendDot(color: AppTheme.voltLime, label: 'Completed'),
          const SizedBox(width: 12),
          _LegendDot(color: AppTheme.surface3, label: 'Skipped'),
          const SizedBox(width: 12),
          _LegendDot(color: const Color(0xFF111122), label: 'Rest/Future'),
        ]),
      ]),
    );
  }

  static String _shortMonth(int m) =>
    ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: AppTheme.label(10, color: AppTheme.ink2)),
  ]);
}

// ── Weekly Bar Chart ───────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<SessionHistoryItem> history;
  const _WeeklyBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // Aggregate XP by week (last 6 complete weeks + current)
    final now = DateTime.now();
    final weekData = <String, int>{}; // weekKey → total XP

    for (final s in history) {
      if (!s.completed) continue;
      final d = DateTime.tryParse(s.date);
      if (d == null) continue;
      final weeksAgo = ((now.difference(d).inDays) / 7).floor();
      final key = 'W${weeksAgo}';
      weekData[key] = (weekData[key] ?? 0) + s.xp;
    }

    final keys = ['W7','W6','W5','W4','W3','W2','W1','W0'];
    final labels = ['7w','6w','5w','4w','3w','2w','1w','Now'];
    final values = keys.map((k) => (weekData[k] ?? 0).toDouble()).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b).clamp(100.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WEEKLY XP EARNED', style: AppTheme.label(11, color: AppTheme.ink3)),
        const SizedBox(height: 4),
        Text('Gym sessions only', style: AppTheme.label(12, color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: BarChart(BarChartData(
            maxY: maxY * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withOpacity(0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Text(labels[i], style: AppTheme.label(9, color: AppTheme.ink3));
                },
              )),
            ),
            barGroups: List.generate(values.length, (i) => BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(
                toY: values[i],
                width: 18,
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: i == 7
                    ? [AppTheme.voltLime.withOpacity(0.7), AppTheme.voltLime]
                    : [AppTheme.blue.withOpacity(0.5), AppTheme.blue],
                ),
              )],
            )),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppTheme.surface3,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '+${rod.toY.toInt()} XP',
                  AppTheme.label(11, color: AppTheme.voltLime),
                ),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

// ── Recent Sessions ────────────────────────────────────────────────────────────

class _RecentSessions extends StatelessWidget {
  final List<SessionHistoryItem> history;
  const _RecentSessions({required this.history});

  @override
  Widget build(BuildContext context) {
    final completed = history.where((s) => s.completed).toList().reversed.take(10).toList();
    if (completed.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECENT SESSIONS', style: AppTheme.label(11, color: AppTheme.ink3)),
        const SizedBox(height: 12),
        ...completed.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _slugColor(s.planSlug),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.planName, style: AppTheme.label(13, color: Colors.white)),
              Text(s.date, style: AppTheme.label(11, color: AppTheme.ink3)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('+${s.xp} XP', style: AppTheme.label(11, color: AppTheme.voltLime)),
            ),
          ]),
        )),
      ]),
    );
  }

  Color _slugColor(String slug) {
    if (slug.contains('push')) return AppTheme.blue;
    if (slug.contains('pull')) return AppTheme.green;
    if (slug.contains('leg')) return AppTheme.amber;
    if (slug.contains('cardio')) return AppTheme.pink;
    return AppTheme.ink3;
  }
}

// ── Exercise Picker ────────────────────────────────────────────────────────────

class _ExercisePicker extends StatelessWidget {
  final List<PlanExercise> exercises;
  final PlanExercise? selected;
  final void Function(PlanExercise) onSelect;
  const _ExercisePicker({required this.exercises, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: exercises.length,
      itemBuilder: (_, i) {
        final e = exercises[i];
        final isSelected = e.id == selected?.id;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.voltLime.withOpacity(0.15) : AppTheme.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.voltLime.withOpacity(0.5) : AppTheme.border,
              ),
            ),
            child: Text(e.name, style: AppTheme.label(11,
              color: isSelected ? AppTheme.voltLime : AppTheme.ink2)),
          ),
        );
      },
    ),
  );
}

// ── Exercise Progress Chart ────────────────────────────────────────────────────

class _ExerciseProgressChart extends ConsumerWidget {
  final PlanExercise exercise;
  const _ExerciseProgressChart({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(exerciseProgressionProvider(exercise.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(exercise.name, style: AppTheme.bigNum(15)),
        const SizedBox(height: 4),
        Text('Max weight per session', style: AppTheme.label(11, color: AppTheme.ink3)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 2)),
            error: (_, __) => Center(child: Text('No data yet', style: AppTheme.label(13, color: AppTheme.ink3))),
            data: (points) {
              if (points.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.show_chart_rounded, color: AppTheme.ink3, size: 32),
                  const SizedBox(height: 8),
                  Text('Log sets to see your progression', style: AppTheme.label(12, color: AppTheme.ink3)),
                ]));
              }

              final hasWeight = points.any((p) => p.maxWeightKg > 0);
              final spots = points.asMap().entries.map((e) {
                final y = hasWeight ? e.value.maxWeightKg : e.value.maxReps.toDouble();
                return FlSpot(e.key.toDouble(), y);
              }).toList();
              final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.25;
              final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.85).clamp(0.0, double.infinity);

              return LineChart(LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.06), strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      hasWeight ? '${v.toInt()}kg' : '${v.toInt()}r',
                      style: AppTheme.label(9, color: AppTheme.ink3),
                    ),
                  )),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      final d = points[i].date;
                      return Text(d.substring(5), style: AppTheme.label(8, color: AppTheme.ink3));
                    },
                  )),
                ),
                lineBarsData: [LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppTheme.voltLime,
                  barWidth: 2.5,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.voltLime.withOpacity(0.18), Colors.transparent],
                    ),
                  ),
                  dotData: FlDotData(getDotPainter: (spot, _, __, ___) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.voltLime,
                      strokeWidth: 2,
                      strokeColor: AppTheme.bg,
                    )),
                )],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surface3,
                    getTooltipItems: (spots) => spots.map((s) {
                      final i = s.spotIndex;
                      if (i >= points.length) return null;
                      final p = points[i];
                      final label = hasWeight
                        ? '${p.maxWeightKg.toStringAsFixed(1)} kg × ${p.maxReps} reps'
                        : '${p.maxReps} reps';
                      return LineTooltipItem(label, AppTheme.label(11, color: AppTheme.voltLime));
                    }).toList(),
                  ),
                ),
              ));
            },
          ),
        ),
      ]),
    );
  }
}

// ── Personal Records Card ──────────────────────────────────────────────────────

class _PRCard extends ConsumerWidget {
  final PlanExercise exercise;
  const _PRCard({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(exerciseProgressionProvider(exercise.id));

    return progressAsync.maybeWhen(
      data: (points) {
        if (points.isEmpty) return const SizedBox.shrink();
        final best = points.reduce((a, b) => a.maxWeightKg >= b.maxWeightKg ? a : b);
        if (best.maxWeightKg == 0 && best.maxReps == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            const Icon(Icons.emoji_events_rounded, color: AppTheme.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exercise.name, style: AppTheme.label(13, color: Colors.white)),
              Text(best.date, style: AppTheme.label(10, color: AppTheme.ink3)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.amber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.amber.withOpacity(0.25)),
              ),
              child: Text(
                best.maxWeightKg > 0
                  ? '${best.maxWeightKg.toStringAsFixed(1)} kg × ${best.maxReps}'
                  : '${best.maxReps} reps',
                style: AppTheme.label(12, color: AppTheme.amber),
              ),
            ),
          ]),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) =>
    Text(title, style: AppTheme.label(11, color: AppTheme.ink3));
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(14)),
  );
}

class _StatsRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: List.generate(4, (i) => Expanded(
    child: Container(
      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
      height: 76,
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
    ),
  )));
}
