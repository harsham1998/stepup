// stepup/lib/shared/models/reputation.dart
class ReputationBreakdown {
  final int consistency, challengeWins, streakDepth, activityMix, social;
  const ReputationBreakdown({
    required this.consistency, required this.challengeWins,
    required this.streakDepth, required this.activityMix, required this.social,
  });
  factory ReputationBreakdown.fromJson(Map<String, dynamic> j) => ReputationBreakdown(
    consistency: (j['consistency'] as num? ?? 0).toInt(),
    challengeWins: (j['challenge_wins'] as num? ?? 0).toInt(),
    streakDepth: (j['streak_depth'] as num? ?? 0).toInt(),
    activityMix: (j['activity_mix'] as num? ?? 0).toInt(),
    social: (j['social'] as num? ?? 0).toInt(),
  );
}

class ReputationHighlights {
  final int bestStreakDays, totalChallengesJoined;
  const ReputationHighlights({required this.bestStreakDays, required this.totalChallengesJoined});
  factory ReputationHighlights.fromJson(Map<String, dynamic> j) => ReputationHighlights(
    bestStreakDays: (j['best_streak_days'] as num? ?? 0).toInt(),
    totalChallengesJoined: (j['total_challenges_joined'] as num? ?? 0).toInt(),
  );
}

class Reputation {
  final int score, percentileRank, monthlyDelta;
  final ReputationBreakdown breakdown;
  final ReputationHighlights highlights;

  const Reputation({
    required this.score, required this.percentileRank, required this.monthlyDelta,
    required this.breakdown, required this.highlights,
  });

  factory Reputation.fromJson(Map<String, dynamic> j) => Reputation(
    score: (j['score'] as num? ?? 0).toInt(),
    percentileRank: (j['percentile_rank'] as num? ?? 100).toInt(),
    monthlyDelta: (j['monthly_delta'] as num? ?? 0).toInt(),
    breakdown: ReputationBreakdown.fromJson(j['breakdown'] as Map<String, dynamic>? ?? {}),
    highlights: ReputationHighlights.fromJson(j['highlights'] as Map<String, dynamic>? ?? {}),
  );
}
