import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final String baseUrl = "http://localhost:3000/api/users";
  // final String baseUrl = "http://10.0.2.2:3000/api/users"; // 안드로이드 에뮬레이터용

  final maskFormatter = MaskTextInputFormatter(
    mask: '###-####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Future<void> _signup() async {
    final String nickname = _nicknameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String phone = _phoneController.text.trim();

    // 빈칸 검사
    if (nickname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty) {
      _showMessage('모든 항목을 입력해주세요.');
      return;
    }

    final url = Uri.parse('$baseUrl/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nickname': nickname,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      print('${response.body}');

      final responseData = jsonDecode(response.body);

      // 가입 성공 시 201 상태 코드 보냄
      if (response.statusCode == 201) {
        _showMessage('회원가입이 완료되었습니다!');
        // 가입 성공 시 뒤로가기(로그인 화면으로 복귀)
        Navigator.pop(context);
      } else {
        _showMessage(responseData['message'] ?? '회원가입 실패');
      }
    } catch (error) {
      print(error);
      _showMessage('서버와 연결할 수 없습니다.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          '회원가입',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BURUM과 함께\n따뜻한 거래를 시작해보세요!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            SizedBox(height: 30),

            _buildTextField('닉네임 (앱에서 사용할 이름)', _nicknameController, false),
            SizedBox(height: 12),
            _buildTextField('이메일 주소', _emailController, false),
            SizedBox(height: 12),
            _buildTextField('비밀번호', _passwordController, true),
            SizedBox(height: 12),
            _buildTextField(
              '전화번호 (숫자만 입력)',
              _phoneController,
              false,
              keyboardType: TextInputType.phone,
              inputFormatters: [maskFormatter],
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF7E36),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                '가입하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    bool isPassword, {
    TextInputType keyboardType = TextInputType.text, // 숫자 키보드 띄우기
    List<TextInputFormatter>? inputFormatters, // 하이픈 자동 완성 마스크 씌우기
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
}
