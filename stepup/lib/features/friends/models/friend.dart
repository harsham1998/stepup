class Friend {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final int xp;
  final String leagueSlug;
  final int streakDays;

  const Friend({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    required this.xp,
    required this.leagueSlug,
    required this.streakDays,
  });

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'] as String,
        name: j['name'] as String,
        username: j['username'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        xp: (j['xp'] as num).toInt(),
        leagueSlug: j['league_slug'] as String? ?? 'bronze',
        streakDays: (j['streak_days'] as num?)?.toInt() ?? 0,
      );
}
