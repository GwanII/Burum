class Message {
  final int id;
  final int senderId;
  final String? senderNickname;
  final String? content;
  final String type;
  final String? imageUrl;
  final DateTime time;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    this.senderNickname,
    this.content,
    required this.type,
    this.imageUrl,
    required this.time,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      senderNickname: json['nickname'],
      content: json['content'],
      type: json['type'] ?? 'text',
      imageUrl: json['image_url'],
      time: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}