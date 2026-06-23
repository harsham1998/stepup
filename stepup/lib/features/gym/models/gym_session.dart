// stepup/lib/features/gym/models/gym_session.dart
import 'gym_plan.dart';

class SetLog {
  final String id;
  final String exerciseId;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final int? durationSecs;
  final String loggedAt;
  final int xpAwarded;

  const SetLog({
    required this.id,
    required this.exerciseId,
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.durationSecs,
    required this.loggedAt,
    required this.xpAwarded,
  });

  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        id: j['id'] as String,
        exerciseId: j['exercise_id'] as String,
        setNumber: (j['set_number'] as num).toInt(),
        weightKg: j['weight_kg'] != null ? (j['weight_kg'] as num).toDouble() : null,
        reps: j['reps'] != null ? (j['reps'] as num).toInt() : null,
        durationSecs: j['duration_secs'] != null ? (j['duration_secs'] as num).toInt() : null,
        loggedAt: j['logged_at'] as String,
        xpAwarded: (j['xp_awarded'] as num? ?? 0).toInt(),
      );
}

class GymSession {
  final String id;
  final String planId;
  final WorkoutPlan plan;
  final String sessionDate;
  final String startedAt;
  final String? completedAt;
  final int xpAwarded;
  final List<SetLog> setLogs;

  const GymSession({
    required this.id,
    required this.planId,
    required this.plan,
    required this.sessionDate,
    required this.startedAt,
    this.completedAt,
    required this.xpAwarded,
    required this.setLogs,
  });

  bool get isCompleted => completedAt != null;

  List<SetLog> logsForExercise(String exerciseId) =>
      setLogs.where((l) => l.exerciseId == exerciseId).toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

  bool isSetLogged(String exerciseId, int setNumber) =>
      setLogs.any((l) => l.exerciseId == exerciseId && l.setNumber == setNumber);

  bool isExerciseComplete(String exerciseId, int totalSets) =>
      logsForExercise(exerciseId).length >= totalSets;

  factory GymSession.fromJson(Map<String, dynamic> j) => GymSession(
        id: j['id'] as String,
        planId: j['plan_id'] as String,
        plan: WorkoutPlan.fromJson(j['plan'] as Map<String, dynamic>),
        sessionDate: j['session_date'] as String,
        startedAt: j['started_at'] as String,
        completedAt: j['completed_at'] as String?,
        xpAwarded: (j['xp_awarded'] as num? ?? 0).toInt(),
        setLogs: (j['set_logs'] as List? ?? [])
            .map((e) => SetLog.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
