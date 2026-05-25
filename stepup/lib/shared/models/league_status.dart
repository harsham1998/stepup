class LeagueTier {
  final String slug, label, colorHex;
  final int xpMin;
  final int? xpMax;
  final bool paidOnly, locked, isCurrent;
  const LeagueTier({required this.slug, required this.label, required this.colorHex, required this.xpMin, this.xpMax, required this.paidOnly, required this.locked, required this.isCurrent});
  factory LeagueTier.fromJson(Map<String, dynamic> j) => LeagueTier(
    slug: j['slug'] as String, label: j['label'] as String, colorHex: j['color_hex'] as String,
    xpMin: (j['xp_min'] as num).toInt(), xpMax: (j['xp_max'] as num?)?.toInt(),
    paidOnly: j['paid_only'] as bool? ?? false, locked: j['locked'] as bool? ?? false,
    isCurrent: j['is_current'] as bool? ?? false,
  );
}

class LeagueStatus {
  final String leagueSlug, label, colorHex;
  final int xp, xpMin, xpForNext, rankInTier, totalInTier, season;
  final List<LeagueTier> tierLadder;
  const LeagueStatus({required this.leagueSlug, required this.label, required this.colorHex, required this.xp, required this.xpMin, required this.xpForNext, required this.rankInTier, required this.totalInTier, required this.season, required this.tierLadder});
  factory LeagueStatus.fromJson(Map<String, dynamic> j) => LeagueStatus(
    leagueSlug: j['league_slug'] as String, label: j['label'] as String, colorHex: j['color_hex'] as String,
    xp: (j['xp'] as num).toInt(), xpMin: (j['xp_min'] as num).toInt(), xpForNext: (j['xp_for_next'] as num).toInt(),
    rankInTier: (j['rank_in_tier'] as num? ?? 1).toInt(), totalInTier: (j['total_in_tier'] as num? ?? 1).toInt(),
    season: (j['season'] as num? ?? 1).toInt(),
    tierLadder: (j['tier_ladder'] as List? ?? []).map((e) => LeagueTier.fromJson(e as Map<String, dynamic>)).toList(),
  );
  double get xpProgress => xpForNext > xpMin ? (xp - xpMin) / (xpForNext - xpMin) : 1.0;
}
