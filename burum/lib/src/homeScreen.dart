import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // 💡 http 대신 Dio 추가!
import 'dart:convert'; // _parseTags에서 혹시 모를 String 파싱을 위해 남겨둠
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'mapScreen.dart';
import 'myPageScreen.dart';
import 'postDetailScreen.dart';
import 'writerDetailPage.dart';
// import '../config.dart'; // 🗑️ DioClient 내부에서 이미 BaseUrl을 쓰고 있으므로 여기선 필요 없음!
import '../dio_client.dart'; // 🌟 우리의 행동대장 DioClient 호출!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _posts = []; // API에서 받아온 원본 데이터 보관
  List<dynamic> _filteredPosts = []; // 🌟 화면에 보여줄(검색 필터링된) 데이터
  List<String> _trendingTags = [];
  bool _isLoading = true;

  // 🌟 검색어를 다루기 위한 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  String currentLoggedInUser = "";
  String currentUserId = "";
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    _fetchAllData();
  }

  @override
  void dispose() {
    // 🌟 메모리 누수 방지를 위해 컨트롤러 닫기
    _searchController.dispose();
    super.dispose();
  }

  // 🌟 변경 포인트 1: 닉네임 로드
  Future<void> _loadUserNickname() async {
    try {
      final response = await DioClient.instance.get('/api/posts/profile');
      final data = response.data;
      setState(() {
        currentLoggedInUser = data['nickname'] ?? "";
        currentUserId =
            data['id']?.toString() ?? data['user_id']?.toString() ?? "";
      });
    } on DioException catch (e) {
      print("닉네임 통신 에러(Dio): ${e.response?.statusCode} - ${e.message}");
    } catch (e) {
      print("닉네임 통신 에러(기타): $e");
    }
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchPosts(), _fetchTrendingTags()]);
    setState(() {
      _isLoading = false;
    });
  }

  // 🌟 변경 포인트 2: 게시글 목록 로드 및 초기 필터 설정
  Future<void> _fetchPosts() async {
    try {
      final response = await DioClient.instance.get('/api/posts');
      setState(() {
        _posts = response.data;
        _filteredPosts = _posts; // 🌟 처음엔 전체 리스트를 보여주기 위해 그대로 복사!
      });
    } catch (e) {
      print('게시글 로드 실패: $e');
    }
  }

  Future<void> _fetchTrendingTags() async {
    try {
      final response = await DioClient.instance.get('/api/posts/trending');
      setState(() {
        _trendingTags = List<String>.from(response.data);
      });
    } catch (e) {
      print('태그 로드 실패: $e');
    }
  }

  // 🌟 [추가된 기능] 검색 필터링 로직!
  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      // 검색어가 비어있으면 원본 리스트 전체 보여주기
      results = _posts;
    } else {
      // 대소문자 구분 없이 검색하기 위해 toLowerCase() 사용
      results = _posts.where((post) {
        final title = (post['title'] ?? '').toLowerCase();
        final content = (post['content'] ?? '').toLowerCase();
        final keyword = enteredKeyword.toLowerCase();

        // 제목이나 내용에 검색어가 포함되어 있으면 리스트에 남김
        return title.contains(keyword) || content.contains(keyword);
      }).toList();
    }

    // 화면 갱신
    setState(() {
      _filteredPosts = results;
    });
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

            // 🌟 검색창 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      _runFilter(value), // 🌟 타이핑할 때마다 필터링 함수 실행!
                  decoration: const InputDecoration(
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
                      : _filteredPosts
                            .isEmpty // 🌟 검색 결과가 없을 때 처리
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              '검색 결과가 없습니다 🥲',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          // 🌟 이제 원본 _posts가 아니라 _filteredPosts를 그립니다!
                          children: _filteredPosts.map((post) {
                            return Column(
                              children: [
                                _buildErrandItem(
                                  postId:
                                      post['id']?.toString() ??
                                      post['post_id']?.toString() ??
                                      post['_id']?.toString() ??
                                      '',
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
    required String postId,
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
        if (currentLoggedInUser.isNotEmpty && nickname == currentLoggedInUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => writerDetailPage(
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
                postId: postId,
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
