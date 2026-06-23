// stepup/lib/features/gym/screens/gym_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../models/gym_plan.dart';
import '../providers/gym_provider.dart';

class GymScreen extends ConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(gymWeekProvider);
    final today = _isoToday();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.voltLime,
          backgroundColor: AppTheme.surface,
          onRefresh: () async => ref.invalidate(gymWeekProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GYM', style: AppTheme.bigNum(30)),
                  Text('Weekly Training Plan', style: AppTheme.label(13, color: AppTheme.ink2)),
                ]),
                weekAsync.maybeWhen(
                  data: (week) {
                    final totalXp = week.fold(0, (s, d) => s + d.xpAwarded);
                    final daysCompleted = week.where((d) => d.isCompleted).length;
                    return _WeekXpBadge(xp: totalXp, days: daysCompleted);
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ]),
              const SizedBox(height: 20),

              // Week day strip
              weekAsync.when(
                loading: () => const _WeekStripSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (week) => _WeekDayStrip(week: week, today: today),
              ),
              const SizedBox(height: 20),

              // Today's workout card
              weekAsync.when(
                loading: () => const _TodayCardSkeleton(),
                error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppTheme.red)),
                data: (week) {
                  final todayDay = week.firstWhere(
                    (d) => d.sessionDate == today,
                    orElse: () => week.first,
                  );
                  return _TodayWorkoutCard(day: todayDay);
                },
              ),
              const SizedBox(height: 20),

              // This week section header
              Text('THIS WEEK', style: AppTheme.label(11, color: AppTheme.ink3)),
              const SizedBox(height: 10),

              // All 7 days list
              weekAsync.when(
                loading: () => const _WeekListSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (week) => Column(
                  children: week.map((day) => _WeekDayRow(day: day)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _isoToday() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}

// ── Week XP Badge ─────────────────────────────────────────────────────────────
class _WeekXpBadge extends StatelessWidget {
  final int xp;
  final int days;
  const _WeekXpBadge({required this.xp, required this.days});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.voltLime.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.voltLime.withOpacity(0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('+$xp XP', style: AppTheme.bigNum(16, color: AppTheme.voltLime)),
      Text('$days/7 days', style: AppTheme.label(10, color: AppTheme.ink2)),
    ]),
  );
}

// ── Week Day Strip ────────────────────────────────────────────────────────────
class _WeekDayStrip extends StatelessWidget {
  final List<WeekDay> week;
  final String today;
  const _WeekDayStrip({required this.week, required this.today});

  static const _labels = ['M','T','W','T','F','S','S'];

  @override
  Widget build(BuildContext context) => Row(
    children: week.asMap().entries.map((e) {
      final day = e.value;
      final isToday = day.sessionDate == today;
      final isDone = day.isCompleted;
      final isRest = day.plan?.isRest ?? true;

      Color bg = AppTheme.surface2;
      Color border = AppTheme.border;
      Color textColor = AppTheme.ink3;

      if (isDone) { bg = AppTheme.voltLime.withOpacity(0.15); border = AppTheme.voltLime.withOpacity(0.4); textColor = AppTheme.voltLime; }
      if (isToday && !isDone) { bg = AppTheme.surface3; border = AppTheme.ink2; textColor = Colors.white; }

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_labels[e.key], style: AppTheme.label(10, color: textColor)),
            const SizedBox(height: 3),
            if (isDone)
              const Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 14)
            else if (isRest)
              const Icon(Icons.bedtime_rounded, color: AppTheme.ink3, size: 12)
            else if (isToday)
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.voltLime, shape: BoxShape.circle))
            else
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppTheme.ink3, shape: BoxShape.circle)),
          ]),
        ),
      );
    }).toList(),
  );
}

// ── Today's Workout Hero Card ─────────────────────────────────────────────────
class _TodayWorkoutCard extends StatelessWidget {
  final WeekDay day;
  const _TodayWorkoutCard({required this.day});

  // Unsplash CDN photos per plan slug — 800px wide, compressed
  static const _bgImages = <String, String>{
    'push_a':  'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
    'pull_a':  'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800&q=80',
    'legs':    'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=800&q=80',
    'push_b':  'https://images.unsplash.com/photo-1581009137042-c552e485697a?w=800&q=80',
    'pull_b':  'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&q=80',
    'cardio':  'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=80',
    'rest':    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80',
  };

  Color get _accentColor {
    final groups = day.plan?.muscleGroups ?? [];
    if (groups.contains('chest')) return AppTheme.blue;
    if (groups.contains('back')) return AppTheme.green;
    if (groups.contains('quads') || groups.contains('hamstrings')) return AppTheme.amber;
    if (groups.contains('cardio')) return AppTheme.pink;
    return AppTheme.ink2;
  }

