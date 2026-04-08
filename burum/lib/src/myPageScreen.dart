import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart'; // 🌟 Dio 예외 처리를 위해 추가!
import 'loginScreen.dart';
import '../dio_client.dart'; // 🌟 우리의 전담 우체부 모셔오기!

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

  // 🌟 심폐소생술 1: DioClient를 적용하여 확 짧아진 프로필 조회 함수!
  Future<void> fetchProfile() async {
    try {
      // 💡 토큰 꺼내서 헤더에 넣는 귀찮은 작업은 DioClient가 알아서 해줍니다!
      // BaseUrl도 DioClient 안에 설정되어 있을 테니 뒷부분(경로)만 적어주면 됩니다.
      final response = await DioClient.instance.get('/api/posts/profile');

      setState(() {
        // 백엔드에서 어떻게 주느냐에 따라 맞춰서 꺼내 쓰세요!
        nickname = response.data['nickname'] ?? "닉네임 없음";
        isLoading = false;
      });
    } on DioException catch (e) {
      // 서버 터미널 대신 앱 콘솔에 예쁘게 에러를 찍어줍니다.
      print("서버 응답 에러: ${e.response?.statusCode} - ${e.message}");
      setState(() {
        nickname = e.response?.statusCode == 401
            ? "로그인 필요"
            : "인증 오류(${e.response?.statusCode})";
        isLoading = false;
      });
    } catch (e) {
      print("통신 에러: $e");
      setState(() {
        nickname = "연결 실패";
        isLoading = false;
      });
    }
  }

  // 🌟 심폐소생술 2: 로그아웃 함수도 간결하게!
  Future<void> _logout() async {
    try {
      // 백엔드에 로그아웃 요청 (이것도 DioClient가 토큰 챙겨서 갑니다)
      await DioClient.instance.post('/api/users/logout');
    } catch (e) {
      print('백엔드 로그아웃 통신 에러 (이미 만료되었거나 서버 문제): $e');
      // 백엔드 통신에 실패하더라도, 앱 내 로그아웃은 진행해야 하므로 멈추지 않습니다!
    }

    // 기기에 저장된 모든 토큰 삭제
    await storage.deleteAll();

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
