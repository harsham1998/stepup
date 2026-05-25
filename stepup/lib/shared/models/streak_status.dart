class StreakStatus {
  final int streakDays, reviveCostCoins, coinBalance;
  final bool streakAtRisk, shieldAvailable, shieldUsedThisMonth, reviveAvailable;
  const StreakStatus({required this.streakDays, required this.reviveCostCoins, required this.coinBalance, required this.streakAtRisk, required this.shieldAvailable, required this.shieldUsedThisMonth, required this.reviveAvailable});
  factory StreakStatus.fromJson(Map<String, dynamic> j) => StreakStatus(
    streakDays: (j['streak_days'] as num? ?? 0).toInt(), reviveCostCoins: (j['revive_cost_coins'] as num? ?? 100).toInt(),
    coinBalance: (j['coin_balance'] as num? ?? 0).toInt(), streakAtRisk: j['streak_at_risk'] as bool? ?? false,
    shieldAvailable: j['shield_available'] as bool? ?? true, shieldUsedThisMonth: j['shield_used_this_month'] as bool? ?? false,
    reviveAvailable: j['revive_available'] as bool? ?? true,
  );
}
