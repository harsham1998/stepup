// stepup/lib/features/gym/screens/workout_session_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../profile/providers/xp_level_provider.dart';
import '../data/warmup_data.dart';
import '../models/gym_session.dart';
import '../providers/gym_provider.dart';
import '../widgets/exercise_session_card.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String date;
  const WorkoutSessionScreen({super.key, required this.date});

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gymSessionProvider.notifier).init(widget.date);
    });
  }

  Future<void> _completeWorkout() async {
    setState(() => _completing = true);
    try {
      final xp = await ref.read(gymSessionProvider.notifier).completeSession();
      ref.invalidate(xpLevelProvider);
      if (!mounted) return;
      await _showCompletionDialog(xp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.red),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _showCompletionDialog(int xp) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('💪', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Workout Complete!', style: AppTheme.bigNum(24)),
            const SizedBox(height: 8),
            Text('You crushed it.', style: AppTheme.label(14, color: AppTheme.ink2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withOpacity(0.15),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppTheme.voltLime.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.voltLime, size: 20),
                const SizedBox(width: 6),
                Text('+$xp XP', style: AppTheme.bigNum(20, color: AppTheme.voltLime)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: const Text('BACK TO GYM'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(gymSessionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
        error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.red))),
        data: (session) {
          if (session == null) return const Center(child: CircularProgressIndicator(color: AppTheme.voltLime));

          final plan = session.plan;
          final exercises = plan.exercises;
          final completedExercises = exercises.where((e) => session.isExerciseComplete(e.id, e.sets)).length;
          final totalSets = exercises.fold(0, (sum, e) => sum + e.sets);
          final loggedSets = session.setLogs.length.clamp(0, totalSets);
          final progress = totalSets == 0 ? 0.0 : loggedSets / totalSets;

          return SafeArea(
            child: Column(children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(plan.name, style: AppTheme.bigNum(20)),
                    Text(_formatDate(session.sessionDate), style: AppTheme.label(12, color: AppTheme.ink2)),
                  ])),
                  if (session.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.voltLime.withOpacity(0.4)),
                      ),
                      child: Text('Completed', style: AppTheme.label(11, color: AppTheme.voltLime)),
                    ),
                ]),
              ),
              const SizedBox(height: 14),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('$loggedSets / $totalSets sets · $completedExercises / ${exercises.length} exercises',
                        style: AppTheme.label(12, color: AppTheme.ink2)),
                    Text('${(progress * 100).toInt()}%',
                        style: AppTheme.label(12, color: AppTheme.voltLime)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.surface3,
                      color: AppTheme.voltLime,
                      minHeight: 6,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Exercise list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  children: [
                    if (plan.isRest)
                      _RestDayCard()
                    else if (plan.slug == 'cardio')
                      _CardioDayCard(
                        session: session,
                        onComplete: session.isCompleted ? null : _completeWorkout,
                      )
                    else ...[
                      if (workoutPhases.containsKey(plan.slug))
                        _WarmupSection(phases: workoutPhases[plan.slug]!),
                      const SizedBox(height: 8),
                      ...exercises.map((ex) => ExerciseSessionCard(
                        exercise: ex,
                        session: session,
                        sessionCompleted: session.isCompleted,
                        onLog: ref.read(gymSessionProvider.notifier).logSet,
                      )),
                      if (workoutPhases.containsKey(plan.slug)) ...[
                        const SizedBox(height: 8),
                        _CooldownSection(phases: workoutPhases[plan.slug]!),
                      ],
                    ],
                  ],
                ),
              ),
            ]),
          );
        },
      ),
      // Complete button
      bottomNavigationBar: sessionAsync.whenOrNull(data: (session) {
        if (session == null || session.isCompleted || session.plan.isRest) return null;
        final exercises = session.plan.exercises;
        final completedExercises = exercises.isEmpty
            ? 0
            : exercises.where((e) => session.isExerciseComplete(e.id, e.sets)).length;
        final allDone = session.plan.slug == 'cardio' ||
            (completedExercises == exercises.length && exercises.isNotEmpty);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _completing ? null : _completeWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allDone ? AppTheme.voltLime : AppTheme.surface2,
                  foregroundColor: allDone ? Colors.black : AppTheme.ink2,
                  side: allDone ? null : const BorderSide(color: AppTheme.border),
                ),
                child: _completing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        allDone ? 'COMPLETE WORKOUT · +150 XP' : 'FINISH EARLY',
                        style: AppTheme.bigNum(14, color: allDone ? Colors.black : AppTheme.ink2),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]}';
  }
}

// ── Warmup Section ────────────────────────────────────────────────────────────

class _WarmupSection extends StatefulWidget {
  final WorkoutPhases phases;
  const _WarmupSection({required this.phases});

  @override
  State<_WarmupSection> createState() => _WarmupSectionState();
}

