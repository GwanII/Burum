import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/chat_room.dart';
import '../widgets/chat_tile.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> chatRooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
  }

  Future<void> fetchChatRooms() async {
    final response = await http.get(
      Uri.parse("http://localhost:3000/chat/rooms/1"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        chatRooms =
            data.map((json) => ChatRoom.fromJson(json)).toList();
        isLoading = false;
      });
    }
  }

  Future<void> deleteRoom(int roomId) async {
    await http.delete(
      Uri.parse("http://localhost:3000/chat/rooms/$roomId"),
    );

    fetchChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("채팅")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatRooms[index];

                return ChatTile(
                  room: room,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(room: room),
                      ),
                    );

                    fetchChatRooms();
                  },
                  onLongPress: () => deleteRoom(room.roomId),
                );
              },
            ),
    );
  }
}