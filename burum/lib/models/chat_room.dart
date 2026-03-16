class ChatRoom {
  final int roomId;
  final int otherUserId;
  final String otherUserNickname;
  final String? otherUserProfileImage;
  final String? otherUserTitle;
  final String? otherUserGrade;

  final int? postId;
  final String? postTitle;
  final String? postImage;
  final String? postContent;
  final int? postCost;
  final String? postStatus;
  final String? postDeadline;
  final int? postWriterId;

  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final bool isPinned;

  ChatRoom({
    required this.roomId,
    required this.otherUserId,
    required this.otherUserNickname,
    this.otherUserProfileImage,
    this.otherUserTitle,
    this.otherUserGrade,
    this.postId,
    this.postTitle,
    this.postImage,
    this.postContent,
    this.postCost,
    this.postStatus,
    this.postDeadline,
    this.postWriterId,
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
      otherUserProfileImage: json['otherUserProfileImage'],
      otherUserTitle: json['otherUserTitle'],
      otherUserGrade: json['otherUserGrade'],
      postId: json['postId'],
      postTitle: json['postTitle'],
      postImage: json['postImage'],
      postContent: json['postContent'],
      postCost: json['postCost'],
      postStatus: json['postStatus'],
      postDeadline: json['postDeadline'],
      postWriterId: json['postWriterId'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      isPinned: json['isPinned'] == 1 || json['isPinned'] == true,
    );
  }
}