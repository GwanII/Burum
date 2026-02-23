import 'package:flutter/material.dart';
import '../models/chat_room.dart';

class ChatTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  final VoidCallback onUpdate;

  const ChatTile({
    super.key,
    required this.room,
    required this.onTap,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      leading: const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person),
      ),

      title: Row(
        children: [
          Expanded(
            child: Text(
              room.nickname,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          //  상단 고정 핀 아이콘
          if (room.isPinned)
            const Icon(
              Icons.push_pin,
              size: 18,
              color: Colors.grey,
            ),
        ],
      ),

      subtitle: Text(room.lastMessage),

      trailing: room.unreadCount > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Text(
                room.unreadCount.toString(),
                style:
                    const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
    );
  }
}
