class LeaderboardEntry {
  final int rank, steps;
  final String userId, name, city;

  const LeaderboardEntry({
    required this.rank, required this.steps,
    required this.userId, required this.name, required this.city,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: (j['rank'] as num).toInt(),
    steps: (j['steps'] as num).toInt(),
    userId: j['user_id'] as String,
    name: j['name'] as String,
    city: (j['city'] as String?) ?? '',
  );
}
