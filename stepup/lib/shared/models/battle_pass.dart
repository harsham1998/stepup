class BattlePassTierData {
  final int level, xpRequired;
  final String freeReward, paidReward;
  final bool unlocked, claimed;
  const BattlePassTierData({required this.level, required this.xpRequired, required this.freeReward, required this.paidReward, required this.unlocked, required this.claimed});
  factory BattlePassTierData.fromJson(Map<String, dynamic> j) => BattlePassTierData(
    level: (j['level'] as num).toInt(), xpRequired: (j['xp_required'] as num).toInt(),
    freeReward: j['free_reward'] as String, paidReward: j['paid_reward'] as String,
    unlocked: j['unlocked'] as bool? ?? false, claimed: j['claimed'] as bool? ?? false,
  );
}

class BattlePassProgress {
  final int season, userXp, daysRemaining;
  final String title;
  final bool isPremium;
  final List<BattlePassTierData> tiers;
  const BattlePassProgress({required this.season, required this.userXp, required this.daysRemaining, required this.title, required this.isPremium, required this.tiers});
  factory BattlePassProgress.fromJson(Map<String, dynamic> j) => BattlePassProgress(
    season: (j['season'] as num).toInt(), userXp: (j['user_xp'] as num? ?? 0).toInt(),
    daysRemaining: (j['days_remaining'] as num? ?? 0).toInt(), title: j['title'] as String? ?? 'Battle Pass',
    isPremium: j['is_premium'] as bool? ?? false,
    tiers: (j['tiers'] as List? ?? []).map((e) => BattlePassTierData.fromJson(e as Map<String, dynamic>)).toList(),
  );
}
