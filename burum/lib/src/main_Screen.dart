import 'package:flutter/material.dart';
import 'homeScreen.dart';
import 'myPageScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. 현재 선택된 탭 번호 (처음엔 0번인 '홈'으로 시작)
  int _selectedIndex = 0;

  // 2. 탭을 누를 때마다 보여줄 알맹이 화면들 리스트!
  // (나중에 채팅, 심부름, 캘린더 화면을 만들면 여기에 쏙쏙 넣으시면 됩니다)
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('채팅 화면 (준비중)')), // 1번 탭 (임시)
    const Center(child: Text('심부름 화면 (준비중)')), // 2번 탭 (임시)
    const Center(child: Text('캘린더 화면 (준비중)')), // 3번 탭 (임시)
    const MyPageScreen(), // 4번 탭 (마이페이지)
  ];

  // 3. 탭을 클릭했을 때 실행되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 번호만 싹 바꿔줍니다
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. 여기가 핵심! IndexedStack을 쓰면 화면을 전환해도 이전 상태(스크롤 등)가 유지됩니다.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      
      // 5. 하단 네비게이션 바는 여기서 딱 한 번만 그립니다!
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFF176), // 앱의 메인 노란색
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
}