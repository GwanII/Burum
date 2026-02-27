import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.yellow[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: message.type == "image"
            ? Image.network(
                "http://localhost:3000${message.imageUrl}",
                width: 150,
              )
            : Text(message.content ?? ""),
      ),
    );
  }
}