class _WarmupSectionState extends State<_WarmupSection> {
  bool _expanded = true;
  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    final items = widget.phases.warmup;
    final allDone = _done.length == items.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? AppTheme.amber.withOpacity(0.4)
              : AppTheme.amber.withOpacity(0.2),
        ),
      ),
      child: Column(children: [
        // Header row
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.amber.withOpacity(0.15),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WARM UP', style: AppTheme.label(12, color: AppTheme.amber)),
                Text('${items.length} exercises · ~5 min',
                    style: AppTheme.label(11, color: AppTheme.ink3)),
              ])),
              if (allDone)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.amber, size: 18)
              else
                Text('${_done.length}/${items.length}',
                    style: AppTheme.label(11, color: AppTheme.ink3)),
              const SizedBox(width: 6),
              Icon(
                _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppTheme.ink3, size: 20,
              ),
            ]),
          ),
        ),

        // Expandable items
        if (_expanded) ...[
          const Divider(height: 1, color: AppTheme.border),
          ...items.asMap().entries.map((e) => _PhaseItem(
            index: e.key,
            item: e.value,
            isDone: _done.contains(e.key),
            accentColor: AppTheme.amber,
            onToggle: () => setState(() {
              if (_done.contains(e.key)) {
                _done.remove(e.key);
              } else {
                _done.add(e.key);
              }
            }),
          )),
        ],
      ]),
    );
  }
}

// ── Cooldown Section ──────────────────────────────────────────────────────────

class _CooldownSection extends StatefulWidget {
  final WorkoutPhases phases;
  const _CooldownSection({required this.phases});

  @override
  State<_CooldownSection> createState() => _CooldownSectionState();
}

class _CooldownSectionState extends State<_CooldownSection> {
  bool _expanded = false;
  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    final items = widget.phases.cooldown;
    final allDone = _done.length == items.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? AppTheme.blue.withOpacity(0.4)
              : AppTheme.blue.withOpacity(0.2),
        ),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.blue.withOpacity(0.15),
                ),
                child: const Center(
                  child: Text('❄️', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('COOL DOWN', style: AppTheme.label(12, color: AppTheme.blue)),
                Text('${items.length} stretches · ~8 min',
                    style: AppTheme.label(11, color: AppTheme.ink3)),
              ])),
              if (allDone)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.blue, size: 18)
              else
                Text('${_done.length}/${items.length}',
                    style: AppTheme.label(11, color: AppTheme.ink3)),
              const SizedBox(width: 6),
              Icon(
                _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppTheme.ink3, size: 20,
              ),
            ]),
          ),
        ),

        if (_expanded) ...[
          const Divider(height: 1, color: AppTheme.border),
          ...items.asMap().entries.map((e) => _PhaseItem(
            index: e.key,
            item: e.value,
            isDone: _done.contains(e.key),
            accentColor: AppTheme.blue,
            onToggle: () => setState(() {
              if (_done.contains(e.key)) {
                _done.remove(e.key);
              } else {
                _done.add(e.key);
              }
            }),
          )),
        ],
      ]),
    );
  }
}

// ── Shared phase item ─────────────────────────────────────────────────────────

class _PhaseItem extends StatelessWidget {
  final int index;
  final WarmupItem item;
  final bool isDone;
  final Color accentColor;
  final VoidCallback onToggle;

  const _PhaseItem({
    required this.index,
    required this.item,
    required this.isDone,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? accentColor : Colors.transparent,
              border: Border.all(
                color: isDone ? accentColor : AppTheme.ink3,
                width: 1.5,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 13)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              item.name,
              style: TextStyle(
                color: isDone ? AppTheme.ink2 : Colors.white,
                fontSize: 14,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(item.dosage, style: AppTheme.label(11, color: AppTheme.ink3)),
          ])),
        ]),
      ),
    );
  }
}

// ── Rest day ──────────────────────────────────────────────────────────────────

class _RestDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: [
          const Text('😴', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Rest Day', style: AppTheme.bigNum(22)),
          const SizedBox(height: 6),
          Text(
            'Recovery is where the gains happen. Rest well.',
            style: AppTheme.label(14, color: AppTheme.ink2),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

class _CardioDayCard extends StatelessWidget {
  final GymSession session;
  final VoidCallback? onComplete;
  const _CardioDayCard({required this.session, required this.onComplete});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: [
          const Text('🏃', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Cardio Day', style: AppTheme.bigNum(22)),
          const SizedBox(height: 6),
          Text(
            '30-40 min steady-state cardio.\nTreadmill, cycling or elliptical.',
            style: AppTheme.label(14, color: AppTheme.ink2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
            ),
            child: Text(
              'Complete to earn +75 XP',
              style: AppTheme.label(12, color: AppTheme.amber),
            ),
          ),
        ]),
      );
}
