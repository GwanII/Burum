import 'package:burum/screens/chat_list_screen.dart';
import 'package:burum/src/homeScreen.dart';
import 'dart:async';
import 'package:burum/src/loginScreen.dart';
import 'package:burum/src/main_Screen.dart';
import 'package:flutter/material.dart';
import 'src/main_Screen.dart'; // 👈 방금 만든 파일을 여기서 불러옵니다!
import 'src/createErrandScreen.dart';
import 'src/calendarScreen.dart';
import 'auth_service.dart';
import 'navigator_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    // 앱 전역에서 인증 상태 변화를 감지하는 리스너 설정
    _authSubscription = AuthService.instance.authStatusStream.listen((status) {
      if (status == AuthStatus.unauthenticated) {
        // 리프레시 토큰 만료 이벤트가 발생하면 로그인 화면으로 강제 이동
        // 현재 앱이 띄워져 있는 최상단 네비게이션 컨텍스트 가져옴
        final context = NavigatorService.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('세션이 만료되어 다시 로그인해야 합니다.')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 앱 종료 시 리스너 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 네비게이션을 위한 GlobalKey 연결. UI 계층 내에서만 사용됩니다.
      navigatorKey: NavigatorService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Burum Demo',
      theme: ThemeData(
        // 앱 전체 테마 설정
        primaryColor: const Color(0xFFFFF59D),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // 홈 화면으로 아까 만든 HomeScreen을 보여줘라!
      home: const LoginScreen(),
    );
  }
}
