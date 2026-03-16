import 'package:burum/src/locationScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_Screen.dart';
import 'signupScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final storage = const FlutterSecureStorage();

   final String baseUrl = "http://localhost:3000/api/users";
  //final String baseUrl = "http://10.0.2.2:3000/api/users"; // 안드로이드 에뮬레이터용

  // 백엔드 API 호출 로직
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('아이디(이메일)와 비밀번호를 모두 입력해주세요.');
      return;
    }

    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        await storage.write(key: 'accessToken', value: accessToken);
        await storage.write(key: 'refreshToken', value: refreshToken);

        final bool requiresLocation = responseData['requiresLocation'] ?? false;

        if (requiresLocation) {
          _showMessage('동네 설정이 필요합니다.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LocationScreen()),
          );
        } else {
          _showMessage('BURUM에 오신 것을 환영합니다! ');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      } else {
        _showMessage(responseData['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (error) {
      print('서버 통신 에러: $error');
      _showMessage('서버와 연결할 수 없습니다. 네트워크를 확인해주세요.');
    }
  }

  // 구글 로그인 객체 생성
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInit = false;

  @override
  void initState() {
    super.initState();
    _initGoogle();
  }

  Future<void> _initGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '1024833914093-ij5n6egqq31ibs4q9naivrrinqagc7pm.apps.googleusercontent.com',
      );
      _isGoogleInit = true;
    } catch (e) {
      print('구글 로그인 초기화 실패: $e');
    }
  }

  // 소셜 로그인 API 호출 로직
  Future<void> _socialLogin(String provider) async {
    if (provider == 'Google') {
      // 초기화가 안 끝났는데 버튼을 눌렀다면, 끝날 때까지 기다림
      if (!_isGoogleInit) {
        await _initGoogle();
      }

      try {
        // 구글 로그인 창 띄우기
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
          scopeHint: ['email', 'profile'],
        );

        // 2. 구글 서버로부터 인증 정보(영수증) 받아오기
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final String? idToken = googleAuth.idToken;

        if (idToken != null) {
          // 성공! 백엔드로 보낼 준비 완료
          print('구글 영수증(idToken) 발급 성공: $idToken');
          _showMessage('구글 로그인 성공! 서버와 연동 중...');

          await _sendGoogleTokenToBackend(idToken);
        } else {
          _showMessage('구글 인증 정보를 가져올 수 없습니다.');
        }
      } catch (error) {
        print('구글 로그인 에러: $error');

        if (error.toString().contains('canceled') ||
            error.toString().contains('sign_in_canceled')) {
          _showMessage('구글 로그인이 취소되었습니다.');
        } else {
          _showMessage('구글 로그인 중 오류가 발생했습니다.');
        }
      }
    } else {
      _showMessage('$provider 작업 중!');
    }
  }

  // 구글 로그인 API
  Future<void> _sendGoogleTokenToBackend(String idToken) async {
    final url = Uri.parse('$baseUrl/google-login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        final nickname = responseData['nickname'] ?? '익명';

        final bool requiresLocation = responseData['requiresLocation'] ?? false;

        await storage.write(key: 'accessToken', value: accessToken);
        await storage.write(key: 'refreshToken', value: refreshToken);
        await storage.write(key: 'nickname', value: nickname);

        if (requiresLocation) {
          _showMessage('동네 설정이 필요합니다.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LocationScreen()),
          );
        } else {
          _showMessage('BURUM에 오신 것을 환영합니다!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        _showMessage(responseData['message'] ?? '구글 로그인 처리에 실패했습니다.');
      }
    } catch (err) {
      print('백엔드 통신 에러: $errorPropertyTextConfiguration');
      _showMessage('서버와 연결할 수 없습니다. 백엔드가 켜져있는지 확인해주세요.');
    }
  }

  // 화면 하단에 알림 메시지를 띄우는 공통 함수
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 72,
                color: Color(0xFFFF7E36),
              ),
              SizedBox(height: 16),
              Text(
                'BURUM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 40),

              _buildTextField('아이디 또는 이메일', _emailController, false),
              SizedBox(height: 12),
              _buildTextField('비밀번호', _passwordController, true),
              SizedBox(height: 20),

              _buildRectButton('로그인', _login, Color(0xFFE8E8E8), Colors.black),
              SizedBox(height: 12),

              // 🌟 회원가입 화면으로 이동하는 버튼
              _buildRectButton(
                '회원가입',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
                Color(0xFFF5F5F5),
                Colors.black54,
              ),

              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Divider(thickness: 1, color: Colors.grey[300]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '간편 로그인',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Divider(thickness: 1, color: Colors.grey[300]),
                  ),
                ],
              ),
              SizedBox(height: 30),

              _buildRoundedButton(
                '구글로 계속하기',
                Color(0xFFF2F2F2),
                Colors.black87,
                () => _socialLogin('Google'),
              ),
              SizedBox(height: 12),
              _buildRoundedButton(
                '카카오로 계속하기',
                Color(0xFFFEE500),
                Colors.black87,
                () => _socialLogin('Kakao'),
              ),
              SizedBox(height: 12),
              _buildRoundedButton(
                '네이버로 계속하기',
                Color(0xFF03C75A),
                Colors.white,
                () => _socialLogin('Naver'),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    bool isPassword,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildRectButton(
    String text,
    VoidCallback onPressed,
    Color bgColor,
    Color textColor,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildRoundedButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
