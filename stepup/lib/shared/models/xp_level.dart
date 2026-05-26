class XpLevel {
  final int xp, level, xpForNextLevel, xpInCurrentLevel, xpNeeded;
  final String title;

  const XpLevel({
    required this.xp,
    required this.level,
    required this.xpForNextLevel,
    required this.xpInCurrentLevel,
    required this.xpNeeded,
    required this.title,
  });

  factory XpLevel.fromJson(Map<String, dynamic> j) => XpLevel(
        xp: (j['xp'] as num? ?? 0).toInt(),
        level: (j['level'] as num? ?? 1).toInt(),
        xpForNextLevel: (j['xp_for_next_level'] as num? ?? 1000).toInt(),
        xpInCurrentLevel: (j['xp_in_current_level'] as num? ?? 0).toInt(),
        xpNeeded: (j['xp_needed'] as num? ?? 1000).toInt(),
        title: j['title'] as String? ?? 'Walker',
      );
}
