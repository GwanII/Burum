import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'mapScreen.dart';
import 'myPageScreen.dart';
import 'postDetailScreen.dart';
import 'writerDetailPage.dart';
import '../config.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _posts = [];
  List<String> _trendingTags = [];
  bool _isLoading = true;

  String currentLoggedInUser = "";
  String currentUserId = "";
  final storage = const FlutterSecureStorage();

  // ⚠️ 중요: 환경에 맞춰 주석 해제 (지금은 크롬/웹 기준)
  //final String baseUrl = "http://localhost:3000/api";
  // final String baseUrl = "http://10.0.2.2:3000/api"; // 안드로이드 에뮬레이터용

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    _fetchAllData();
  }

  Future<void> _loadUserNickname() async {
    final token =
        await storage.read(key: 'accessToken') ??
        await storage.read(key: 'FlutterSecureStorage.accessToken');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/posts/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentLoggedInUser = data['nickname'] ?? "";
          currentUserId = data['id']?.toString() ?? data['user_id']?.toString() ?? "";
        });
      } else {
        print("서버 응답 에러: ${response.statusCode}");
      }
    } catch (e) {
      print("닉네임 통신 에러: $e");
    }
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchPosts(), _fetchTrendingTags()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/api/posts'));
      if (response.statusCode == 200) {
        setState(() {
          _posts = json.decode(response.body);
        });
      }
    } catch (e) {
      print('게시글 로드 실패: $e');
    }
  }

  Future<void> _fetchTrendingTags() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/api/posts/trending')); 
      if (response.statusCode == 200) {
        setState(() {
          _trendingTags = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('태그 로드 실패: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')} 마감';
    } catch (e) {
      return '';
    }
  }

  List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    try {
      if (tags is List) return List<String>.from(tags);
      if (tags is String) return List<String>.from(jsonDecode(tags));
      return [];
    } catch (e) {
      return [];
    }
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyPageScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Possible',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 검색창
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: '찾는 심부름을 검색해보세요!',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    suffixIcon: Icon(Icons.search, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 인기 태그 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔥 실시간 급상승 태그',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _trendingTags.isEmpty
                      ? const Text(
                          "태그 없음",
                          style: TextStyle(color: Colors.grey),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildTagList(0, 3),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildTagList(3, 6),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5), height: 40),

            // 게시글 리스트 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '추천 심부름',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: _posts.map((post) {
                            return Column(
                              children: [
                                _buildErrandItem(
                                  // 🌟 핵심 추가 포인트 1: 백엔드 데이터에서 ID 뽑아내기
                                  // 서버가 id, post_id, _id 중 무엇을 쓸지 몰라 방어적으로 작성했습니다.
                                  postId: post['id']?.toString() ?? post['post_id']?.toString() ?? post['_id']?.toString() ?? '',
                                  title: post['title'] ?? '',
                                  desc: post['content'] ?? '',
                                  price: '${post['cost']}원',
                                  deadlineInfo: _formatDate(post['deadline']),
                                  nickname: post['nickname'] ?? '익명',
                                  tags: _parseTags(post['tags']),
                                  imageUrl: post['image_url'],
                                ),
                                const Divider(
                                  color: Colors.grey,
                                  thickness: 0.5,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapScreen()),
          );
        },
        backgroundColor: const Color(0xFFFFF59D),
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.map_outlined, color: Colors.black),
        label: const Text(
          '지도로 보기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _buildTagList(int start, int end) {
    List<Widget> list = [];
    for (int i = start; i < end; i++) {
      if (i < _trendingTags.length) {
        list.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${i + 1}  ${_trendingTags[i]}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    }
    return list;
  }

  Widget _buildErrandItem({
    required String postId, // 🌟 핵심 추가 포인트 2: 파라미터로 postId 받기
    required String title,
    required String desc,
    required String price,
    required String deadlineInfo,
    required String nickname,
    required List<String> tags,
    String? imageUrl,
  }) {
    return InkWell(
      onTap: () {
        print('====================================');
        print('👉 내 닉네임(currentLoggedInUser) : [$currentLoggedInUser]');
        print('👉 게시글 작성자(nickname) : [$nickname]');
        print('👉 둘이 완전히 똑같은가요? : ${nickname == currentLoggedInUser}');
        print('====================================');

        if (currentLoggedInUser.isNotEmpty && nickname == currentLoggedInUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => writerDetailPage(
                // 💡 만약 내가 쓴 글 페이지에서도 수정/삭제를 위해 postId가 필요하다면
                // writerDetailPage 파일에 들어가서 postId 변수를 추가해주셔야 합니다!
                postId: postId, 
                title: title,
                content: desc,
                price: price,
                date: deadlineInfo,
                nickname: nickname,
                tags: tags,
                imageUrl: imageUrl,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: postId, // 🌟 핵심 추가 포인트 3: PostDetailScreen으로 postId 넘겨주기!
                title: title,
                content: desc,
                currentUserId: currentUserId,
                price: price,
                date: deadlineInfo,
                nickname: nickname,
                tags: tags,
                imageUrl: imageUrl,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 박스
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.hardEdge,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                      size: 30,
                    ),
            ),
            const SizedBox(width: 15),
            // 텍스트 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...tags.map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$deadlineInfo | $nickname',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}