// stepup/lib/shared/models/body_vitals.dart

class BodyVitalsEntry {
  final String date;
  final double? weightKg;
  final double? bmi;
  final int? visceralFatLevel;
  final double? musclePercentage;

  const BodyVitalsEntry({
    required this.date,
    this.weightKg,
    this.bmi,
    this.visceralFatLevel,
    this.musclePercentage,
  });

  factory BodyVitalsEntry.fromJson(Map<String, dynamic> j) => BodyVitalsEntry(
    date:              j['date'] as String,
    weightKg:          (j['weight_kg'] as num?)?.toDouble(),
    bmi:               (j['bmi'] as num?)?.toDouble(),
    visceralFatLevel:  (j['visceral_fat_level'] as num?)?.toInt(),
    musclePercentage:  (j['muscle_percentage'] as num?)?.toDouble(),
  );
}

class BodyVitalsGoal {
  final double? goalWeightKg;
  final double? goalBmi;

  const BodyVitalsGoal({this.goalWeightKg, this.goalBmi});

  factory BodyVitalsGoal.fromJson(Map<String, dynamic> j) => BodyVitalsGoal(
    goalWeightKg: (j['goal_weight_kg'] as num?)?.toDouble(),
    goalBmi:      (j['goal_bmi'] as num?)?.toDouble(),
  );
}

class BodyVitalsSummary {
  final BodyVitalsEntry? latest;
  final BodyVitalsEntry? earliest;
  final BodyVitalsGoal? goal;
  final int loggingStreak;
  final bool loggedToday;

  const BodyVitalsSummary({
    this.latest,
    this.earliest,
    this.goal,
    required this.loggingStreak,
    required this.loggedToday,
  });

  factory BodyVitalsSummary.fromJson(Map<String, dynamic> j) => BodyVitalsSummary(
    latest:       j['latest'] != null
        ? BodyVitalsEntry.fromJson(j['latest'] as Map<String, dynamic>)
        : null,
    earliest:     j['earliest'] != null
        ? BodyVitalsEntry.fromJson(j['earliest'] as Map<String, dynamic>)
        : null,
    goal:         j['goal'] != null
        ? BodyVitalsGoal.fromJson(j['goal'] as Map<String, dynamic>)
        : null,
    loggingStreak: (j['logging_streak'] as num? ?? 0).toInt(),
    loggedToday:  j['logged_today'] as bool? ?? false,
  );
}
