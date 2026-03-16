// 모바일에서 사진 가져올람 dart:io가 필요한데 얘가 웹에서는 움직이질 않노;;
// 그래서 웹으로 작업할 땐 관련 코드 싹다 봉인해놨음.
// 실사용 때는 봉인을 '해제' 해야함.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'dart:io'; // 💡 웹 에러의 원흉인 File 마법을 임시 봉인하오!
// 이미지이미지이미지이미지이미지이미지이미지
// import 'package:image_picker/image_picker.dart'; // 💡 사진 찍기 마법도 임시 봉인하오!
// 이미지이미지이미지이미지이미지이미지이미지

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
  // 💡 스펠링 정화 완료! (_contextController -> _contentController)
  final TextEditingController _contentController = TextEditingController(); 
  final TextEditingController _locationController = TextEditingController(); 
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];

  // 💡 File 대신 인터넷 주소(String)를 담는 가짜 창고로 변신!!!!!
  List<String> _selectedImages = []; 
  // 이미지이미지이미지이미지이미지이미지이미지
  
  // final ImagePicker _picker = ImagePicker(); // 봉인!
  // 이미지이미지이미지이미지이미지이미지이미지
  
  Future<void> _pickImages() async {
    // 💡 갤러리를 여는 대신, 누를 때마다 예쁜 무작위 가짜 사진을 추가하오!!!!!
    setState(() {
      int remainingSlots = 10 - _selectedImages.length;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진은 최대 10장까지만')),
        );
        return;
      }
      // 무작위 사진 URL 생성하여 배열에 쏙!
      _selectedImages.add('https://picsum.photos/100/100?random=${DateTime.now().millisecondsSinceEpoch}');
    });
  }
  // 이미지이미지이미지이미지이미지이미지이미지
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  // 이미지이미지이미지이미지이미지이미지이미지

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

  Future<void> _submitErrand() async {
    final url = Uri.parse('http://localhost:3000/api/createErrand');
    var request = http.MultipartRequest('POST', url);
    request.fields['user_id'] = '1';
    request.fields['title'] = _titleController.text;
    
    // 💡 스펠링 정화 완료! 백엔드와 똑같이 'content'라는 이름표를 달아주오!!!!!
    request.fields['content'] = "${_contentController.text}\n(장소: ${_locationController.text})";
    
    request.fields['cost'] = _costController.text.isEmpty ? '0' : _costController.text;
    if (_dateController.text.isNotEmpty) {
      request.fields['deadline'] = _dateController.text;
    }
    request.fields['tags'] = jsonEncode(_tags);
    
    // 💡 [웹 테스트용] 사진 파일을 보내는 대신, 가짜 텍스트 URL 하나만 쓱 밀어 넣소!!!!!
    request.fields['image_url'] = _selectedImages.isNotEmpty ? _selectedImages.first : "https://example.com/no-image.png";
    // 이미지이미지이미지이미지이미지이미지이미지

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse); 

      if (response.statusCode == 201) {
        print("🎉 등록 성공");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 심부름이 성공적으로 등록')),
          );
          Navigator.pop(context); 
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
    _contentController.dispose(); // 💡 여기도 잊지 않고 고쳤소!
    _locationController.dispose();
    _tagController.dispose();
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
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImages,
                    // 이미지이미지이미지이미지이미지이미지이미지
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
                    // 이미지이미지이미지이미지이미지이미지이미지
                    
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: NetworkImage(fileUrl), fit: BoxFit.cover), 
                            // 이미지이미지이미지이미지이미지이미지이미지
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            // 이미지이미지이미지이미지이미지이미지이미지
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
              height: 150,
              decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _contentController, // 💡 여기도 이름이 바뀌었소!!!!!
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