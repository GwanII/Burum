import 'package:flutter/material.dart';
import 'mapScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 하단 탭 선택 상태

  // 하단 탭 클릭 시 실행되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. 상단 앱바 (Possible)
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176), // 피그마의 진한 노란색
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black12, height: 1.0), // 하단 구분선
        ),
      ),

      // 2. 메인 내용 (스크롤 가능)
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // [검색창 영역]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: '찾는 심부름을 검색해보세요!',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    suffixIcon: Icon(Icons.search, color: Colors.black),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // [인기 급상승 해시태그 영역]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.pinkAccent),
                      SizedBox(width: 8),
                      Text(
                        '인기 급상승 해시태그',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // 해시태그 리스트 (2열 배치)
                  Row(
                    children: [
                      Expanded( // 공간을 반반 나누고 싶으면 Expanded를 씌우세요
                        flex: 1, 
                        child: _buildHashtagColumn(['1  #곰팡이', '2  #벌레', '3  #청소']),
                      ),
                      const SizedBox(width: 20), 

                      Expanded(
                        flex: 1,
                        child: _buildHashtagColumn(['4  #이사', '5  #약', '6  #운전']),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5), height: 40),

            // [추천 심부름 리스트 영역]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '“케로로”님 추천 심부름',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 리스트 아이템들
                  _buildErrandItem(
                    color: Colors.orange, // 이미지 대신 색상
                    title: '카레 가져다주기 #배달',
                    desc: '고씨네에서 카레 포장해서 가져다 주시면 됩니다!!',
                    price: '5000원',
                    info: '1시간 남음!! | 500m',
                  ),
                  _buildDivider(),
                  _buildErrandItem(
                    color: Colors.blue,
                    title: '수리검 표적지 만들기 #제작',
                    desc: '도로로가 사용할 수리검 표적지 만들어서 50장 정도 인쇄해주시면 가질러 가겠습니다.',
                    price: '5000원',
                    info: '2일 남음!! | 700m',
                  ),
                  _buildDivider(),
                  _buildErrandItem(
                    color: Colors.red,
                    title: '헬스 보조해주기 #헬스',
                    desc: '헬스 보조 해주실분 구합니다. 밥도 사드립니다.',
                    price: '만나서 합의',
                    info: '3시간 남음!! | 700m',
                  ),
                   _buildDivider(),
                  _buildErrandItem(
                    color: Colors.yellow,
                    title: '햄스터 산책 시키기 #동물',
                    desc: '햄스터 산책 시켜주실 분 구합니다.',
                    price: '7000원',
                    info: '1일 남음!! | 1KM',
                  ),
                  const SizedBox(height: 20),
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
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        backgroundColor: const Color(0xFFFFF59D), 
        // 그림자: 너무 진하지 않게 설정
        elevation: 4, 
        // 모양: 완전 둥근 알약 모양 (기본값이지만 명시)
        shape: const StadiumBorder(), 
        // 아이콘: 검정색
        icon: const Icon(Icons.map_outlined, color: Colors.black), 
        // 글자: 검정색, 굵게
        label: const Text(
          '지도로 보기',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      // 👆 여기까지

      // 3. 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 아이템이 4개 이상일 때 필수
        backgroundColor: const Color(0xFFFFF176), // 배경 노란색
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
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

  // [위젯 함수] 해시태그 컬럼 생성기
  Widget _buildHashtagColumn(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags
          .map((tag) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ))
          .toList(),
    );
  }

  // [위젯 함수] 리스트 아이템 생성기
  Widget _buildErrandItem({
    required Color color,
    required String title,
    required String desc,
    required String price,
    required String info,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 이미지 영역 (지금은 색깔 박스로 대체)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3), // 연한 배경
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.person, color: color, size: 40), 
          ),
          const SizedBox(width: 15),

          // 2. 텍스트 정보 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      info,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  // [위젯 함수] 구분선
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Divider(color: Colors.grey, thickness: 0.5),
    );
  }
}