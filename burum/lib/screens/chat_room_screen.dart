import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../chat_config.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<Message> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isSending = false;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
    markAsRead();
  }

  Future<void> _scrollToBottom({bool animated = true}) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (!scrollController.hasClients) return;

    final position = scrollController.position.maxScrollExtent;

    if (animated) {
      await scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(position);
    }
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse("$kBaseUrl/api/chat/messages/${widget.room.roomId}"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          messages = data.map((json) => Message.fromJson(json)).toList();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _scrollToBottom(animated: true);
        });
      }
    } catch (e) {
      debugPrint("fetchMessages error: $e");
    }
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await http.post(
        Uri.parse("$kBaseUrl/api/chat/message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatRoomId": widget.room.roomId,
          "senderId": kCurrentUserId,
          "content": controller.text.trim(),
        }),
      );

      controller.clear();
      await fetchMessages();
      await markAsRead();
      await _scrollToBottom(animated: true);
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> pickAndSendImage() async {
    if (isUploadingImage) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      final Uint8List? bytes = pickedFile.bytes;

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 데이터를 불러오지 못했습니다.')),
        );
        return;
      }

      setState(() {
        isUploadingImage = true;
      });

      final uri = Uri.parse("$kBaseUrl/api/chat/image");
      final request = http.MultipartRequest('POST', uri)
        ..fields['chatRoomId'] = widget.room.roomId.toString()
        ..fields['senderId'] = kCurrentUserId.toString()
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: pickedFile.name.isNotEmpty ? pickedFile.name : 'image.jpg',
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await fetchMessages();
        await markAsRead();
        await _scrollToBottom(animated: true);
      } else {
        debugPrint('image upload failed: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 전송에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      debugPrint('pickAndSendImage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  Future<void> markAsRead() async {
    await http.post(
      Uri.parse("$kBaseUrl/api/chat/read"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "roomId": widget.room.roomId,
        "userId": kCurrentUserId,
      }),
    );
  }

  String formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatDateLabel(DateTime time) {
    final local = time.toLocal();
    return '${local.year}년 ${local.month}월 ${local.day}일';
  }

  bool shouldShowDateDivider(int index) {
    if (index == 0) return true;

    final current = messages[index].time.toLocal();
    final previous = messages[index - 1].time.toLocal();

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget buildDateDivider(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget buildPostCard() {
    if (widget.room.postTitle == null && widget.room.postImage == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DummyPostDetailScreen(room: widget.room),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.room.postImage != null &&
                      widget.room.postImage!.isNotEmpty
                  ? Image.network(
                      "$kBaseUrl${widget.room.postImage}",
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(Icons.inventory_2_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '관련 심부름 게시물',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.room.postTitle ?? '게시물 정보 없음',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = isSending || isUploadingImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF78D),
        surfaceTintColor: const Color(0xFFFFF78D),
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DummyProfileDetailScreen(room: widget.room),
              ),
            );
          },
          child: Text(
            widget.room.otherUserNickname,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          buildPostCard(),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text("아직 메시지가 없습니다."),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      return Column(
                        children: [
                          if (shouldShowDateDivider(index))
                            buildDateDivider(formatDateLabel(message.time)),
                          MessageBubble(
                            message: message,
                            isMe: message.senderId == kCurrentUserId,
                            otherUserNickname: widget.room.otherUserNickname,
                            formattedTime: formatTime(message.time),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: IconButton(
                      icon: isUploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: Colors.black87,
                            ),
                      onPressed: isBusy ? null : pickAndSendImage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "메시지를 입력하세요",
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: IconButton(
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.black87),
                      onPressed: isBusy ? null : sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DummyProfileDetailScreen extends StatelessWidget {
  final ChatRoom room;

  const DummyProfileDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: const Color(0xFFFFF78D),
        surfaceTintColor: const Color(0xFFFFF78D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.amber[100],
              child: Text(
                room.otherUserNickname.isNotEmpty
                    ? room.otherUserNickname[0]
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              room.otherUserNickname,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '임시 프로필 상세 화면입니다.\n백엔드가 연결되면 사용자 소개, 평점, 거래 이력 등을 표시할 수 있습니다.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DummyPostDetailScreen extends StatelessWidget {
  final ChatRoom room;

  const DummyPostDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물 상세'),
        backgroundColor: const Color(0xFFFFF78D),
        surfaceTintColor: const Color(0xFFFFF78D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.postImage != null && room.postImage!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  "$kBaseUrl${room.postImage}",
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.inventory_2_outlined, size: 40),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              room.postTitle ?? '게시물 제목 없음',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '임시 게시물 상세 화면입니다.\n백엔드가 연결되면 심부름 내용, 가격, 위치, 작성자 정보 등을 표시할 수 있습니다.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}