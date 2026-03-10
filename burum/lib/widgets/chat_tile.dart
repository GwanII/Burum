import 'package:flutter/material.dart';
import '../models/chat_room.dart';

class ChatTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatTile({
    required this.room,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(room.nickname),
      subtitle: Text(room.lastMessage ?? ""),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (room.lastMessageTime != null)
            Text(
              "${room.lastMessageTime!.hour}:${room.lastMessageTime!.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 12),
            ),
          if (room.unreadCount > 0)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                room.unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            )
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}