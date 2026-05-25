class Rival {
  final String userId, name, league;
  final String? avatarUrl;
  final int weekSteps, todaySteps, streakDays;
  const Rival({required this.userId, required this.name, required this.league, this.avatarUrl, required this.weekSteps, required this.todaySteps, required this.streakDays});
  factory Rival.fromJson(Map<String, dynamic> j) => Rival(
    userId: j['user_id'] as String, name: j['name'] as String, league: j['league'] as String? ?? 'bronze',
    avatarUrl: j['avatar_url'] as String?, weekSteps: (j['week_steps'] as num? ?? 0).toInt(),
    todaySteps: (j['today_steps'] as num? ?? 0).toInt(), streakDays: (j['streak_days'] as num? ?? 0).toInt(),
  );
}

class Battle {
  final String id, challengerId, opponentId, challengerName, opponentName, status;
  final int challengerSteps, opponentSteps, coinWager, durationDays;
  final DateTime createdAt;
  final DateTime? startTime, endTime;
  const Battle({required this.id, required this.challengerId, required this.opponentId, required this.challengerName, required this.opponentName, required this.status, required this.challengerSteps, required this.opponentSteps, required this.coinWager, required this.durationDays, required this.createdAt, this.startTime, this.endTime});
  factory Battle.fromJson(Map<String, dynamic> j) => Battle(
    id: j['id'] as String, challengerId: j['challenger_id'] as String, opponentId: j['opponent_id'] as String,
    challengerName: j['challenger_name'] as String? ?? 'Unknown', opponentName: j['opponent_name'] as String? ?? 'Unknown',
    status: j['status'] as String, challengerSteps: (j['challenger_steps'] as num? ?? 0).toInt(),
    opponentSteps: (j['opponent_steps'] as num? ?? 0).toInt(), coinWager: (j['coin_wager'] as num? ?? 0).toInt(),
    durationDays: (j['duration_days'] as num? ?? 7).toInt(), createdAt: DateTime.parse(j['created_at'] as String),
    startTime: j['start_time'] != null ? DateTime.parse(j['start_time'] as String) : null,
    endTime: j['end_time'] != null ? DateTime.parse(j['end_time'] as String) : null,
  );
}
