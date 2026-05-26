import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/health_data_provider.dart';
import '../../steps/step_sync_service.dart';

class StatsGridScreen extends ConsumerWidget {
  const StatsGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(healthDaySummaryProvider(selectedDate));
    final weekAsync = ref.watch(weekStepsProvider);
    final isToday = _isToday(selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 22),
                      ),
                      Text(isToday ? 'Today' : _formatDate(selectedDate),
                          style: AppTheme.label(13, color: AppTheme.ink2)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title + date navigator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isToday ? 'Today' : _formatShort(selectedDate),
                          style: AppTheme.bigNum(32)),
                      _DateNav(
                        date: selectedDate,
                        onPrev: () => ref
                            .read(selectedDateProvider.notifier)
                            .setDate(selectedDate.subtract(const Duration(days: 1))),
                        onNext: isToday
                            ? null
                            : () => ref
                                .read(selectedDateProvider.notifier)
                                .setDate(selectedDate.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Big step card
                  summaryAsync.when(
                    loading: () => const _StepCardSkeleton(),
                    error: (_, __) => const _StepCardSkeleton(),
                    data: (s) => _StepCard(summary: s),
                  ),
                  const SizedBox(height: 12),

                  // 2×2 grid
                  summaryAsync.when(
                    loading: () => _StatGrid(
                        dist: '—', kcal: '—', mins: '—', floors: '—'),
                    error: (_, __) =>
                        _StatGrid(dist: '—', kcal: '—', mins: '—', floors: '—'),
                    data: (s) => _StatGrid(
                      dist: '${s.distanceKm.toStringAsFixed(1)} km',
                      kcal: '${s.calories}',
                      mins: '${s.activeMins}',
                      floors: '${s.floors}',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // This week header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('This week',
                          style: AppTheme.label(13, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => context.push('/activities/feed'),
                        child: Text('Activity feed →',
                            style: AppTheme.label(12, color: AppTheme.voltLime)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Week chart
                  weekAsync.when(
                    loading: () => const _WeekChartSkeleton(),
                    error: (_, __) => const _WeekChartSkeleton(),
                    data: (steps) => _WeekChart(
                      weekSteps: steps,
                      goal: 10000,
                      selectedDayIndex: selectedDate.weekday - 1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Log session CTA
                  GestureDetector(
                    onTap: () => context.push('/activities/log'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.amber.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text('+ Log a session',
                            style: AppTheme.label(14, color: AppTheme.amber)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
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

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _formatShort(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _DateNav extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _DateNav({required this.date, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) => Row(children: [
        GestureDetector(
          onTap: onPrev,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onNext,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: onNext != null ? AppTheme.surface : AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(Icons.chevron_right_rounded,
                color: onNext != null ? Colors.white : AppTheme.ink3,
                size: 18),
          ),
        ),
      ]);
}

class _StepCard extends StatelessWidget {
  final HealthDaySummary summary;
  const _StepCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    const goal = 10000;
    final pct = (summary.steps / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.voltLime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt_rounded, color: AppTheme.voltLime, size: 16),
          const SizedBox(width: 4),
          Text('Steps', style: AppTheme.label(12, color: AppTheme.ink2)),
        ]),
        const SizedBox(height: 6),
        Text(_fmt(summary.steps),
            style: AppTheme.bigNum(52, color: AppTheme.voltLime)),
        const SizedBox(height: 4),
        Text('${(pct * 100).round()}% of ${_fmt(goal)} goal',
            style: AppTheme.label(11, color: AppTheme.ink2)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
          ),
        ),
      ]),
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _StepCardSkeleton extends StatelessWidget {
  const _StepCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppTheme.voltLime, strokeWidth: 2),
        ),
      );
}

class _StatGrid extends StatelessWidget {
  final String dist, kcal, mins, floors;
  const _StatGrid(
      {required this.dist,
      required this.kcal,
      required this.mins,
      required this.floors});

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(
              child: _Tile(
                  label: 'Distance',
                  value: dist,
                  icon: Icons.directions_walk_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _Tile(
                  label: 'Calories',
                  value: kcal,
                  icon: Icons.local_fire_department_rounded,
                  accent: AppTheme.amber)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _Tile(
                  label: 'Active min',
                  value: mins,
                  icon: Icons.timer_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _Tile(
                  label: 'Floors',
                  value: floors,
                  icon: Icons.stairs_rounded)),
        ]),
      ]);
}

class _Tile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? accent;
  const _Tile(
      {required this.label,
      required this.value,
      required this.icon,
      this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.voltLime;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(value, style: AppTheme.bigNum(26, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.label(11, color: AppTheme.ink2)),
      ]),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<int> weekSteps;
  final int goal, selectedDayIndex;
  const _WeekChart(
      {required this.weekSteps,
      required this.goal,
      required this.selectedDayIndex});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final steps = i < weekSteps.length ? weekSteps[i] : 0;
        final pct = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
        final isFuture = i > todayIndex;
        final isSelected = i == selectedDayIndex;
        final isToday = i == todayIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(children: [
              if (steps > 0 && !isFuture)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(_fmtK(steps),
                      style: AppTheme.label(8, color: AppTheme.ink2),
                      textAlign: TextAlign.center),
                ),
              Container(
                height: 60,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: isFuture ? 4 : (pct * 60).clamp(4.0, 60.0),
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.white.withValues(alpha: 0.05)
                        : isSelected || isToday
                            ? AppTheme.voltLime
                            : AppTheme.voltLime.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(
                            color: AppTheme.voltLime, width: 1.5)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(days[i],
                  style: AppTheme.label(11,
                          color: isToday ? Colors.white : AppTheme.ink2)
                      .copyWith(
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400)),
            ]),
          ),
        );
      }),
    );
  }

  static String _fmtK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _WeekChartSkeleton extends StatelessWidget {
  const _WeekChartSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
