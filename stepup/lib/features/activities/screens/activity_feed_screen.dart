import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/health_data_provider.dart';
import '../../steps/step_sync_service.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(healthDaySummaryProvider(selectedDate));
    final workoutsAsync = ref.watch(healthWorkoutsProvider(selectedDate));
    final loggedAsync = ref.watch(loggedActivitiesProvider(selectedDate));
    final isToday = _isToday(selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Activity', style: AppTheme.bigNum(26)),
                ]),
                // Date navigator
                Row(children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(selectedDateProvider.notifier)
                        .setDate(selectedDate.subtract(const Duration(days: 1))),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 22),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      isToday ? 'Today' : _fmtDate(selectedDate),
                      style: AppTheme.label(12, color: AppTheme.ink2)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: isToday
                        ? null
                        : () => ref
                            .read(selectedDateProvider.notifier)
                            .setDate(
                                selectedDate.add(const Duration(days: 1))),
                    child: Icon(Icons.chevron_right_rounded,
                        color: isToday ? AppTheme.ink3 : Colors.white,
                        size: 22),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Steps + pct chips
          summaryAsync.when(
            loading: () => const SizedBox(height: 36),
            error: (_, __) => const SizedBox(height: 36),
            data: (s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _StepChip(steps: s.steps),
                const SizedBox(width: 8),
                _PctChip(pct: (s.steps / 10000 * 100).clamp(0, 999).round()),
                const SizedBox(width: 8),
                _MiniChip(icon: Icons.local_fire_department_rounded,
                    label: '${s.calories} kcal', color: AppTheme.amber),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // TIMELINE label
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SectionLabel(label: 'TIMELINE'),
            ),
          ),
          const SizedBox(height: 8),

          // Feed list
          Expanded(
            child: _buildFeed(workoutsAsync, loggedAsync, context, ref),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeed(
    AsyncValue<List<HealthWorkout>> workoutsAsync,
    AsyncValue<List<Map<String, dynamic>>> loggedAsync,
    BuildContext context,
    WidgetRef ref,
  ) {
    final workouts = workoutsAsync.whenOrNull(data: (w) => w) ?? [];
    final logged = loggedAsync.whenOrNull(data: (l) => l) ?? [];
    final loading = workoutsAsync.isLoading || loggedAsync.isLoading;

    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.voltLime));
    }

    // Merge and sort by time
    final items = <_FeedEntry>[];

    for (final w in workouts) {
      items.add(_FeedEntry(
        time: w.startTime,
        icon: _workoutIcon(w.type),
        title: _workoutLabel(w.type),
        sub: '${w.durationMins} min${w.distanceKm > 0 ? ' · ${w.distanceKm.toStringAsFixed(1)} km' : ''}',
        color: _workoutColor(w.type),
        coinBadge: null,
        source: 'health',
        workout: w,
      ));
    }

    for (final a in logged) {
      final type = a['activity_type'] as String? ?? '';
      final dur = a['duration_minutes'] as int? ?? 0;
      final cal = a['calories_burned'] as int? ?? 0;
      final loggedAt = a['logged_at'] != null
          ? DateTime.tryParse(a['logged_at'] as String) ?? DateTime.now()
          : DateTime.now();
      items.add(_FeedEntry(
        time: loggedAt,
        icon: _activityIcon(type),
        title: _activityLabel(type),
        sub: '$dur min${cal > 0 ? ' · $cal kcal' : ''}',
        color: _workoutColor(type),
        coinBadge: null,
        source: 'app',
        workout: null,
      ));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏃', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('No activities recorded',
              style: AppTheme.label(14, color: AppTheme.ink2)),
          const SizedBox(height: 6),
          Text('Workouts from Health app appear here automatically',
              style: AppTheme.label(11, color: AppTheme.ink2),
              textAlign: TextAlign.center),
        ]),
      );
    }

    items.sort((a, b) => a.time.compareTo(b.time));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final entry = items[i];
        return _FeedRow(
          entry: entry,
          onTap: entry.source == 'health' && entry.workout != null
              ? () {
                  ref.read(selectedWorkoutProvider.notifier).select(entry.workout!);
                  context.push('/activities/workout');
                }
              : null,
        );
      },
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

  static IconData _workoutIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return Icons.directions_run_rounded;
    if (t.contains('walk')) return Icons.directions_walk_rounded;
    if (t.contains('cycl') || t.contains('bike')) return Icons.directions_bike_rounded;
    if (t.contains('swim')) return Icons.pool_rounded;
    if (t.contains('yoga') || t.contains('mindful')) return Icons.self_improvement_rounded;
    if (t.contains('gym') || t.contains('strength') || t.contains('functional') || t.contains('traditional_strength')) return Icons.fitness_center_rounded;
    if (t.contains('hiit') || t.contains('interval')) return Icons.flash_on_rounded;
    if (t.contains('sport') || t.contains('soccer') || t.contains('basketball')) return Icons.sports_rounded;
    return Icons.directions_walk_rounded;
  }

  static IconData _activityIcon(String type) => _workoutIcon(type);

  static String _workoutLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('traditional_strength') || t.contains('strength_training')) return 'Strength training';
    if (t.contains('functional_strength')) return 'Functional training';
    if (t.contains('high_intensity')) return 'HIIT';
    if (t.contains('running')) return 'Run';
    if (t.contains('walking')) return 'Walk';
    if (t.contains('cycling')) return 'Cycling';
    if (t.contains('swimming')) return 'Swimming';
    if (t.contains('yoga')) return 'Yoga';
    if (t.contains('mindfulness') || t.contains('mind_and_body')) return 'Mindfulness';
    return type.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  static String _activityLabel(String type) => _workoutLabel(type);

  static Color _workoutColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('yoga') || t.contains('mindful')) return const Color(0xFF818CF8);
    if (t.contains('run')) return AppTheme.voltLime;
    if (t.contains('walk')) return AppTheme.voltLime;
    if (t.contains('cycl')) return const Color(0xFF38BDF8);
    if (t.contains('swim')) return const Color(0xFF38BDF8);
    return AppTheme.amber;
  }
}

