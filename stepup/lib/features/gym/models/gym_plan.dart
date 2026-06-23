// stepup/lib/features/gym/models/gym_plan.dart

class PlanExercise {
  final String id;
  final String name;
  final List<String> targetMuscles;
  final int sets;
  final String repsLabel;
  final String equipment;
  final int sortOrder;
  final String? gifUrl;

  const PlanExercise({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.sets,
    required this.repsLabel,
    required this.equipment,
    required this.sortOrder,
    this.gifUrl,
  });

  factory PlanExercise.fromJson(Map<String, dynamic> j) => PlanExercise(
        id: j['id'] as String,
        name: j['name'] as String,
        targetMuscles: List<String>.from(j['target_muscles'] as List? ?? []),
        sets: (j['sets'] as num).toInt(),
        repsLabel: j['reps_label'] as String,
        equipment: j['equipment'] as String? ?? 'machine',
        sortOrder: (j['sort_order'] as num? ?? 0).toInt(),
        gifUrl: j['gif_url'] as String?,
      );
}

class WorkoutPlan {
  final String id;
  final String slug;
  final String name;
  final int dayOfWeek;
  final List<String> muscleGroups;
  final bool isRest;
  final List<PlanExercise> exercises;

  const WorkoutPlan({
    required this.id,
    required this.slug,
    required this.name,
    required this.dayOfWeek,
    required this.muscleGroups,
    required this.isRest,
    required this.exercises,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        dayOfWeek: (j['day_of_week'] as num).toInt(),
        muscleGroups: List<String>.from(j['muscle_groups'] as List? ?? []),
        isRest: j['is_rest'] as bool? ?? false,
        exercises: (j['exercises'] as List? ?? [])
            .map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WeekDay {
  final int dayOfWeek;
  final String sessionDate;
  final WorkoutPlan? plan;
  final bool hasSession;
  final bool isCompleted;
  final int xpAwarded;

  const WeekDay({
    required this.dayOfWeek,
    required this.sessionDate,
    required this.plan,
    required this.hasSession,
    required this.isCompleted,
    required this.xpAwarded,
  });

  factory WeekDay.fromJson(Map<String, dynamic> j) => WeekDay(
        dayOfWeek: (j['day_of_week'] as num).toInt(),
        sessionDate: j['session_date'] as String,
        plan: j['plan'] != null
            ? WorkoutPlan.fromJson(j['plan'] as Map<String, dynamic>)
            : null,
        hasSession: j['has_session'] as bool? ?? false,
        isCompleted: j['is_completed'] as bool? ?? false,
        xpAwarded: (j['xp_awarded'] as num? ?? 0).toInt(),
      );
}
