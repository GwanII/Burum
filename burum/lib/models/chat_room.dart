import 'dart:convert';

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
  final List<String> postTags;

  final String? postWriterNickname;
  final String? postWriterProfileImage;
  final String? postWriterTitle;
  final String? postWriterGrade;

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
    this.postTags = const [],
    this.postWriterNickname,
    this.postWriterProfileImage,
    this.postWriterTitle,
    this.postWriterGrade,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isPinned,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomId: json['roomId'] is int
          ? json['roomId']
          : int.tryParse(json['roomId']?.toString() ?? '0') ?? 0,
      otherUserId: json['otherUserId'] is int
          ? json['otherUserId']
          : int.tryParse(json['otherUserId']?.toString() ?? '0') ?? 0,
      otherUserNickname: json['otherUserNickname'] ?? '알 수 없음',
      otherUserProfileImage: json['otherUserProfileImage'],
      otherUserTitle: json['otherUserTitle'],
      otherUserGrade: json['otherUserGrade'],

      postId: json['postId'] is int
          ? json['postId']
          : int.tryParse(json['postId']?.toString() ?? ''),
      postTitle: json['postTitle'],
      postImage: json['postImage'],
      postContent: json['postContent'],
      postCost: json['postCost'] is int
          ? json['postCost']
          : int.tryParse(json['postCost']?.toString() ?? ''),
      postStatus: json['postStatus'],
      postDeadline: json['postDeadline'],
      postWriterId: json['postWriterId'] is int
          ? json['postWriterId']
          : int.tryParse(json['postWriterId']?.toString() ?? ''),
      postTags: _parseTags(json['postTags']),

      postWriterNickname: json['postWriterNickname'],
      postWriterProfileImage: json['postWriterProfileImage'],
      postWriterTitle: json['postWriterTitle'],
      postWriterGrade: json['postWriterGrade'],

      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      isPinned: json['isPinned'] == 1 || json['isPinned'] == true,
    );
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return [];

      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}

      return text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }
}