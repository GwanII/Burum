import 'package:flutter/material.dart';
import '../chat_config.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String otherUserNickname;
  final String formattedTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserNickname,
    required this.formattedTime,
  });

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = "$kBaseUrl${message.imageUrl}";

    return GestureDetector(
      onTap: () => _openFullScreenImage(context, imageUrl),
      child: Hero(
        tag: imageUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 180,
              height: 140,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: message.type == "image"
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: message.type == "image"
            ? Colors.transparent
            : (isMe ? Colors.amber[200] : Colors.white),
        borderRadius: BorderRadius.circular(14),
      ),
      child: message.type == "image"
          ? _buildImage(context)
          : Text(
              message.content ?? "",
              style: const TextStyle(fontSize: 15),
            ),
    );

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.isRead ? '읽음' : '안읽음',
                  style: TextStyle(
                    fontSize: 11,
                    color: message.isRead ? Colors.black54 : Colors.grey,
                    fontWeight:
                        message.isRead ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 6),
            bubble,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.amber[100],
            child: Text(
              otherUserNickname.isNotEmpty ? otherUserNickname[0] : '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUserNickname,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bubble,
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}