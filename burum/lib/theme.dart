import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFFF78D);
  static const Color secondaryColor = Color(0xFFFFD54F);
  static const Color backgroundColor = Color(0xFFFFFDE7);

  // 메시지 색상 수정
  static const Color myMessageColor = Color(0xFFFFF176); // 노랑
  static const Color otherMessageColor = Color(0xFFF1F3F5); // 연한 회색 (흰색 아님)

  // 입력창 배경색
  static const Color inputBarColor = Color(0xFFFFF3B0);

  // 공통 브랜드/포인트 색상
  static const Color pointOrange = Color(0xFFFF7E36); // 주요 오렌지색
  static const Color pointMint = Color(0xFF5ADBB5); // 민트색

  // 텍스트 필드 및 버튼 배경색
  static const Color textFieldBackground = Color(0xFFF8F8F8);
  static const Color buttonGrey = Color(0xFFE8E8E8);
  static const Color lightGrey = Color(0xFFF5F5F5);

  // 소셜 로그인 버튼 색상
  static const Color googleButtonColor = Color(0xFFF2F2F2);
  static const Color kakaoButtonColor = Color(0xFFFEE500);
  static const Color naverButtonColor = Color(0xFF03C75A);

  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      foregroundColor: Colors.black,
    ),
  );
}
