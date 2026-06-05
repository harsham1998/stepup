class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderUsername;
  final String? senderAvatar;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderUsername,
    this.senderAvatar,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        senderName: j['sender_name'] as String,
        senderUsername: j['sender_username'] as String?,
        senderAvatar: j['sender_avatar'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
