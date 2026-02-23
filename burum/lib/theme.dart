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
