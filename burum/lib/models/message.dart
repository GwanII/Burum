class Message {
  final int id;
  final int senderId;
  final String? content;
  final String type; // text / image
  final String? imageUrl;
  final DateTime time;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
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
      content: json['content'],
      type: json['type'] ?? 'text',
      imageUrl: json['image_url'],
      time: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1,
    );
  }
}