import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../chat_config.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int userId;

  const ProfileDetailScreen({super.key, required this.userId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic>? user;
  List createdPosts = [];
  List assignedPosts = [];

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$kBaseUrl/api/users/profile/${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          user = data['user'];
          createdPosts = data['createdPosts'] ?? [];
          assignedPosts = data['assignedPosts'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("fetchProfile error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildProfileImage() {
    final imageUrl = user?['profile_image_url'];

    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return CircleAvatar(
        radius: 42,
        backgroundColor: Colors.amber[100],
        child: Text(
          (user?['nickname'] ?? '?').toString().isNotEmpty
              ? (user?['nickname'] ?? '?').toString()[0]
              : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 42,
      backgroundImage: NetworkImage("$kBaseUrl$imageUrl"),
    );
  }

  Widget buildPostCard(Map<String, dynamic> post) {
    final imageUrl = post['image_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E6E6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null && imageUrl.toString().isNotEmpty
                ? Image.network(
                    "$kBaseUrl$imageUrl",
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 54,
                      height: 54,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: Colors.grey[200],
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? '제목 없음',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "비용: ${post['cost'] ?? 0}원",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "상태: ${post['status'] ?? '-'}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, List items, {String emptyText = '데이터가 없습니다.'}) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(color: Colors.black54),
            )
          else
            ...items.map((e) => buildPostCard(Map<String, dynamic>.from(e))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF78D),
        surfaceTintColor: const Color(0xFFFFF78D),
        centerTitle: true,
        title: const Text(
          '프로필',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('프로필 정보를 불러오지 못했습니다.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            buildProfileImage(),
                            const SizedBox(height: 14),
                            Text(
                              user?['nickname'] ?? '알 수 없음',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4B0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user?['user_title'] ?? 'BURUM 사용자',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "등급: ${user?['grade'] ?? '새싹'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?['location'] ?? '위치 정보 없음',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      buildSection(
                        '심부름 맡긴 게시물',
                        createdPosts,
                        emptyText: '아직 등록한 게시물이 없습니다.',
                      ),
                      buildSection(
                        '심부름 맡은 게시물',
                        assignedPosts,
                        emptyText: '아직 맡은 게시물이 없습니다.',
                      ),
                    ],
                  ),
                ),
    );
  }
}