class _FeedEntry {
  final DateTime time;
  final IconData icon;
  final String title, sub;
  final Color color;
  final String? coinBadge;
  final String source;
  final HealthWorkout? workout;
  const _FeedEntry({
    required this.time,
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.coinBadge,
    required this.source,
    required this.workout,
  });
}

class _StepChip extends StatelessWidget {
  final int steps;
  const _StepChip({required this.steps});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.voltLime.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppTheme.voltLime.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bolt_rounded, color: AppTheme.voltLime, size: 13),
          const SizedBox(width: 4),
          Text('${_fmt(steps)} Steps',
              style: AppTheme.label(12, color: AppTheme.voltLime)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
      );

  static String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _PctChip extends StatelessWidget {
  final int pct;
  const _PctChip({required this.pct});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.arrow_upward_rounded,
              color: AppTheme.voltLime, size: 11),
          const SizedBox(width: 3),
          Text('$pct%',
              style: AppTheme.label(11, color: AppTheme.voltLime)
                  .copyWith(fontWeight: FontWeight.w600)),
        ]),
      );
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(label,
              style: AppTheme.label(11, color: color)
                  .copyWith(fontWeight: FontWeight.w600)),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTheme.label(10, color: AppTheme.ink2)
          .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700));
}

class _FeedRow extends StatelessWidget {
  final _FeedEntry entry;
  final VoidCallback? onTap;
  const _FeedRow({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Time
            SizedBox(
              width: 58,
              child: Text(_fmtTime(entry.time),
                  style: AppTheme.label(11, color: AppTheme.ink2)
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
            // Icon circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: entry.color.withValues(alpha: 0.35)),
              ),
              child: Center(child: Icon(entry.icon, color: entry.color, size: 15)),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(entry.title,
                        style: AppTheme.label(13, color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (entry.source == 'health')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Health',
                          style: AppTheme.label(8, color: AppTheme.ink2)),
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.ink2, size: 14),
                  ],
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Text(entry.sub,
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                  if (entry.coinBadge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(entry.coinBadge!,
                          style: AppTheme.label(9, color: AppTheme.amber)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      );

  static String _fmtTime(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $amPm';
  }
}
