import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateErrandsPage extends StatefulWidget {
  const CreateErrandsPage({super.key});

  @override
  State<CreateErrandsPage> createState() => _CreateErrandsPageState();
}

class _CreateErrandsPageState extends State<CreateErrandsPage> {
  int _selectedIndex = 2;

  final Color mainYellow = const Color(0xFFFFF59D);
  final Color inputGrey = const Color(0xFFD9D9D9);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(); // 스키마엔 없지만 UI용

  Future<void> _submitErrand() async {
    final url = Uri.parse('http://localhost:3000/api');

    final requestData = {
      "user": 1, 
      "title": _titleController.text,
      "context": "${_contextController.text}\n(장소: ${_locationController.text})",
      "cost": int.tryParse(_costController.text),
      "deadline": "2026-12-31 23:59:59",
      "tags": ["심부름", "테스트"],
      "image_url": "https://example.com/no-image.png"
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData), // JSON으로 압축
      );

      if (response.statusCode == 201) {
        print("등록 성공");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('심부름 등록 성공')),
          );
          Navigator.pop(context); // 이전 페이지로 복귀
        }
      } else {
        print("상태 코드: ${response.statusCode}");
      }
    } catch (e) {
      print("에러: $e");
    }
  }

  // 메모리 누수를 막는 청소 마법이래.
  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _dateController.dispose();
    _contextController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('내 심부름', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 48, color: Colors.black54),
                  SizedBox(height: 8),
                  Text('사진을 넣어주세요', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            _buildCustomTextField('제목을 입력해주세요', _titleController),
            const SizedBox(height: 12),
            const Row(
              children: [
                Text('AI ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('가격 추천', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildCustomTextField('가격을 입력해주세요', _costController, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildCustomTextField('날짜를 입력해주세요', _dateController)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _contextController, 
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: '내용을 입력해주세요',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (index) => 
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(20)),
                    child: const Text('+ 해시태그', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  )
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildCustomTextField('장소를 입력 해주세요', _locationController)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 40, color: Colors.black),
              ],
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitErrand, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainYellow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('작성 완료', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: mainYellow,
        child: BottomNavigationBar(
          backgroundColor: mainYellow,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            setState(() { _selectedIndex = index; });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: '심부름'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '캘린더'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이'),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField(String hint, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller, 
        keyboardType: isNumber ? TextInputType.number : TextInputType.text, 
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}