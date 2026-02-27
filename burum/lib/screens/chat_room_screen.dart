import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/chat_room.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;

  ChatRoomScreen({required this.room});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<Message> messages = [];
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
    markAsRead();
  }

  Future<void> fetchMessages() async {
    final response = await http.get(
      Uri.parse(
          "http://localhost:3000/api/chat/messages/${widget.room.roomId}"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        messages =
            data.map((json) => Message.fromJson(json)).toList();
      });
    }
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    await http.post(
      Uri.parse("http://localhost:3000/api/chat/message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "chatRoomId": widget.room.roomId,
        "senderId": 1,
        "content": controller.text.trim(),
      }),
    );

    controller.clear();
    fetchMessages();
  }

  Future<void> markAsRead() async {
    await http.post(
      Uri.parse("http://localhost:3000/api/chat/read"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "roomId": widget.room.roomId,
        "userId": 1,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.nickname)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return MessageBubble(
                  message: message,
                  isMe: message.senderId == 1,
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: controller,
                    decoration:
                        InputDecoration(hintText: "메시지를 입력하세요"),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: sendMessage,
              ),
            ],
          )
        ],
      ),
    );
  }
}