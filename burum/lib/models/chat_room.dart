class ChatRoom {
  final String id;
  final String nickname;
  final String profileImage;
  final String lastMessage;
  int unreadCount;
  bool isPinned;

  ChatRoom({
    required this.id,
    required this.nickname,
    required this.profileImage,
    required this.lastMessage,
    required this.unreadCount,
    this.isPinned = false,
  });
}
