class ChatRoom {
  final int roomId;
  final int otherUserId;
  final String otherUserNickname;

  final int? postId;
  final String? postTitle;
  final String? postImage;

  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final bool isPinned;

  ChatRoom({
    required this.roomId,
    required this.otherUserId,
    required this.otherUserNickname,
    this.postId,
    this.postTitle,
    this.postImage,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isPinned,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomId: json['roomId'] ?? 0,
      otherUserId: json['otherUserId'] ?? 0,
      otherUserNickname: json['otherUserNickname'] ?? '알 수 없음',
      postId: json['postId'],
      postTitle: json['postTitle'],
      postImage: json['postImage'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      isPinned: json['isPinned'] == 1 || json['isPinned'] == true,
    );
  }

  ChatRoom copyWith({
    bool? isPinned,
    int? unreadCount,
  }) {
    return ChatRoom(
      roomId: roomId,
      otherUserId: otherUserId,
      otherUserNickname: otherUserNickname,
      postId: postId,
      postTitle: postTitle,
      postImage: postImage,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}