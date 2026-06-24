// stepup/lib/features/gym/models/gym_plan.dart
import 'package:uuid/uuid.dart';

// ── Master exercise (static catalogue for search) ─────────────────────────────

class MasterExercise {
  final String name;
  final List<String> targetMuscles;
  final String equipment;
  final String category; // push | pull | legs | core | cardio

  const MasterExercise({
    required this.name,
    required this.targetMuscles,
    required this.equipment,
    required this.category,
  });
}

// Full searchable catalogue — used client-side, no network call
const masterExercises = <MasterExercise>[
  // Chest / Push
  MasterExercise(name: 'Machine Chest Press', targetMuscles: ['chest'], equipment: 'machine', category: 'push'),
  MasterExercise(name: 'Incline Dumbbell Press', targetMuscles: ['chest', 'front-delt'], equipment: 'dumbbell', category: 'push'),
  MasterExercise(name: 'Pec Deck Fly', targetMuscles: ['chest'], equipment: 'machine', category: 'push'),
  MasterExercise(name: 'Push Up', targetMuscles: ['chest', 'triceps'], equipment: 'bodyweight', category: 'push'),
  MasterExercise(name: 'Dumbbell Bench Press', targetMuscles: ['chest'], equipment: 'dumbbell', category: 'push'),
  MasterExercise(name: 'Cable Crossover', targetMuscles: ['chest'], equipment: 'cable', category: 'push'),
  // Shoulders
  MasterExercise(name: 'Machine Shoulder Press', targetMuscles: ['shoulders', 'front-delt'], equipment: 'machine', category: 'push'),
  MasterExercise(name: 'Lateral Raise', targetMuscles: ['shoulders', 'side-delt'], equipment: 'dumbbell', category: 'push'),
  MasterExercise(name: 'Front Raise', targetMuscles: ['shoulders', 'front-delt'], equipment: 'dumbbell', category: 'push'),
  MasterExercise(name: 'Arnold Press', targetMuscles: ['shoulders'], equipment: 'dumbbell', category: 'push'),
  MasterExercise(name: 'Upright Row', targetMuscles: ['shoulders', 'upper-back'], equipment: 'barbell', category: 'push'),
  // Triceps
  MasterExercise(name: 'Rope Pushdown', targetMuscles: ['triceps'], equipment: 'cable', category: 'push'),
  MasterExercise(name: 'Overhead Rope Extension', targetMuscles: ['triceps', 'long-head-triceps'], equipment: 'cable', category: 'push'),
  MasterExercise(name: 'Dips', targetMuscles: ['triceps', 'chest'], equipment: 'bodyweight', category: 'push'),
  MasterExercise(name: 'Skull Crushers', targetMuscles: ['triceps'], equipment: 'barbell', category: 'push'),
  MasterExercise(name: 'Diamond Push Up', targetMuscles: ['triceps', 'chest'], equipment: 'bodyweight', category: 'push'),
  // Back / Pull
  MasterExercise(name: 'Lat Pulldown', targetMuscles: ['lats', 'back'], equipment: 'machine', category: 'pull'),
  MasterExercise(name: 'Seated Cable Row', targetMuscles: ['back', 'mid-back'], equipment: 'cable', category: 'pull'),
  MasterExercise(name: 'Chest Supported Row', targetMuscles: ['back', 'mid-back'], equipment: 'machine', category: 'pull'),
  MasterExercise(name: 'Face Pull', targetMuscles: ['rear-delt', 'upper-back'], equipment: 'cable', category: 'pull'),
  MasterExercise(name: 'Pull Up', targetMuscles: ['lats', 'back'], equipment: 'bodyweight', category: 'pull'),
  MasterExercise(name: 'Deadlift', targetMuscles: ['back', 'hamstrings', 'glutes'], equipment: 'barbell', category: 'pull'),
  MasterExercise(name: 'T-Bar Row', targetMuscles: ['back', 'mid-back'], equipment: 'machine', category: 'pull'),
  // Biceps
  MasterExercise(name: 'Machine Curl', targetMuscles: ['biceps'], equipment: 'machine', category: 'pull'),
  MasterExercise(name: 'Hammer Curl', targetMuscles: ['biceps', 'brachialis'], equipment: 'dumbbell', category: 'pull'),
  MasterExercise(name: 'Barbell Curl', targetMuscles: ['biceps'], equipment: 'barbell', category: 'pull'),
  MasterExercise(name: 'Cable Curl', targetMuscles: ['biceps'], equipment: 'cable', category: 'pull'),
  MasterExercise(name: 'Incline Dumbbell Curl', targetMuscles: ['biceps'], equipment: 'dumbbell', category: 'pull'),
  MasterExercise(name: 'Concentration Curl', targetMuscles: ['biceps'], equipment: 'dumbbell', category: 'pull'),
  // Legs
  MasterExercise(name: 'Barbell Squat', targetMuscles: ['quads', 'glutes'], equipment: 'barbell', category: 'legs'),
  MasterExercise(name: 'Romanian Deadlift', targetMuscles: ['hamstrings', 'glutes'], equipment: 'barbell', category: 'legs'),
  MasterExercise(name: 'Leg Press', targetMuscles: ['quads', 'glutes'], equipment: 'machine', category: 'legs'),
  MasterExercise(name: 'Leg Extension', targetMuscles: ['quads'], equipment: 'machine', category: 'legs'),
  MasterExercise(name: 'Leg Curl', targetMuscles: ['hamstrings'], equipment: 'machine', category: 'legs'),
  MasterExercise(name: 'Standing Calf Raise', targetMuscles: ['calves'], equipment: 'machine', category: 'legs'),
  MasterExercise(name: 'Bulgarian Split Squat', targetMuscles: ['quads', 'glutes'], equipment: 'dumbbell', category: 'legs'),
  MasterExercise(name: 'Hip Thrust', targetMuscles: ['glutes', 'hamstrings'], equipment: 'barbell', category: 'legs'),
  MasterExercise(name: 'Goblet Squat', targetMuscles: ['quads', 'glutes'], equipment: 'dumbbell', category: 'legs'),
  MasterExercise(name: 'Lunges', targetMuscles: ['quads', 'glutes'], equipment: 'dumbbell', category: 'legs'),
  MasterExercise(name: 'Sumo Deadlift', targetMuscles: ['quads', 'glutes', 'hamstrings'], equipment: 'barbell', category: 'legs'),
  MasterExercise(name: 'Seated Calf Raise', targetMuscles: ['calves'], equipment: 'machine', category: 'legs'),
  // Core
  MasterExercise(name: 'Plank', targetMuscles: ['core', 'abs'], equipment: 'bodyweight', category: 'core'),
  MasterExercise(name: 'Crunches', targetMuscles: ['abs', 'core'], equipment: 'bodyweight', category: 'core'),
  MasterExercise(name: 'Russian Twist', targetMuscles: ['abs', 'core'], equipment: 'bodyweight', category: 'core'),
  MasterExercise(name: 'Hanging Leg Raise', targetMuscles: ['abs', 'core'], equipment: 'bodyweight', category: 'core'),
  MasterExercise(name: 'Mountain Climber', targetMuscles: ['core', 'abs'], equipment: 'bodyweight', category: 'core'),
  MasterExercise(name: 'Ab Rollout', targetMuscles: ['abs', 'core'], equipment: 'machine', category: 'core'),
  MasterExercise(name: 'Side Plank', targetMuscles: ['core'], equipment: 'bodyweight', category: 'core'),
  MasterExercise(name: 'Bicycle Crunch', targetMuscles: ['abs', 'core'], equipment: 'bodyweight', category: 'core'),
  // Cardio
  MasterExercise(name: 'Jumping Jacks', targetMuscles: ['core'], equipment: 'bodyweight', category: 'cardio'),
  MasterExercise(name: 'Skipping', targetMuscles: ['calves', 'core'], equipment: 'bodyweight', category: 'cardio'),
  MasterExercise(name: 'Burpees', targetMuscles: ['core', 'chest'], equipment: 'bodyweight', category: 'cardio'),
  MasterExercise(name: 'Jump Squat', targetMuscles: ['quads', 'glutes'], equipment: 'bodyweight', category: 'cardio'),
  MasterExercise(name: 'High Knees', targetMuscles: ['core', 'quads'], equipment: 'bodyweight', category: 'cardio'),
  MasterExercise(name: 'Box Jump', targetMuscles: ['quads', 'glutes'], equipment: 'bodyweight', category: 'cardio'),
  MasterExercise(name: 'Battle Ropes', targetMuscles: ['shoulders', 'core'], equipment: 'machine', category: 'cardio'),
];

// ── Editable exercise (for plan customisation) ────────────────────────────────

class EditableExercise {
  final String id;
  final String name;
  final List<String> targetMuscles;
  final String equipment;
  int sets;
  String repsLabel;
  int sortOrder;

  EditableExercise({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.equipment,
    required this.sets,
    required this.repsLabel,
    required this.sortOrder,
  });

  factory EditableExercise.fromPlanExercise(PlanExercise e) => EditableExercise(
        id: e.id,
        name: e.name,
        targetMuscles: e.targetMuscles,
        equipment: e.equipment,
        sets: e.sets,
        repsLabel: e.repsLabel,
        sortOrder: e.sortOrder,
      );

  factory EditableExercise.fromMaster(MasterExercise m, int sortOrder) => EditableExercise(
        id: const Uuid().v4(),
        name: m.name,
        targetMuscles: m.targetMuscles,
        equipment: m.equipment,
        sets: 3,
        repsLabel: m.category == 'cardio' ? '30' : '10',
        sortOrder: sortOrder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target_muscles': targetMuscles,
        'equipment': equipment,
        'sets': sets,
        'reps_label': repsLabel,
        'sort_order': sortOrder,
      };
}

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
