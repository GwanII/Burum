import 'package:burum/src/loginScreen.dart';
import 'package:burum/src/main_Screen.dart';
import 'package:flutter/material.dart';
import 'src/main_Screen.dart'; // 👈 방금 만든 파일을 여기서 불러옵니다!
import 'src/createErrandScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Burum Demo',
      theme: ThemeData(
        // 앱 전체 테마 설정
        primaryColor: const Color(0xFFFFF59D),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // 홈 화면으로 아까 만든 HomeScreen을 보여줘라!
      home: const CreateErrandsPage(),
    );
  }
}
