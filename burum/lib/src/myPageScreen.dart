import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'loginScreen.dart';
import '../config.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String nickname = "불러오는 중...";
  bool isLoading = true;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    // 1. 이미 확인하신 방식으로 토큰을 가져옵니다.
    final token =
        await storage.read(key: 'accessToken') ??
        await storage.read(key: 'FlutterSecureStorage.accessToken');

    if (token == null) {
      setState(() {
        nickname = "로그인 필요";
        isLoading = false;
      });
      return;
    }

    try {
      // 2. 크롬이므로 localhost:3000 사용
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/posts/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // 백엔드에서 res.json({ nickname: results[0].nickname }) 으로 보내준다고 가정
          nickname = data['nickname'] ?? "닉네임 없음";
          isLoading = false;
        });
      } else {
        // 서버 터미널에 에러 로그가 찍힐 겁니다.
        print("서버 응답 에러: ${response.statusCode}");
        setState(() {
          nickname = "인증 오류(${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      print("통신 에러: $e");
      setState(() {
        nickname = "연결 실패";
        isLoading = false;
      });
    }
  }

  // 로그아웃 처리 함수
  Future<void> _logout() async {
    // 1. 기기에 저장된 액세스 토큰 읽어오기
    final accessToken = await storage.read(key: 'accessToken');

    // 2. 백엔드에 로그아웃 요청 (DB에서 refreshToken 삭제)
    if (accessToken != null) {
      try {
        final url = Uri.parse('${Config.baseUrl}/api/users/logout');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
      } catch (e) {
        print('백엔드 로그아웃 통신 에러: $e');
      }
    }

    // 3. 기기에 저장된 모든 토큰 삭제
    await storage.deleteAll(); // 저장된 모든 토큰 삭제
    if (!mounted) return;
    // 로그인 화면으로 이동하며 기존 화면 스택(히스토리)을 모두 지움
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF59D),
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFF59D)),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '닉네임',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            nickname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  ListTile(
                    title: const Text("작성한 심부름"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text("완료한 심부름"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      "로그아웃",
                      style: TextStyle(color: Colors.red),
                    ),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('정말 로그아웃 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                '취소',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // 팝업 닫기
                                _logout(); // 로그아웃 실행
                              },
                              child: const Text(
                                '로그아웃',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
