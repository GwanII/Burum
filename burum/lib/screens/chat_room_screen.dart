import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController controller = TextEditingController();

  List<Message> messages = [
    Message(
      text: "안녕하세요 😊",
      isMe: false,
      time: DateTime.now(),
    ),
    Message(
      text: "네 안녕하세요!",
      isMe: true,
      time: DateTime.now(),
      isRead: true,
    ),
  ];

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add(
        Message(
          text: controller.text.trim(),
          isMe: true,
          time: DateTime.now(),
          isRead: false,
        ),
      );
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      appBar: AppBar(
        title: Text(widget.room.nickname),
      ),

      body: Column(
        children: [

          // ✅ 게시물 미리보기 영역 (상단바 아래 따로 배치)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 30),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "심부름 게시글 제목 더미 데이터",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "게시글 설명이 이 위치에 들어갑니다.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ✅ 메시지 영역 (중앙 흰색)
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: messages[index]);
                },
              ),
            ),
          ),

          // ✅ 입력창 영역 (배경색 구분)
          Container(
            color: AppTheme.inputBarColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "메시지 입력",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
