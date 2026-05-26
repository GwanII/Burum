import 'package:flutter/material.dart';
import 'homeScreen.dart';
import 'myPageScreen.dart';
import '../screens/chat_list_screen.dart';
import 'calendarScreen.dart';
import 'package:burum/screens/errand_management_screen.dart';

// ㅁㄴㅇㄻㄴㅇㄻㄴㅇㄹㄴㅁㅇㅁㄹㄴㅇㄹ
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. 현재 선택된 탭 번호 (처음엔 0번인 '홈'으로 시작)
  int _selectedIndex = 0;

  // 🌟 화면 새로고침을 위한 Key 들
  // 탭을 다시 누를 때마다 UniqueKey()를 갱신하여 강제로 DB를 새로고침하게 만듭니다.
  Key _homeKey = UniqueKey();
  Key _errandKey = UniqueKey();
  Key _calendarKey = UniqueKey();
  Key _myPageKey = UniqueKey();

  // 2. 탭을 누를 때마다 보여줄 알맹이 화면들 리스트!
  List<Widget> get _screens => [
    HomeScreen(key: _homeKey), // 0번 탭 (홈)
    ChatListScreen(), // 1번 탭 (채팅)
    ErrandManagementScreen(key: _errandKey), // 2번 탭 (심부름)
    CalendarScreen(key: _calendarKey), // 3번 탭 (캘린더)
    MyPageScreen(key: _myPageKey), // 4번 탭 (마이페이지)
  ];

  // 3. 탭을 클릭했을 때 실행되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // 🌟 핵심: 탭을 누를 때마다 해당 탭의 Key를 갱신하여 화면을 완전히 새로 그립니다!
      if (index == 0) {
        _homeKey = UniqueKey();
      } else if (index == 2) {
        _errandKey = UniqueKey();
      } else if (index == 3) {
        _calendarKey = UniqueKey();
      } else if (index == 4) {
        _myPageKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. 여기가 핵심! IndexedStack을 쓰면 화면을 전환해도 이전 상태(스크롤 등)가 유지됩니다.
      body: IndexedStack(index: _selectedIndex, children: _screens),

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
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: '심부름',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
