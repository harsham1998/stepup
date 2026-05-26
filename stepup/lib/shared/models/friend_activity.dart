class FriendActivity {
  final String id;
  final String type; // 'battle_lost' | 'league_overtake' | 'streak_milestone'
  final String friendId;
  final String friendName;
  final String? friendAvatar;
  final DateTime occurredAt;
  final Map<String, dynamic> meta;

  const FriendActivity({
    required this.id,
    required this.type,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
    required this.occurredAt,
    required this.meta,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> j) => FriendActivity(
        id: j['id'] as String,
        type: j['type'] as String,
        friendId: j['friend_id'] as String,
        friendName: j['friend_name'] as String,
        friendAvatar: j['friend_avatar'] as String?,
        occurredAt: DateTime.parse(j['occurred_at'] as String),
        meta: j['meta'] as Map<String, dynamic>? ?? {},
      );
}

class FriendsStandingEntry {
  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int xp;
  final String leagueSlug;
  final bool isMe;
  final int xpGap;

  const FriendsStandingEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.xp,
    required this.leagueSlug,
    required this.isMe,
    required this.xpGap,
  });

  factory FriendsStandingEntry.fromJson(Map<String, dynamic> j) => FriendsStandingEntry(
        rank: j['rank'] as int,
        userId: j['user_id'] as String,
        name: j['name'] as String,
        avatarUrl: j['avatar_url'] as String?,
        xp: j['xp'] as int,
        leagueSlug: j['league_slug'] as String,
        isMe: j['is_me'] as bool,
        xpGap: j['xp_gap'] as int? ?? 0,
      );
}

class FriendsStandings {
  final List<FriendsStandingEntry> entries;
  final int myRank;

  const FriendsStandings({required this.entries, required this.myRank});

  factory FriendsStandings.fromJson(Map<String, dynamic> j) => FriendsStandings(
        entries: (j['entries'] as List)
            .map((e) => FriendsStandingEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        myRank: j['my_rank'] as int? ?? 1,
      );
}

class SocialFeedData {
  final List<FriendActivity> activities;
  final FriendsStandings standings;

  const SocialFeedData({required this.activities, required this.standings});
}
