// 모바일에서 사진 가져올람 dart:io가 필요한데 얘가 웹에서는 움직이질 않노;;
// 그래서 웹으로 작업할 땐 관련 코드 싹다 봉인해놨음.
// 실사용 때는 봉인을 '해제' 해야함.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:flutter/services.dart'; 
import 'homeScreen.dart'; 
import 'postDetailScreen.dart';

// import 'dart:io'; // 💡 웹 에러의 원흉인 File 마법을 임시 봉인하오!
// 이미지이미지이미지이미지이미지이미지이미지
// import 'package:image_picker/image_picker.dart'; // 💡 사진 찍기 마법도 임시 봉인하오!
// 이미지이미지이미지이미지이미지이미지이미지

// 🌟🌟🌟 천 단위로 쉼표(,)를 팍팍 찍어주는 요정!!!!! 🌟🌟🌟
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericString.isEmpty) return newValue.copyWith(text: '');
    
    final buffer = StringBuffer();
    for (int i = 0; i < numericString.length; i++) {
      if (i > 0 && (numericString.length - i) % 3 == 0) buffer.write(',');
      buffer.write(numericString[i]);
    }
    final formattedString = buffer.toString();
    return newValue.copyWith(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}

class CreateErrandsPage extends StatefulWidget {
  const CreateErrandsPage({super.key});

  @override
  State<CreateErrandsPage> createState() => _CreateErrandsPageState();
}

