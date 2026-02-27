class ChatRoom {
  final int roomId;
  final String nickname;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  bool isPinned;

  ChatRoom({
    required this.roomId,
    required this.nickname,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    this.isPinned = false,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomId: json['roomId'],
      nickname: "상대방", // 일단 더미
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}