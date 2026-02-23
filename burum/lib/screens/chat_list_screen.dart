import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../widgets/chat_tile.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentIndex = 1;
  bool showUnreadOnly = false;

  List<ChatRoom> chatRooms = [
    ChatRoom(
      id: "1",
      nickname: "홍길동",
      profileImage: "",
      lastMessage: "안녕하세요!",
      unreadCount: 2,
    ),
    ChatRoom(
      id: "2",
      nickname: "김철수",
      profileImage: "",
      lastMessage: "거래 가능할까요?",
      unreadCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<ChatRoom> filtered = showUnreadOnly
        ? chatRooms.where((c) => c.unreadCount > 0).toList()
        : chatRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text("채팅"),
      ),

      // ✅ 중앙 흰색
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ✅ 안 읽음 버튼 스타일
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showUnreadOnly = !showUnreadOnly;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: showUnreadOnly
                          ? Colors.amber[200]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("안 읽음"),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final room = filtered[index];

                  return Dismissible(
                    key: Key(room.id),
                    background: slideLeftBackground(),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => buildOptionSheet(room),
                      );
                      return false;
                    },
                    child: ChatTile(
                      room: room,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatRoomScreen(room: room),
                          ),
                        );
                      },
                      onUpdate: () {
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ✅ 하단바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "채팅"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "심부름"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "캘린더"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이"),
        ],
      ),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.grey[300],
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.more_horiz),
    );
  }

  Widget buildOptionSheet(ChatRoom room) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            title: const Text("상단 고정"),
            onTap: () {
              setState(() {
                room.isPinned = !room.isPinned;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("읽기 처리"),
            onTap: () {
              setState(() {
                room.unreadCount = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("채팅방 나가기"),
            onTap: () {
              setState(() {
                chatRooms.remove(room);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
