// stepup/lib/features/gym/models/gym_analytics.dart

class GymStats {
  final int totalSessions;
  final int totalVolumeKg;
  final int totalXp;
  final int streak;

  const GymStats({
    required this.totalSessions,
    required this.totalVolumeKg,
    required this.totalXp,
    required this.streak,
  });

  static const empty = GymStats(
    totalSessions: 0, totalVolumeKg: 0, totalXp: 0, streak: 0,
  );

  factory GymStats.fromJson(Map<String, dynamic> j) => GymStats(
    totalSessions: (j['totalSessions'] as num?)?.toInt() ?? 0,
    totalVolumeKg: (j['totalVolumeKg'] as num?)?.toInt() ?? 0,
    totalXp: (j['totalXp'] as num?)?.toInt() ?? 0,
    streak: (j['streak'] as num?)?.toInt() ?? 0,
  );
}

class SessionHistoryItem {
  final String date;
  final int xp;
  final bool completed;
  final String planName;
  final String planSlug;

  const SessionHistoryItem({
    required this.date,
    required this.xp,
    required this.completed,
    required this.planName,
    required this.planSlug,
  });

  factory SessionHistoryItem.fromJson(Map<String, dynamic> j) => SessionHistoryItem(
    date: j['date'] as String? ?? '',
    xp: (j['xp'] as num?)?.toInt() ?? 0,
    completed: j['completed'] as bool? ?? false,
    planName: j['planName'] as String? ?? '',
    planSlug: j['planSlug'] as String? ?? '',
  );
}

class ExerciseProgressPoint {
  final String date;
  final double maxWeightKg;
  final int maxReps;

  const ExerciseProgressPoint({
    required this.date,
    required this.maxWeightKg,
    required this.maxReps,
  });
}
