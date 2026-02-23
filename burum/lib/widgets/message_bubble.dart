import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ✅ 상대방 프로필 사진
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          // ✅ 내 메시지일 경우 시간/읽음 먼저
          if (message.isMe) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.isRead)
                  const Text("읽음", style: TextStyle(fontSize: 10)),
                Text(
                  "${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],

          // ✅ 메시지 버블
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isMe
                    ? AppTheme.myMessageColor
                    : AppTheme.otherMessageColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message.text),
            ),
          ),

          // ✅ 상대방 메시지 시간 표시
          if (!message.isMe) ...[
            const SizedBox(width: 6),
            Text(
              "${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