  @override
  Widget build(BuildContext context) {
    final plan = day.plan;
    final isRest = plan?.isRest ?? true;
    final bgUrl = plan != null ? _bgImages[plan.slug] : _bgImages['rest'];

    return GestureDetector(
      onTap: isRest ? null : () => context.push('/gym/session/${day.sessionDate}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(fit: StackFit.expand, children: [

            // Background photo
            if (bgUrl != null)
              Image.network(
                bgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.surface2),
              ),

            // Dark gradient overlay — heavier at bottom for text legibility
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Accent color tint on the top-left
            Positioned(
              top: 0, left: 0, right: 0, bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accentColor.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row — TODAY tag + completed badge
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Text('TODAY', style: AppTheme.label(10, color: Colors.white)),
                    ),
                    const Spacer(),
                    if (day.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.voltLime.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.voltLime.withOpacity(0.5)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.voltLime, size: 12),
                          const SizedBox(width: 4),
                          Text('+${day.xpAwarded} XP', style: AppTheme.label(11, color: AppTheme.voltLime)),
                        ]),
                      ),
                  ]),

                  // Bottom section — name, tags, actions
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      isRest ? 'Rest & Recovery' : plan!.name,
                      style: const TextStyle(
                        fontFamily: 'BigShouldersDisplay',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isRest && plan != null) ...[
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        ...plan.muscleGroups.map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(g, style: AppTheme.label(11, color: Colors.white)),
                        )),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        _InfoChipLight(icon: Icons.fitness_center_rounded, label: '${plan.exercises.length} exercises'),
                        const SizedBox(width: 10),
                        const _InfoChipLight(icon: Icons.bolt_rounded, label: '150+ XP'),
                        const Spacer(),
                        if (!day.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.voltLime,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: AppTheme.voltLime.withOpacity(0.4), blurRadius: 12, spreadRadius: -2)],
                            ),
                            child: Text('START', style: AppTheme.bigNum(13, color: Colors.black)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text('VIEW', style: AppTheme.bigNum(13, color: Colors.white)),
                          ),
                      ]),
                    ] else ...[
                      Text('Recovery is where the gains happen.',
                        style: AppTheme.label(13, color: Colors.white.withOpacity(0.7))),
                    ],
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoChipLight extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChipLight({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: Colors.white70, size: 13),
    const SizedBox(width: 4),
    Text(label, style: AppTheme.label(12, color: Colors.white70)),
  ]);
}

// ── Week Day Row (list below today card) ──────────────────────────────────────
class _WeekDayRow extends StatelessWidget {
  final WeekDay day;
  const _WeekDayRow({required this.day});

  static const _dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  Color get _accent {
    final groups = day.plan?.muscleGroups ?? [];
    if (groups.contains('chest')) return AppTheme.blue;
    if (groups.contains('back')) return AppTheme.green;
    if (groups.contains('quads')) return AppTheme.amber;
    if (groups.contains('cardio')) return AppTheme.pink;
    return AppTheme.ink3;
  }

  @override
  Widget build(BuildContext context) {
    final plan = day.plan;
    final isRest = plan?.isRest ?? true;
    final d = DateTime.tryParse(day.sessionDate);
    final dayLabel = d != null ? _dayNames[d.weekday % 7] : '';

    return GestureDetector(
      onTap: (isRest || plan == null) ? null : () => context.push('/gym/session/${day.sessionDate}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: day.isCompleted ? AppTheme.voltLime.withOpacity(0.3) : AppTheme.border,
          ),
        ),
        child: Row(children: [
          // Day label
          SizedBox(
            width: 36,
            child: Text(dayLabel, style: AppTheme.label(13, color: AppTheme.ink2)),
          ),
          const SizedBox(width: 10),

          // Color dot
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRest ? AppTheme.ink3 : _accent,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              plan?.name ?? 'Rest Day',
              style: AppTheme.label(13, color: isRest ? AppTheme.ink3 : Colors.white),
            ),
          ),

          if (day.isCompleted)
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.voltLime, size: 14),
              const SizedBox(width: 4),
              Text('+${day.xpAwarded}', style: AppTheme.label(11, color: AppTheme.voltLime)),
            ])
          else if (!isRest && plan != null)
            const Icon(Icons.chevron_right_rounded, color: AppTheme.ink3, size: 16),
        ]),
      ),
    );
  }
}

// ── Skeletons ─────────────────────────────────────────────────────────────────
class _WeekStripSkeleton extends StatelessWidget {
  const _WeekStripSkeleton();
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(7, (_) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 52,
        decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(10)),
      ),
    )),
  );
}

class _TodayCardSkeleton extends StatelessWidget {
  const _TodayCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(18)),
  );
}

class _WeekListSkeleton extends StatelessWidget {
  const _WeekListSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(7, (_) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 48,
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
    )),
  );
}
