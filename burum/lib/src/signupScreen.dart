import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../dio_client.dart';
import '../theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  final Map<String, String?> _errors = {};
  // 텍스트 필드의 텍스트 숨김 상태
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  final maskFormatter = MaskTextInputFormatter(
    mask: '###-####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 입력 필드 값이 변경될 때 해당 필드의 에러를 지우는 함수
  void _clearError(String key) {
    if (_errors.containsKey(key)) {
      setState(() {
        _errors.remove(key);
      });
    }
  }

  Future<void> _signup() async {
    // 1. 키보드 숨기기
    FocusScope.of(context).unfocus();

    // 2. 에러 상태 초기화
    setState(() {
      _errors.clear();
    });

    final String nickname = _nicknameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String phone = _phoneController.text.trim();

    // 닉네임 검사 (2자 이상 10자 이하)
    if (nickname.isEmpty) {
      _errors['nickname'] = '닉네임을 입력해주세요.';
    } else if (nickname.length < 2 || nickname.length > 10) {
      _errors['nickname'] = '닉네임은 2자 이상 10자 이하로 설정해주세요.';
    }

    // 이메일 형식 검사 (정규식 사용)
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
    if (email.isEmpty) {
      _errors['email'] = '이메일 주소를 입력해주세요.';
    } else if (!emailValid) {
      _errors['email'] = '올바른 이메일 형식을 입력해주세요.';
    }

    // 비밀번호 검사 (8자 이상, 영문 및 숫자 포함)
    final bool passwordValid = RegExp(
      r"^(?=.*[a-zA-Z])(?=.*[0-9]).{8,}$",
    ).hasMatch(password);
    if (password.isEmpty) {
      _errors['password'] = '비밀번호를 입력해주세요.';
    } else if (!passwordValid) {
      _errors['password'] = '비밀번호는 8자 이상, 영문과 숫자를 포함해야 합니다.';
    } else if (password != confirmPassword) {
      _errors['confirmPassword'] = '비밀번호가 일치하지 않습니다.';
    }

    // 전화번호 검사 (숫자만 추출하여 11자리인지 확인)
    final String rawPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      _errors['phone'] = '전화번호를 입력해주세요.';
    } else if (rawPhone.length != 11) {
      _errors['phone'] = '전화번호는 11자리 숫자로 입력해주세요.';
    }

    // 에러가 하나라도 있으면 UI를 다시 그리고 함수를 종료합니다.
    if (_errors.isNotEmpty) {
      setState(() {});
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await DioClient.instance.post(
        '/api/users/signup',
        data: {
          'nickname': nickname,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );

      print('${response.data}');

      // 통신 대기 중 사용자가 화면을 나갔다면 이후 로직 실행 안함
      if (!mounted) return;

      // 가입 성공 시 201 상태 코드 보냄
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showMessage('회원가입이 완료되었습니다!');
        // 가입 성공 시 뒤로가기(로그인 화면으로 복귀)
        Navigator.pop(context);
      } else {
        _showMessage(response.data['message'] ?? '회원가입 실패');
      }
    } on DioException catch (error) {
      print(error);
      if (!mounted) return;
      if (error.response != null) {
        _showMessage(error.response?.data['message'] ?? '회원가입 실패');
      } else {
        _showMessage('서버와 연결할 수 없습니다.');
      }
    } catch (error) {
      print(error);
      if (!mounted) return;
      _showMessage('서버와 연결할 수 없습니다.');
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

            _buildTextField(
              '닉네임 (앱에서 사용할 이름)',
              _nicknameController,
              false,
              errorText: _errors['nickname'],
              onChanged: (value) => _clearError('nickname'),
            ),
            SizedBox(height: 12),
            _buildTextField(
              '이메일 주소',
              _emailController,
              false,
              errorText: _errors['email'],
              onChanged: (value) => _clearError('email'),
            ),
            SizedBox(height: 12),
            _buildTextField(
              '비밀번호',
              _passwordController,
              _isPasswordObscured,
              errorText: _errors['password'],
              onChanged: (value) => _clearError('password'),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            SizedBox(height: 12),
            _buildTextField(
              '비밀번호 확인',
              _confirmPasswordController,
              _isConfirmPasswordObscured,
              errorText: _errors['confirmPassword'],
              onChanged: (value) => _clearError('confirmPassword'),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                  });
                },
              ),
            ),
            SizedBox(height: 12),
            _buildTextField(
              '전화번호 (숫자만 입력)',
              _phoneController,
              false,
              keyboardType: TextInputType.phone,
              inputFormatters: [maskFormatter],
              errorText: _errors['phone'],
              onChanged: (value) => _clearError('phone'),
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pointOrange,
                foregroundColor: Colors.white,
                // disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16),
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
                      '가입하기',
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

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    bool obscureText, {
    String? errorText,
    TextInputType keyboardType = TextInputType.text, // 숫자 키보드 띄우기
    List<TextInputFormatter>? inputFormatters, // 하이픈 자동 완성 마스크 씌우기
    void Function(String)? onChanged, // 입력 변경 콜백 추가
    Widget? suffixIcon, // 우측 아이콘 위젯 추가
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: AppTheme.textFieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppTheme.pointOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}
