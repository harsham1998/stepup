import 'friend.dart';

enum FriendshipStatus { none, pendingSent, pendingReceived, friends }

class UserSearchResult extends Friend {
  final FriendshipStatus friendshipStatus;
  final String? requestId;

  const UserSearchResult({
    required super.id,
    required super.name,
    super.username,
    super.avatarUrl,
    required super.xp,
    required super.leagueSlug,
    required super.streakDays,
    required this.friendshipStatus,
    this.requestId,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) {
    final statusStr = j['friendship_status'] as String? ?? 'none';
    final status = switch (statusStr) {
      'pending_sent' => FriendshipStatus.pendingSent,
      'pending_received' => FriendshipStatus.pendingReceived,
      'friends' => FriendshipStatus.friends,
      _ => FriendshipStatus.none,
    };
    return UserSearchResult(
      id: j['id'] as String,
      name: j['name'] as String,
      username: j['username'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      xp: (j['xp'] as num).toInt(),
      leagueSlug: j['league_slug'] as String? ?? 'bronze',
      streakDays: (j['streak_days'] as num?)?.toInt() ?? 0,
      friendshipStatus: status,
      requestId: j['request_id'] as String?,
    );
  }
}
