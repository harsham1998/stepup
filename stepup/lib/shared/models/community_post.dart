class CommunityPost {
  final String id, userId, userName, type, content;
  final String? userAvatar, userLeague;
  final int likes;
  final bool likedByMe, isMine;
  final DateTime createdAt;
  final String visibility;
  final List<String> mediaUrls;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.content,
    this.userAvatar,
    this.userLeague,
    required this.likes,
    required this.likedByMe,
    required this.isMine,
    required this.createdAt,
    this.visibility = 'everyone',
    this.mediaUrls = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    userName: j['user_name'] as String? ?? 'Unknown',
    type: j['type'] as String,
    content: j['content'] as String,
    userAvatar: j['user_avatar'] as String?,
    userLeague: j['user_league'] as String?,
    likes: (j['likes'] as num? ?? 0).toInt(),
    likedByMe: j['liked_by_me'] as bool? ?? false,
    isMine: j['is_mine'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    visibility: j['visibility'] as String? ?? 'everyone',
    mediaUrls: (j['media_urls'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
  );
}
