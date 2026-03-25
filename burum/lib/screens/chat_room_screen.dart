import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../chat_config.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../services/socket_service.dart';
import '../widgets/message_bubble.dart';
import 'profile_detail_screen.dart';
import '../src/postDetailScreen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatRoomScreen({super.key, required this.room,});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<Message> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final SocketService socketService = SocketService();

  bool isSending = false;
  bool isUploadingImage = false;
  bool isFetchingMessages = false;

  @override
  void initState() {
    super.initState();

    socketService.connect(kBaseUrl, kCurrentUserId);
    socketService.joinRoom(widget.room.roomId);

    socketService.on('newMessage', (data) async {
      if (!mounted || data == null) return;
      if (data is! Map) return;

      final map = Map<String, dynamic>.from(data);
      if (map['chat_room_id'] != widget.room.roomId) return;

      final incomingId = map['id'];
      final alreadyExists = messages.any((m) => m.id == incomingId);
      if (alreadyExists) return;

      setState(() {
        messages.add(Message.fromJson(map));
      });

      // 내가 현재 이 방에 있으니 들어온 메시지는 바로 읽음 처리
      await markAsRead();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _scrollToBottom(animated: true);
      });
    });

    socketService.on('messagesRead', (data) async {
      if (!mounted || data == null) return;
      if (data is! Map) return;

      final map = Map<String, dynamic>.from(data);
      if (map['roomId'] != widget.room.roomId) return;

      // 내가 읽은 이벤트는 무시
      if (map['userId'] == kCurrentUserId) return;

      // 상대가 읽었으면 서버의 최신 is_read 값 다시 조회
      await fetchMessages(refreshOnly: true);
    });

    fetchMessages();
    markAsRead();
  }

  @override
  void dispose() {
    socketService.leaveRoom(widget.room.roomId);
    socketService.off('newMessage');
    socketService.off('messagesRead');
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void openProfileDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          userId: widget.room.otherUserId,
        ),
      ),
    );
  }

  bool get hasPostPreview {
    return (widget.room.postId != null) ||
        (widget.room.postTitle != null &&
            widget.room.postTitle!.trim().isNotEmpty) ||
        (widget.room.postImage != null &&
            widget.room.postImage!.trim().isNotEmpty) ||
        (widget.room.postContent != null &&
            widget.room.postContent!.trim().isNotEmpty) ||
        (widget.room.postCost != null);
  }

  Future<void> _scrollToBottom({bool animated = true}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!scrollController.hasClients) return;

    final maxScroll = scrollController.position.maxScrollExtent;

    if (animated) {
      await scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(maxScroll);
    }
  }

  Future<void> fetchMessages({bool refreshOnly = false}) async {
    if (isFetchingMessages) return;

    isFetchingMessages = true;

    try {
      final response = await http.get(
        Uri.parse("$kBaseUrl/api/chat/messages/${widget.room.roomId}"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (!mounted) return;

        final fetchedMessages =
            data.map((json) => Message.fromJson(json)).toList();

        setState(() {
          messages = fetchedMessages;
        });

        if (!refreshOnly) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _scrollToBottom(animated: true);
          });
        }
      }
    } catch (e) {
      debugPrint("fetchMessages error: $e");
    } finally {
      isFetchingMessages = false;
    }
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty || isSending) return;

    final content = controller.text.trim();

    setState(() {
      isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$kBaseUrl/api/chat/message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatRoomId": widget.room.roomId,
          "senderId": kCurrentUserId,
          "content": content,
        }),
      );

      if (response.statusCode == 200) {
        controller.clear();
      } else {
        debugPrint("sendMessage failed: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('메시지 전송에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      debugPrint("sendMessage error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지 전송 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 데이터를 불러오지 못했습니다.')),
          );
        }
        return;
      }

      setState(() {
        isUploadingImage = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$kBaseUrl/api/chat/image"),
      )
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

      if (response.statusCode != 200) {
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
    try {
      await http.post(
        Uri.parse("$kBaseUrl/api/chat/read"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "roomId": widget.room.roomId,
          "userId": kCurrentUserId,
        }),
      );
    } catch (e) {
      debugPrint("markAsRead error: $e");
    }
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
    if (!hasPostPreview) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: widget.room.postId.toString(), // 추가했어연 -기완
              currentUserId: kCurrentUserId.toString(), // 추가했어연 -기완
              title: widget.room.postTitle ?? '게시물 정보 없음',
              content: widget.room.postContent ?? '내용 없음',
              price: '${widget.room.postCost ?? 0}',
              date: widget.room.postDeadline ?? '',
              nickname: widget.room.otherUserNickname,
              tags: const [],
              imageUrl: widget.room.postImage,
            ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "비용: ${widget.room.postCost ?? 0}원",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
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

  Widget buildProfileAvatar() {
    final imageUrl = widget.room.otherUserProfileImage;

    return GestureDetector(
      onTap: openProfileDetail,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage("$kBaseUrl$imageUrl"),
            )
          : CircleAvatar(
              radius: 18,
              backgroundColor: Colors.amber[100],
              child: Text(
                widget.room.otherUserNickname.isNotEmpty
                    ? widget.room.otherUserNickname[0]
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildProfileAvatar(),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: openProfileDetail,
              child: Text(
                widget.room.otherUserNickname,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
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
                            otherUserProfileImage:
                                widget.room.otherUserProfileImage,
                            formattedTime: formatTime(message.time),
                            onOtherUserTap: openProfileDetail,
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