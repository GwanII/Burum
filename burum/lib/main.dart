import 'package:flutter/material.dart';
import 'screens/chat_list_screen.dart';
import 'theme.dart';

void main() {
  runApp(const BurumApp());
}

class BurumApp extends StatelessWidget {
  const BurumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const ChatListScreen(),
    );
  }
}