class _CreateErrandsPageState extends State<CreateErrandsPage> {
  final Color mainYellow = const Color(0xFFFFF59D);
  final Color inputGrey = const Color(0xFFD9D9D9);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _contentController = TextEditingController(); 
  final TextEditingController _locationController = TextEditingController(); 
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];

  List<String> _selectedImages = []; 
  // 이미지이미지이미지이미지이미지이미지이미지
  
  Future<void> _pickImages() async {
    setState(() {
      int remainingSlots = 10 - _selectedImages.length;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진은 최대 10장까지만')),
        );
        return;
      }
      _selectedImages.add('https://picsum.photos/100/100?random=${DateTime.now().millisecondsSinceEpoch}');
    });
  }
  // 이미지이미지이미지이미지이미지이미지이미지
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2999), 
    );
    if (picked != null) {
      setState((){
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} 23:59:59";
      });
    }
  }

  void _addTag(String value) {
    if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
      setState(() {
        _tags.add(value.trim());
        _tagController.clear(); 
      });
    }
  }
  
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // 🚨 [경고 팝업 소환 마법!!!!!]
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ 등록 실패', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🚀 [진짜 토큰 & 장소/내용 분리형 궁극의 대포!!!!!]
  Future<void> _submitErrand() async {
    if (_titleController.text.length > 40) {
      _showErrorPopup('제목은 40자를 초과할 수 없소!!!!!\n(현재: ${_titleController.text.length}자)');
      return;
    }
    if (_contentController.text.length > 500) {
      _showErrorPopup('내용은 500자를 초과할 수 없소!!!!!\n(현재: ${_contentController.text.length}자)');
      return;
    }

    const storage = FlutterSecureStorage();
    String? myAccessToken = await storage.read(key: 'accessToken');
    //추가 ?
    String? myUserId = await storage.read(key: 'userId'); 
    String? myNickname = await storage.read(key: 'nickname');

    if (myAccessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이단자여! 로그인을 먼저 하고 오시오!!!!!')),
        );
      }
      return; 
    }

    final url = Uri.parse('http://localhost:3000/api/createErrand');
    var request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $myAccessToken';
    request.fields['title'] = _titleController.text;
    request.fields['content'] = _contentController.text; 
    request.fields['location'] = _locationController.text;     
    
    String rawCost = _costController.text.replaceAll(',', '');
    request.fields['cost'] = rawCost.isEmpty ? '0' : rawCost;
    
    if (_dateController.text.isNotEmpty) {
      request.fields['deadline'] = _dateController.text;
    }
    request.fields['tags'] = jsonEncode(_tags);
    
    request.fields['image_url'] = _selectedImages.isNotEmpty ? _selectedImages.first : "https://example.com/no-image.png";

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse); 

      if (response.statusCode == 201) {
        print("🎉 등록 성공");

        //추가
        var responseData = jsonDecode(response.body);
        String newPostId = responseData['errandId'].toString();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 심부름이 성공적으로 등록되었소!!!!!')),
          );
          
          // 🌟🌟🌟 [개조 완료: 동료 코드 보존을 위한 값 넘기기!!!!!] 🌟🌟🌟
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                //추가
                postId: newPostId,
                currentUserId: myUserId ?? '',
                
                title: _titleController.text,
                content: _contentController.text,
                price: _costController.text.isEmpty ? '0원' : '${_costController.text}원',
                date: _dateController.text.isEmpty ? '마감일 없음' : _dateController.text,
                nickname: '나(작성자)', // 아직 로그인 정보가 없으므로 임시 설정!
                tags: _tags,
                imageUrl: _selectedImages.isNotEmpty ? _selectedImages.first : null,
              ),
            ),
          );
        }
      } else {
        print("적의 방어! 상태 코드: ${response.statusCode}");
        print("에러 내용: ${response.body}"); 
      }
    } catch (e) {
      print("통신망 단절 에러: $e");
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _dateController.dispose();
    _contentController.dispose(); 
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟🌟🌟 [궁극의 결계 PopScope 발동!!!!!] 🌟🌟🌟
    return PopScope(
      canPop: false, // 🛡️ 뒤로 가기를 일단 막아버리오!
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        bool? shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('⚠️ 작성 취소 경고', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            content: const Text('게시물 작성을 취소하시겠습니까?\n작성 중인 내용은 모두 사라집니다!', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('예(나가기)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldLeave == true && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()), 
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: mainYellow,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.maybePop(context); 
            },
          ),
          title: const Text('게시물 생성', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, color: Colors.black54),
                            const SizedBox(height: 4),
                            Text('${_selectedImages.length}/10', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    
                    ..._selectedImages.asMap().entries.map((entry) {
                      int index = entry.key;
                      String fileUrl = entry.value; 
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: NetworkImage(fileUrl), fit: BoxFit.cover), 
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              _buildCustomTextField('제목을 입력해주세요', _titleController, maxLength: 40),
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
                  Expanded(child: _buildCustomTextField('가격을 입력해주세요', _costController, isNumber: true, formatters: [ThousandsSeparatorInputFormatter()])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildCustomTextField('날짜 선택', _dateController),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.only(bottom: 8), 
                child: TextField(
                  controller: _contentController, 
                  maxLines: 5, 
                  maxLength: 500, 
                  decoration: const InputDecoration(
                    hintText: '내용을 입력해주세요',
                    hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '해시태그 입력 후 엔터',
                  filled: true,
                  fillColor: inputGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: _addTag,
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _tags.map((tag) {
                  return InputChip(
                    label: Text(tag),
                    backgroundColor: mainYellow,
                    onDeleted: () => _removeTag(tag),
                  );                
                }).toList(),
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
        
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFF176), 
          selectedItemColor: Colors.black, 
          unselectedItemColor: Colors.black54,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          currentIndex: 2, 
          onTap: (index) {
            if (index == 2) return; 
            
            // 💡 다른 탭을 누르면, 스마트폰의 뒤로 가기를 누른 것과 똑같이 취급하여 팝업을 띄우오!
            Navigator.maybePop(context); 
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

  Widget _buildCustomTextField(String hint, TextEditingController controller, {bool isNumber = false, int? maxLength, List<TextInputFormatter>? formatters}) {
    return Container(
      decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.only(bottom: maxLength != null ? 8 : 0), 
      child: TextField(
        controller: controller, 
        keyboardType: isNumber ? TextInputType.number : TextInputType.text, 
        maxLength: maxLength,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}