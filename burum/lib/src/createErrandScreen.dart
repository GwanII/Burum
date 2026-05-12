// =========================================================
// 🔥 최종 완성본 CreateErrandsPage (돈 제미티에 마법 강화판 ✨)
// =========================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io' if (dart.library.html) 'dart:html';

import 'main_Screen.dart';
import 'postDetailScreen.dart';
import '../config.dart';
import '../dio_client.dart';

// =========================================================
// 천 단위 포맷터
// =========================================================

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();

    for (int i = 0; i < numericString.length; i++) {
      if (i > 0 && (numericString.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(numericString[i]);
    }

    final formattedString = buffer.toString();

    return newValue.copyWith(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}

// =========================================================
// 메인 페이지
// =========================================================

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

  final List<String> _tags = [];

  // =========================================================
  // 이미지
  // =========================================================

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  // =========================================================
  // 중복 submit 방지
  // =========================================================

  bool _isSubmitting = false;

  // =========================================================
  // 지도
  // =========================================================

  LatLng _selectedLatLng = const LatLng(35.154, 128.114);
  GoogleMapController? _mapController;

  // =========================================================
  // 이미지 선택
  // =========================================================

  Future<void> _pickImages() async {
    try {
      int remainingSlots = 10 - _selectedImages.length;

      if (remainingSlots <= 0) {
        _showErrorPopup('사진은 최대 10장까지 첨부 가능합니다.');
        return;
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      setState(() {
        _selectedImages.addAll(
          pickedFiles.take(remainingSlots),
        );
      });
    } catch (e) {
      _showErrorPopup('이미지 선택 중 오류 발생\n$e');
    }
  }

  // =========================================================
  // 이미지 제거
  // =========================================================

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // =========================================================
  // 날짜 선택
  // =========================================================

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

  // =========================================================
  // 태그 추가
  // =========================================================

  void _addTag(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) return;

    setState(() {
      _tags.add(trimmed);
      _tagController.clear();
    });
  }

  // =========================================================
  // 태그 제거
  // =========================================================

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // =========================================================
  // 에러 팝업
  // =========================================================

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '오류 발생',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 등록
  // =========================================================

  Future<void> _submitErrand() async {
    if (_isSubmitting) return;

    if (_titleController.text.trim().isEmpty) {
      _showErrorPopup('제목을 입력해주세요.');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showErrorPopup('내용을 입력해주세요.');
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showErrorPopup('장소를 입력해주세요.');
      return;
    }

    if (_titleController.text.length > 40) {
      _showErrorPopup('제목은 40자를 초과할 수 없습니다.');
      return;
    }

    if (_contentController.text.length > 500) {
      _showErrorPopup('내용은 500자를 초과할 수 없습니다.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      const storage = FlutterSecureStorage();

      String? myAccessToken = await storage.read(key: 'accessToken');
      String? myUserId = await storage.read(key: 'userId');

      if (myAccessToken == null) {
        _showErrorPopup('로그인이 필요합니다.');
        return;
      }

      String rawCost = _costController.text.replaceAll(',', '');
      List<MultipartFile> imageFiles = [];

      for (XFile image in _selectedImages) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          imageFiles.add(
            MultipartFile.fromBytes(bytes, filename: image.name),
          );
        } else {
          imageFiles.add(
            await MultipartFile.fromFile(image.path, filename: image.name),
          );
        }
      }

      final formData = FormData.fromMap({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _selectedLatLng.latitude.toStringAsFixed(8),
        'longitude': _selectedLatLng.longitude.toStringAsFixed(8),
        'cost': rawCost.isEmpty ? '0' : rawCost,
        'tags': jsonEncode(_tags),
        'images': imageFiles,
        if (_dateController.text.isNotEmpty) 'deadline': _dateController.text,
      });

      final response = await DioClient.instance.post(
        '${Config.baseUrl}/api/createErrand',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        String newPostId = responseData['errandId'].toString();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('심부름 등록 완료 🎉'),
            duration: Duration(seconds: 2),
          ),
        );

        // 스낵바를 볼 수 있게 0.5초 대기 ✨
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: newPostId,
              currentUserId: myUserId ?? '',
              writerId: myUserId ?? '',
              title: _titleController.text,
              content: _contentController.text,
              price: _costController.text.isEmpty
                  ? '0원'
                  : '${_costController.text}원',
              date: _dateController.text.isEmpty
                  ? '마감일 없음'
                  : _dateController.text,
              nickname: '나(작성자)',
              tags: _tags,
              imageUrl: null,
            ),
          ),
        );
      } else {
        _showErrorPopup('서버 오류 발생\n상태 코드: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = '네트워크 오류 발생';

      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '서버 연결 시간 초과';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '응답 시간 초과';
      } else if (e.response != null) {
        errorMessage = '서버 오류 (${e.response?.statusCode})';
      }

      _showErrorPopup(errorMessage);
    } catch (e) {
      _showErrorPopup('알 수 없는 오류 발생\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
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
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: mainYellow,
        elevation: 0,
        title: const Text(
          '게시물 생성',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 이미지 업로드 영역
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
                          Text('${_selectedImages.length}/10', 
                            style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  ..._selectedImages.asMap().entries.map((entry) {
                    int index = entry.key;
                    XFile image = entry.value;

                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(image.path),
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
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildCustomTextField('제목 입력', _titleController, maxLength: 40),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildCustomTextField(
                    '가격 입력',
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
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: '내용 입력',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildCustomTextField('장소 입력', _locationController),

            const SizedBox(height: 12),

            // =================================================
            // 🔥 용사님! 여기가 바로 부활한 해시태그 영역이옵니다!
            // =================================================
            Container(
              decoration: BoxDecoration(
                color: inputGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '태그 입력 (스페이스바 또는 엔터로 추가)',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (value) => _addTag(value),
                onChanged: (value) {
                  if (value.endsWith(' ')) {
                    _addTag(value);
                  }
                },
              ),
            ),

            // 태그 칩 목록
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    backgroundColor: mainYellow,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // 구글 지도
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLatLng,
                    zoom: 16,
                  ),
                  onTap: (LatLng latLng) {
                    setState(() {
                      _selectedLatLng = latLng;
                    });
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _selectedLatLng,
                    ),
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitErrand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        '작성 완료',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 공용 텍스트필드 빌더
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
      child: TextField(
        controller: controller,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint,
          counterText: "", // maxLength 표시 숨기기 (깔끔하게!)
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