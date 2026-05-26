class StreakCalendarDay {
  final String date, status;
  final int steps, streakCount;

  const StreakCalendarDay({
    required this.date,
    required this.status,
    required this.steps,
    required this.streakCount,
  });

  factory StreakCalendarDay.fromJson(Map<String, dynamic> j) => StreakCalendarDay(
        date: j['date'] as String,
        status: j['status'] as String? ?? 'none',
        steps: (j['steps'] as num? ?? 0).toInt(),
        streakCount: (j['streak_count'] as num? ?? 0).toInt(),
      );
}
