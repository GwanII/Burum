import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../chat_config.dart';
import '../models/chat_room.dart';
import '../widgets/chat_tile.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> chatRooms = [];
  bool isLoading = true;
  bool showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
  }

  Future<void> fetchChatRooms() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("$kBaseUrl/api/chat/rooms/$kCurrentUserId"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final rooms = data.map((json) => ChatRoom.fromJson(json)).toList();

        rooms.sort((a, b) {
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }

          final aTime = DateTime.tryParse(a.lastMessageTime ?? '');
          final bTime = DateTime.tryParse(b.lastMessageTime ?? '');

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        setState(() {
          chatRooms = rooms;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchChatRooms error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> leaveRoom(int roomId) async {
    await http.delete(
      Uri.parse("$kBaseUrl/api/chat/rooms/$roomId?userId=$kCurrentUserId"),
    );
    await fetchChatRooms();
  }

  Future<void> markRoomAsRead(int roomId) async {
    await http.post(
      Uri.parse("$kBaseUrl/api/chat/read"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "roomId": roomId,
        "userId": kCurrentUserId,
      }),
    );
    await fetchChatRooms();
  }

  Future<void> togglePin(ChatRoom room) async {
    await http.patch(
      Uri.parse("$kBaseUrl/api/chat/rooms/${room.roomId}/pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": kCurrentUserId,
        "isPinned": !room.isPinned,
      }),
    );
    await fetchChatRooms();
  }

  Future<void> showRoomOptions(ChatRoom room) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  room.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(room.isPinned ? '상단 고정 해제' : '상단 고정'),
                onTap: () async {
                  Navigator.pop(context);
                  await togglePin(room);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mark_chat_read_outlined),
                title: const Text('읽음 처리'),
                onTap: () async {
                  Navigator.pop(context);
                  await markRoomAsRead(room.roomId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  '채팅방 나가기',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('채팅방 나가기'),
                      content: const Text('정말 이 채팅방에서 나가시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('나가기'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await leaveRoom(room.roomId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = showUnreadOnly
        ? chatRooms.where((room) => room.unreadCount > 0).toList()
        : chatRooms;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF78D),
        surfaceTintColor: const Color(0xFFFFF78D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "채팅",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchChatRooms,
              child: filteredRooms.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('안 읽음'),
                                selected: showUnreadOnly,
                                selectedColor: const Color(0xFFFFF78D),
                                checkmarkColor: Colors.black87,
                                side: BorderSide(
                                  color: showUnreadOnly
                                      ? const Color(0xFFE6D95B)
                                      : Colors.grey.shade300,
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    showUnreadOnly = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 180),
                        Center(
                          child: Text(
                            showUnreadOnly
                                ? "안 읽은 채팅이 없습니다."
                                : "채팅방이 없습니다.",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('안 읽음'),
                                selected: showUnreadOnly,
                                selectedColor: const Color(0xFFFFF78D),
                                checkmarkColor: Colors.black87,
                                side: BorderSide(
                                  color: showUnreadOnly
                                      ? const Color(0xFFE6D95B)
                                      : Colors.grey.shade300,
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    showUnreadOnly = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...filteredRooms.map(
                          (room) => Dismissible(
                            key: ValueKey('room_${room.roomId}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await showRoomOptions(room);
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.grey.shade200,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.more_horiz),
                                  SizedBox(width: 6),
                                  Text('옵션'),
                                ],
                              ),
                            ),
                            child: ChatTile(
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
                              onLongPress: () => showRoomOptions(room),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}