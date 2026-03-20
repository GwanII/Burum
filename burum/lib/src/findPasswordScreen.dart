import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../config.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  _FindPasswordScreenState createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final maskFormatter = MaskTextInputFormatter(
    mask: '###-####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Future<void> _findPassword() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();

    // 이메일 유효성 검사
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    if (email.isEmpty) {
      setState(() => _errorMessage = '이메일 주소를 입력해주세요.');
      return;
    } else if (!emailValid) {
      setState(() => _errorMessage = '올바른 이메일 형식을 입력해주세요.');
      return;
    }

    // 전화번호 검사 (숫자만 추출하여 11자리인지 확인)
    final String rawPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      setState(() => _errorMessage = '전화번호를 입력해주세요.');
      return;
    } else if (rawPhone.length != 11) {
      setState(() => _errorMessage = '전화번호는 11자리 숫자로 입력해주세요.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final url = Uri.parse('${Config.baseUrl}/api/users/reset-password');

    try {
      // 실제 백엔드에 맞게 요청 형식을 수정 가능
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        _showMessage('입력하신 이메일로 비밀번호 재설정 안내를 보냈습니다.');
        if (mounted) Navigator.pop(context); // 이전 화면(로그인)으로 복귀
      } else {
        final responseData = jsonDecode(response.body);
        _showMessage(responseData['message'] ?? '가입된 이메일을 찾을 수 없습니다.');
      }
    } catch (error) {
      print('서버 통신 에러: $error');
      _showMessage('서버와 연결할 수 없습니다. 네트워크를 확인해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '가입하신 이메일 주소를\n입력해 주세요.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '해당 이메일로 임시 비밀번호를 보내드립니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
              decoration: InputDecoration(
                hintText: '이메일 주소',
                errorText: _errorMessage,
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF7E36),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              inputFormatters: [maskFormatter],
              keyboardType: TextInputType.phone,
              onChanged: (_) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
              decoration: InputDecoration(
                hintText: '휴대폰 번호 (숫자만 입력)',
                errorText: _errorMessage,
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF7E36),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _findPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E36),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text(
                      '비밀번호 찾기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
