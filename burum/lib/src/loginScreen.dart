import 'package:burum/src/locationScreen.dart';
import 'package:burum/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_Screen.dart';
import 'signupScreen.dart';
import 'findPasswordScreen.dart'; // 새로 만든 파일 임포트
import '../config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isAutoLogin = false;

  final storage = const FlutterSecureStorage();

  String _loadingType = '';

  // 백엔드 API 호출 로직
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('아이디(이메일)와 비밀번호를 모두 입력해주세요.');
      return;
    }

    setState(() {
      _loadingType = 'normal';
    });

    final url = Uri.parse('${Config.baseUrl}/api/users/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'autoLogin': _isAutoLogin, // 🌟 자동 로그인 여부 전송
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _handleLoginSuccess(responseData);
      } else {
        _showMessage(responseData['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (error) {
      print('서버 통신 에러: $error');
      _showMessage('서버와 연결할 수 없습니다. 네트워크를 확인해주세요.');
    } finally {
      // 에러가 뜨더라도 이 코드는 실행된다
      if (mounted) {
        setState(() {
          _loadingType = '';
        });
      }
    }
  }

  // 구글 로그인 객체 생성
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInit = false;

  @override
  void initState() {
    super.initState();
    _initGoogle();
    _checkAutoLogin(); // 화면 시작 시 자동 로그인 검사 실행
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 앱 구동 시 refreshToken을 확인하고 백엔드에 토큰 재발급 요청
  Future<void> _checkAutoLogin() async {
    final refreshToken = await storage.read(key: 'refreshToken');

    if (refreshToken != null) {
      setState(() {
        _loadingType = 'autoLogin';
      });

      try {
        final url = Uri.parse('${Config.baseUrl}/api/users/refresh');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          await _handleLoginSuccess(responseData); // 성공 시 바로 화면 이동
        } else {
          // 토큰 만료 또는 유효하지 않은 경우 스토리지 비우기
          await storage.deleteAll();
          if (mounted) setState(() => _loadingType = '');
        }
      } catch (e) {
        print('자동 로그인 에러: $e');
        if (mounted) setState(() => _loadingType = '');
      }
    }
  }

  Future<void> _initGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '1024833914093-ij5n6egqq31ibs4q9naivrrinqagc7pm.apps.googleusercontent.com', // 보안 위험!! .env 파일이나 Config 클래스로 옮기는게 좋을듯
      );
      _isGoogleInit = true;
    } catch (e) {
      print('구글 로그인 초기화 실패: $e');
    }
  }

  // 소셜 로그인 API 호출 로직
  Future<void> _socialLogin(String provider) async {
    setState(() {
      _loadingType = provider;
    });

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
      } finally {
        if (mounted) {
          setState(() {
            _loadingType = '';
          });
        }
      }
    } else {
      _showMessage('$provider 작업 중!');
      setState(() {
        _loadingType = '';
      });
    }
  }

  // 구글 로그인 API
  Future<void> _sendGoogleTokenToBackend(String idToken) async {
    final url = Uri.parse('${Config.baseUrl}/api/users/google-login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'autoLogin': _isAutoLogin, // 🌟 구글 로그인 시에도 자동 로그인 옵션 전달
        }),
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

        // 다은 작업 ** 채팅 화면에서 현재 로그인한 유저를 구분하기 위해 userId 저장
        final userId =
          responseData['userId'] ??
          responseData['id'] ??
         (responseData['user'] != null ? responseData['user']['id'] : null);

        if (userId != null) {
         await storage.write(key: 'userId', value: userId.toString());
        }
        //여기까징

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
      print('백엔드 통신 에러: $err');
      _showMessage('서버와 연결할 수 없습니다. 백엔드가 켜져있는지 확인해주세요.');
    }
  }

  // 로그인 성공 후 공통 처리 로직 (토큰 저장 및 화면 이동)
  Future<void> _handleLoginSuccess(Map<String, dynamic> responseData) async {
    final accessToken = responseData['accessToken'];
    final refreshToken = responseData['refreshToken'];
    // 토큰이 없는 경우 예외 처리
    if (accessToken == null || refreshToken == null) {
      _showMessage('로그인에 실패했습니다. (토큰 오류)');
      return;
    }

    await storage.write(key: 'accessToken', value: accessToken);
    await storage.write(key: 'refreshToken', value: refreshToken);

  // 다은 작업 **채팅 화면에서 현재 로그인한 유저를 구분하기 위해 userId 저장
  final userId =
      responseData['userId'] ??
      responseData['id'] ??
      (responseData['user'] != null ? responseData['user']['id'] : null);

  if (userId != null) {
    await storage.write(key: 'userId', value: userId.toString());
  }
  // 여기까징 

    if (!mounted) return;

    final bool requiresLocation = responseData['requiresLocation'] ?? false;

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
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
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
    // 🌟 자동 로그인이 진행 중일 때, 깜빡임 방지를 위해 전체 화면 로딩 띄우기
    if (_loadingType == 'autoLogin') {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7E36)),
        ),
      );
    }

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
              _buildTextField(
                '비밀번호',
                _passwordController,
                _isPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),

              // 자동 로그인 체크박스 및 비밀번호 찾기 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isAutoLogin,
                        onChanged: (value) {
                          setState(() {
                            _isAutoLogin = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFFF7E36),
                      ),
                      Text(
                        '자동 로그인',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      '비밀번호를 잊으셨나요?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),

              _buildRectButton(
                '로그인',
                _loadingType.isNotEmpty ? null : _login,
                Color(0xFFE8E8E8),
                Colors.black,
                isLoading: _loadingType == 'normal',
              ),
              SizedBox(height: 12),

              // 🌟 회원가입 화면으로 이동하는 버튼
              _buildRectButton(
                '회원가입',
                _loadingType.isNotEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
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
                _loadingType.isNotEmpty ? null : () => _socialLogin('Google'),
                isLoading: _loadingType == 'Google',
              ),
              SizedBox(height: 12),
              _buildRoundedButton(
                '카카오로 계속하기',
                Color(0xFFFEE500),
                Colors.black87,
                _loadingType.isNotEmpty ? null : () => _socialLogin('Kakao'),
                isLoading: _loadingType == 'Kakao',
              ),
              SizedBox(height: 12),
              _buildRoundedButton(
                '네이버로 계속하기',
                Color(0xFF03C75A),
                Colors.white,
                _loadingType.isNotEmpty ? null : () => _socialLogin('Naver'),
                isLoading: _loadingType == 'Naver',
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
    bool obscureText, {
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Color(0xFFFF7E36), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildRectButton(
    String text,
    VoidCallback? onPressed,
    Color bgColor,
    Color textColor, {
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                // 빙글빙글 도는 애니메이션 (로딩)
                color: textColor,
                strokeWidth: 2.0,
              ),
            )
          : Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }

  Widget _buildRoundedButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback? onPressed, {
    bool isLoading = false,
  }) {
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
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: textColor,
                strokeWidth: 2.0,
              ),
            )
          : Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
    );
  }
}
