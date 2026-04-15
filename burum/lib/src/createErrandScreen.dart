// 모바일에서 사진 가져올 때 dart:io가 필요하지만 웹에서는 동작하지 않습니다.
// 따라서 웹 환경 작업 시에는 관련 코드를 주석 처리합니다.
// 실사용 환경(모바일)에서는 주석을 해제해야 합니다.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'main_Screen.dart';
import 'postDetailScreen.dart';
import '../config.dart';
import '../dio_client.dart'; 

// import 'dart:io'; // 웹 에러 원인인 File 클래스 임시 주석 처리
// import 'package:image_picker/image_picker.dart'; // 사진 선택 기능 임시 주석 처리

// 천 단위 구분 기호 텍스트 포맷터
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

  Future<void> _pickImages() async {
    setState(() {
      int remainingSlots = 10 - _selectedImages.length;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사진은 최대 10장까지만 첨부할 수 있습니다.')));
        return;
      }
      _selectedImages.add(
        'https://picsum.photos/100/100?random=${DateTime.now().millisecondsSinceEpoch}',
      );
    });
  }

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
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} 23:59:59";
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

  // 오류 메시지 다이얼로그
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '등록 실패',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 폼 데이터 전송 로직 (Dio 활용)
  Future<void> _submitErrand() async {
    if (_titleController.text.length > 40) {
      _showErrorPopup(
        '제목은 40자를 초과할 수 없습니다.\n(현재: ${_titleController.text.length}자)',
      );
      return;
    }
    if (_contentController.text.length > 500) {
      _showErrorPopup(
        '내용은 500자를 초과할 수 없습니다.\n(현재: ${_contentController.text.length}자)',
      );
      return;
    }

    const storage = FlutterSecureStorage();
    String? myAccessToken = await storage.read(key: 'accessToken');
    String? myUserId = await storage.read(key: 'userId');

    // 인증 상태 검증
    if (myAccessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물을 작성하려면 로그인이 필요합니다.')),
        );
      }
      return;
    }

    String rawCost = _costController.text.replaceAll(',', '');

    // FormData 구성
    final Map<String, dynamic> formDataMap = {
      'title': _titleController.text,
      'content': _contentController.text,
      'location': _locationController.text,
      'cost': rawCost.isEmpty ? '0' : rawCost,
      'tags': jsonEncode(_tags),
      'image_url': _selectedImages.isNotEmpty
          ? _selectedImages.first
          : "https://example.com/no-image.png",
    };

    if (_dateController.text.isNotEmpty) {
      formDataMap['deadline'] = _dateController.text;
    }

    FormData formData = FormData.fromMap(formDataMap);

    try {
      // 설정된 전역 DioClient 인스턴스를 통해 API 요청 수행
      var response = await DioClient.instance.post(
        '${Config.baseUrl}/api/createErrand',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("게시물 등록 성공");

        // Dio는 JSON 응답을 자동으로 Map으로 변환합니다.
        var responseData = response.data;
        String newPostId = responseData['errandId'].toString();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('심부름이 성공적으로 등록되었습니다.')),
          );

          // 등록 완료 후 상세 화면으로 라우팅 및 데이터 전달
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: newPostId,
                currentUserId: myUserId ?? '',
                writerId: myUserId ?? '', //다은 수정
                title: _titleController.text,
                content: _contentController.text,
                price: _costController.text.isEmpty
                    ? '0원'
                    : '${_costController.text}원',
                date: _dateController.text.isEmpty
                    ? '마감일 없음'
                    : _dateController.text,
                nickname: '나(작성자)', // 초기 화면용 임시 설정
                tags: _tags,
                imageUrl: _selectedImages.isNotEmpty
                    ? _selectedImages.first
                    : null,
              ),
            ),
          );
        }
      } else {
        print("등록 실패. 상태 코드: ${response.statusCode}");
        print("오류 내용: ${response.data}");
      }
    } on DioException catch (e) {
      print("네트워크 통신 오류 발생: ${e.message}");
      if (e.response != null) {
         print("상세 오류 정보: ${e.response?.data}");
      }
    } catch (e) {
      print("알 수 없는 오류 발생: $e");
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
    // 뒤로가기 동작 제어 컴포넌트
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) async {
        if (didPop) return;

        bool? shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '작성 취소 확인',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            content: const Text(
              '게시물 작성을 취소하시겠습니까?\n작성 중인 내용은 저장되지 않습니다.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  '아니오',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '예(나가기)',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldLeave == true && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
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
          title: const Text(
            '게시물 생성',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
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
                        decoration: BoxDecoration(
                          color: inputGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, color: Colors.black54),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedImages.length}/10',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
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
                              image: DecorationImage(
                                image: NetworkImage(fileUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
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
              _buildCustomTextField(
                '제목을 입력해주세요',
                _titleController,
                maxLength: 40,
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Text(
                    'AI ',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '가격 추천',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      '가격을 입력해주세요',
                      _costController,
                      isNumber: true,
                      formatters: [ThousandsSeparatorInputFormatter()],
                    ),
                  ),
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
                decoration: BoxDecoration(
                  color: inputGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
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
                  Expanded(
                    child: _buildCustomTextField(
                      '장소를 입력 해주세요',
                      _locationController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 40,
                    color: Colors.black,
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '작성 완료',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            Navigator.maybePop(context);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: '심부름',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: '캘린더',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField(
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
    int? maxLength,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputGrey,
        borderRadius: BorderRadius.circular(12),
      ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}