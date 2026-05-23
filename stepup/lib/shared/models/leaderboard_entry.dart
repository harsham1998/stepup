class LeaderboardEntry {
  final int rank, steps;
  final String userId, name, city;

  const LeaderboardEntry({
    required this.rank, required this.steps,
    required this.userId, required this.name, required this.city,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: j['rank'], steps: j['steps'],
    userId: j['user_id'], name: j['name'], city: j['city'] ?? '',
  );
}
