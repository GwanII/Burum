import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mapScreen.dart'; // 같은 폴더에 mapScreen.dart가 있어야 해요!

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

  // ⚠️ 중요: 환경에 맞춰 주석 해제 (지금은 크롬/웹 기준)
  final String baseUrl = "http://localhost:3000/api"; 
  // final String baseUrl = "http://10.0.2.2:3000/api"; // 안드로이드 에뮬레이터용

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchPosts(), _fetchTrendingTags()]);
    setState(() { _isLoading = false; });
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));
      if (response.statusCode == 200) {
        setState(() { _posts = json.decode(response.body); });
      }
    } catch (e) { print('게시글 로드 실패: $e'); }
  }

  Future<void> _fetchTrendingTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/trending'));
      if (response.statusCode == 200) {
        setState(() { _trendingTags = List<String>.from(json.decode(response.body)); });
      }
    } catch (e) { print('태그 로드 실패: $e'); }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')} 마감';
    } catch (e) { return ''; }
  }

  List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    try {
      if (tags is List) return List<String>.from(tags);
      if (tags is String) return List<String>.from(jsonDecode(tags));
      return [];
    } catch (e) { return []; }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
        centerTitle: true,
        title: const Text('Possible', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  const Text('🔥 실시간 급상승 태그', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _trendingTags.isEmpty
                      ? const Text("태그 없음", style: TextStyle(color: Colors.grey))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildTagList(0, 3))),
                            const SizedBox(width: 20),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildTagList(3, 6))),
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
                  const Text('추천 심부름', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: _posts.map((post) {
                            return Column(
                              children: [
                                _buildErrandItem(
                                  title: post['title'] ?? '',
                                  desc: post['content'] ?? '',
                                  price: '${post['cost']}원',
                                  deadlineInfo: _formatDate(post['deadline']),
                                  nickname: post['nickname'] ?? '익명',
                                  tags: _parseTags(post['tags']),
                                  imageUrl: post['image_url'], // 이미지 URL 전달
                                ),
                                const Divider(color: Colors.grey, thickness: 0.5),
                              ],
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 80), // 하단 버튼에 가려지지 않게 여백 추가
                ],
              ),
            ),
          ],
        ),
      ),

      // 👇 [복구 완료!] 지도로 보기 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
        },
        backgroundColor: const Color(0xFFFFF59D),
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.map_outlined, color: Colors.black),
        label: const Text('지도로 보기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: '심부름'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이'),
        ],
      ),
    );
  }

  // 태그 리스트 생성 함수
  List<Widget> _buildTagList(int start, int end) {
    List<Widget> list = [];
    for (int i = start; i < end; i++) {
      if (i < _trendingTags.length) {
        list.add(Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text('${i + 1}  ${_trendingTags[i]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ));
      }
    }
    return list;
  }

  // 게시글 아이템 (이미지 포함 버전)
  Widget _buildErrandItem({
    required String title,
    required String desc,
    required String price,
    required String deadlineInfo,
    required String nickname,
    required List<String> tags,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 박스
          Container(
            width: 80, height: 80,
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
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 15),
          // 텍스트 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    ...tags.map((tag) => Padding(padding: const EdgeInsets.only(right: 4.0), child: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('$deadlineInfo | $nickname', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
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