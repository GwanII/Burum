import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mapScreen.dart'; // mapScreen.dart 파일이 같은 폴더에 있어야 합니다.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // 데이터 담을 변수들
  List<dynamic> _posts = [];
  List<String> _trendingTags = [];
  bool _isLoading = true;

  // ⚠️ 중요: 본인 환경에 맞는 주석을 해제해서 쓰세요!
  // [옵션 1] 웹(Chrome), iOS 시뮬레이터용
  final String baseUrl = "http://localhost:3000/api";
  // [옵션 2] 안드로이드 에뮬레이터용
  // final String baseUrl = "http://10.0.2.2:3000/api";

  @override
  void initState() {
    super.initState();
    // 앱 켜지자마자 데이터 2개(목록, 태그) 동시에 가져오기
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchPosts(),
      _fetchTrendingTags(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  // 1. 심부름 게시글 목록 가져오기
  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));
      if (response.statusCode == 200) {
        setState(() {
          _posts = json.decode(response.body);
        });
      }
    } catch (e) {
      print('게시글 로드 실패: $e');
    }
  }

  // 2. 실시간 인기 태그 가져오기
  Future<void> _fetchTrendingTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/trending'));
      if (response.statusCode == 200) {
        setState(() {
          _trendingTags = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('태그 로드 실패: $e');
    }
  }

  // 날짜 포맷팅 함수 (2026-03-02T18:00... -> 3/2 18:00 마감)
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '마감일 미정';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')} 마감';
    } catch (e) {
      return '';
    }
  }

  // 태그 파싱 함수 (DB에서 온 JSON 문자열을 리스트로 변환)
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
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: Colors.black12, height: 1.0)),
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
            
            // [섹션 1] 인기 급상승 해시태그 (최근 1시간 Top 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥 실시간 급상승 태그 (최근 1시간)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  _trendingTags.isEmpty
                      ? const Text("최근 등록된 태그가 없어요.", style: TextStyle(color: Colors.grey))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 왼쪽 컬럼 (1~3위)
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildTagList(0, 3))),
                            const SizedBox(width: 20),
                            // 오른쪽 컬럼 (4~6위)
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildTagList(3, 6))),
                          ],
                        ),
                ],
              ),
            ),
            
            const Divider(thickness: 8, color: Color(0xFFF5F5F5), height: 40),

            // [섹션 2] 심부름 리스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('“케로로”님 추천 심부름', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _posts.isEmpty
                          ? const Center(child: Text("등록된 심부름이 없습니다."))
                          : Column(
                              children: _posts.map((post) {
                                return Column(
                                  children: [
                                    _buildErrandItem(
                                      color: Colors.blueAccent,
                                      title: post['title'] ?? '제목 없음',
                                      desc: post['content'] ?? '내용 없음',
                                      price: '${post['cost']}원',
                                      deadlineInfo: _formatDate(post['deadline']), // 마감 시간 변환
                                      nickname: post['nickname'] ?? '익명',
                                      tags: _parseTags(post['tags']), // 태그 파싱
                                    ),
                                    const Divider(color: Colors.grey, thickness: 0.5),
                                  ],
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      // 하단바 및 FAB
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
        backgroundColor: const Color(0xFFFFF176),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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

  // 인기 태그 리스트 조각 만드는 함수
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

  // 게시글 아이템 디자인
  Widget _buildErrandItem({
    required Color color,
    required String title,
    required String desc,
    required String price,
    required String deadlineInfo,
    required String nickname,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 영역
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.person, color: color, size: 40),
          ),
          const SizedBox(width: 15),

          // 텍스트 내용 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 제목 + 태그 (한 줄에)
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                // 2. 내용
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // 3. 가격 + 마감시간
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