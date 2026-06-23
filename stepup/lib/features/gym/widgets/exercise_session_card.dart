// stepup/lib/features/gym/widgets/exercise_session_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/gym_plan.dart';
import '../models/gym_session.dart';
import 'exercise_detail_sheet.dart';
import 'log_set_sheet.dart';

class ExerciseSessionCard extends StatelessWidget {
  final PlanExercise exercise;
  final GymSession session;
  final bool sessionCompleted;
  final Future<void> Function({
    required String exerciseId,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? durationSecs,
  }) onLog;

  const ExerciseSessionCard({
    super.key,
    required this.exercise,
    required this.session,
    required this.sessionCompleted,
    required this.onLog,
  });

  Color _muscleColor(String muscle) {
    if (['chest', 'upper-chest'].contains(muscle)) return AppTheme.blue;
    if (['lats', 'back', 'mid-back', 'upper-back', 'rear-delt'].contains(muscle)) return AppTheme.green;
    if (['quads', 'hamstrings', 'glutes', 'calves'].contains(muscle)) return AppTheme.amber;
    if (['shoulders', 'side-delt', 'front-delt'].contains(muscle)) return AppTheme.purple;
    if (['biceps', 'brachialis', 'triceps', 'long-head-triceps'].contains(muscle)) return AppTheme.pink;
    if (['core', 'abs'].contains(muscle)) return AppTheme.voltLime;
    return AppTheme.ink2;
  }

  @override
  Widget build(BuildContext context) {
    final logs = session.logsForExercise(exercise.id);
    final allDone = session.isExerciseComplete(exercise.id, exercise.sets);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allDone ? AppTheme.voltLime.withOpacity(0.4) : AppTheme.border,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(exercise.name, style: AppTheme.bigNum(15))),
                if (allDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 12),
                      const SizedBox(width: 3),
                      Text('Done', style: AppTheme.label(10, color: AppTheme.voltLime)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 4),
              Wrap(spacing: 4, runSpacing: 4, children: [
                ...exercise.targetMuscles.take(3).map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _muscleColor(m).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _muscleColor(m).withOpacity(0.3)),
                  ),
                  child: Text(m, style: AppTheme.label(10, color: _muscleColor(m))),
                )),
              ]),
            ])),
            const SizedBox(width: 8),
            // View demo button
            GestureDetector(
              onTap: () => ExerciseDetailSheet.show(context, exercise),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface3,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_circle_outline_rounded, color: AppTheme.ink2, size: 14),
                  const SizedBox(width: 4),
                  Text('View', style: AppTheme.label(11, color: AppTheme.ink2)),
                ]),
              ),
            ),
          ]),
        ),

        // Set rows
        ...List.generate(exercise.sets, (i) {
          final setNum = i + 1;
          final log = logs.where((l) => l.setNumber == setNum).firstOrNull;
          final isLogged = log != null;

          return GestureDetector(
            onTap: sessionCompleted
                ? null
                : () => LogSetSheet.show(
                      context,
                      exercise: exercise,
                      setNumber: setNum,
                      existing: log,
                      onLog: onLog,
                    ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(children: [
                // Set number circle
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLogged ? AppTheme.voltLime.withOpacity(0.15) : AppTheme.surface3,
                    border: Border.all(
                      color: isLogged ? AppTheme.voltLime.withOpacity(0.5) : AppTheme.border,
                    ),
                  ),
                  child: Center(
                    child: isLogged
                        ? Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 14)
                        : Text('$setNum', style: AppTheme.label(12, color: AppTheme.ink2)),
                  ),
                ),
                const SizedBox(width: 12),

                // Weight / reps logged
                Expanded(child: isLogged
                    ? Row(children: [
                        if (log.weightKg != null) ...[
                          Text('${log.weightKg!.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                        ],
                        if (log.reps != null)
                          Text('× ${log.reps} reps', style: AppTheme.label(13, color: AppTheme.ink2)),
                        if (log.durationSecs != null)
                          Text('${log.durationSecs}s', style: AppTheme.label(13, color: AppTheme.ink2)),
                      ])
                    : Text(
                        'Set $setNum · ${exercise.repsLabel} ${exercise.repsLabel.endsWith('s') ? 'sec' : 'reps'}',
                        style: AppTheme.label(13, color: AppTheme.ink3),
                      ),
                ),

                // Tap to log
                if (!sessionCompleted)
                  Icon(
                    isLogged ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                    color: isLogged ? AppTheme.ink3 : AppTheme.voltLime,
                    size: 18,
                  ),

                // XP chip when logged
                if (isLogged) ...[
                  const SizedBox(width: 6),
                  Text('+10', style: AppTheme.label(11, color: AppTheme.voltLime)),
                ],
              ]),
            ),
          );
        }),

        const SizedBox(height: 4),
      ]),
    );
  }
}
