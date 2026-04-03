import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';
import '../models/chat_room.dart';
import '../services/socket_service.dart';
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

  final SocketService socketService = SocketService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  int? currentUserId;
  bool socketConnected = false;

  @override
  void initState() {
    super.initState();

    socketService.on('chatRoomUpdated', (_) {
      fetchChatRooms(showLoading: false);
    });

    socketService.on('chatRoomCreated', (_) {
      fetchChatRooms(showLoading: false);
    });

    socketService.on('chatRoomDeleted', (_) {
      fetchChatRooms(showLoading: false);
    });

    socketService.on('chatRoomPinned', (_) {
      fetchChatRooms(showLoading: false);
    });

    _initializeChatList();
  }

  Future<void> _initializeChatList() async {
    final userIdString = await storage.read(key: 'userId');
    final parsedUserId = int.tryParse(userIdString ?? '');

    if (!mounted) return;

    if (parsedUserId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    currentUserId = parsedUserId;

    socketService.connect(Config.baseUrl, currentUserId!);
    socketConnected = true;

    await fetchChatRooms();
  }

  @override
  void dispose() {
    socketService.off('chatRoomUpdated');
    socketService.off('chatRoomCreated');
    socketService.off('chatRoomDeleted');
    socketService.off('chatRoomPinned');
    super.dispose();
  }

    Future<void> fetchChatRooms({bool showLoading = true}) async {
  if (currentUserId == null) return;

  if (showLoading && mounted) {
    setState(() {
      isLoading = true;
    });
  }

  try {
    final url = "${Config.baseUrl}/api/chat/rooms/$currentUserId";
    print('채팅방 조회 URL = $url');

    final response = await http.get(Uri.parse(url));

    print('응답 상태코드 = ${response.statusCode}');
    print('응답 headers = ${response.headers}');
    print('응답 body = ${response.body}');

    if (response.statusCode != 200) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      return;
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      print('JSON 아님! content-type = $contentType');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      return;
    }

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

    if (!mounted) return;

    setState(() {
      chatRooms = rooms;
      isLoading = false;
    });
  } catch (e) {
    debugPrint('fetchChatRooms error: $e');
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> leaveRoom(int roomId) async {
    if (currentUserId == null) return;

    await http.delete(
      Uri.parse("$Config.baseUrl/api/chat/rooms/$roomId?userId=$currentUserId"),
    );
    await fetchChatRooms(showLoading: false);
  }

  Future<void> markRoomAsRead(int roomId) async {
    if (currentUserId == null) return;

    await http.post(
      Uri.parse("$Config.baseUrl/api/chat/read"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "roomId": roomId,
        "userId": currentUserId,
      }),
    );
    await fetchChatRooms(showLoading: false);
  }

  Future<void> togglePin(ChatRoom room) async {
    if (currentUserId == null) return;

    await http.patch(
      Uri.parse("$Config.baseUrl/api/chat/rooms/${room.roomId}/pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": currentUserId,
        "isPinned": !room.isPinned,
      }),
    );
    await fetchChatRooms(showLoading: false);
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

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인 사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
        ),
      );
    }

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
      body: RefreshIndicator(
        onRefresh: () => fetchChatRooms(showLoading: false),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              builder: (_) => ChatRoomScreen(
                                room: room,
                                currentUserId: currentUserId!,
                              ),
                            ),
                          );
                          fetchChatRooms(showLoading: false);
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