import 'dart:io'; // 모바일용 진짜 파일 마법
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 웹/모바일 차원 스캐너
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // 주소 통역 마법서
import 'package:image_picker/image_picker.dart'; // 갤러리 소환술사
import 'main_Screen.dart';
import 'postDetailScreen.dart';
import '../config.dart';
import '../dio_client.dart';

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
  // 🌟 [수정 모드 대비용 거대한 주머니들 장착!]
  final String? postId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCost;
  final String? initialDate;
  final List<String>? initialTags;
  final String? initialImageUrl;

  const CreateErrandsPage({
    super.key,
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialCost,
    this.initialDate,
    this.initialTags,
    this.initialImageUrl,
  });

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

  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  LatLng _selectedLatLng = const LatLng(35.154, 128.114);
  GoogleMapController? _mapController;

  // 🌟 [방에 들어올 때 기존 짐이 있으면 풀어서 세팅하는 마법!]
  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _titleController.text = widget.initialTitle ?? '';
      _contentController.text = widget.initialContent ?? '';
      // 가격에서 '원'과 콤마를 떼고 숫자만 세팅
      _costController.text = widget.initialCost?.replaceAll('원', '').replaceAll(',', '') ?? '';
      
      if (widget.initialTags != null) {
        _tags = List.from(widget.initialTags!);
      }
      if (widget.initialDate != null && widget.initialDate != '마감일 없음') {
        _dateController.text = widget.initialDate!;
      }
      // 위치나 이미지는 복잡해질 수 있으니 일단 기본값 세팅 (필요시 백엔드에서 위도/경도도 받아와야 완벽해짐!)
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_selectedImages.length < 10) {
              _selectedImages.add(file);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사진은 최대 10장까지만 첨부할 수 있습니다.')),
              );
              break;
            }
          }
        });
      }
    } catch (e) {
      print("🚨 갤러리 소환 실패: $e");
    }
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

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('실패', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
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

  // 🌟 [대망의 전송 마법! 생성(POST)과 수정(PUT)을 지능적으로 구별하오!]
  Future<void> _submitErrand() async {
    if (_titleController.text.length > 40) {
      _showErrorPopup('제목은 40자를 초과할 수 없습니다.\n(현재: ${_titleController.text.length}자)');
      return;
    }
    if (_contentController.text.length > 500) {
      _showErrorPopup('내용은 500자를 초과할 수 없습니다.\n(현재: ${_contentController.text.length}자)');
      return;
    }

    const storage = FlutterSecureStorage();
    String? myAccessToken = await storage.read(key: 'accessToken');
    String? myUserId = await storage.read(key: 'userId');

    if (myAccessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물을 작성/수정하려면 로그인이 필요합니다.')),
        );
      }
      return;
    }

    String rawCost = _costController.text.replaceAll(',', '');

    final Map<String, dynamic> formDataMap = {
      'title': _titleController.text,
      'content': _contentController.text,
      'location': _locationController.text,
      'latitude': _selectedLatLng.latitude.toStringAsFixed(8),
      'longitude': _selectedLatLng.longitude.toStringAsFixed(8),
      'cost': rawCost.isEmpty ? '0' : rawCost,
      'tags': jsonEncode(_tags),
    };

    if (_dateController.text.isNotEmpty) {
      formDataMap['deadline'] = _dateController.text;
    }

    if (_selectedImages.isNotEmpty) {
      List<MultipartFile> multipartImages = [];
      for (var file in _selectedImages) {
        multipartImages.add(
          await MultipartFile.fromFile(file.path, filename: file.name)
        );
      }
      // 백엔드 라우터(upload.array('images'))가 기다리는 정확한 이름표 'images'를 붙여주오!
      formDataMap['images'] = multipartImages;
    }

    FormData formData = FormData.fromMap(formDataMap);

    try {
      Response response;
      bool isEditMode = widget.postId != null; // 수정 모드인지 판별!

      if (isEditMode) {
        // 🛠️ 수정 모드일 때: PUT /api/posts/:id 로 쏜다!
        response = await DioClient.instance.put(
          '${Config.baseUrl}/api/posts/${widget.postId}',
          data: formData,
        );
      } else {
        // ✨ 생성 모드일 때: POST /api/createErrand 로 쏜다!
        response = await DioClient.instance.post(
          '${Config.baseUrl}/api/createErrand',
          data: formData,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditMode ? '심부름이 성공적으로 수정되었습니다.' : '심부름이 성공적으로 등록되었습니다.')),
          );

          // 홈 화면으로 완전히 돌아가서 새로고침 되도록 유도!
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        print("요청 실패: ${response.statusCode}");
      }
    } on DioException catch (e) {
      print("네트워크 오류: ${e.message}");
    } catch (e) {
      print("알 수 없는 오류: $e");
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
    bool isEditMode = widget.postId != null; // 🌟 현재 모드가 무엇인지 파악!

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) async {
        if (didPop) return;

        bool? shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('취소 확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            content: Text(isEditMode ? '수정을 취소하시겠습니까?\n변경 사항은 저장되지 않습니다.' : '게시물 작성을 취소하시겠습니까?\n작성 중인 내용은 저장되지 않습니다.', style: const TextStyle(fontSize: 16)),
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
          Navigator.pop(context); // 이전 화면으로 살포시 돌아가기!
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: mainYellow,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.maybePop(context),
          ),
          // 🌟 타이틀도 똑똑하게 바뀜!
          title: Text(isEditMode ? '게시물 수정' : '게시물 생성', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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
                        width: 100, height: 100,
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
                      XFile file = entry.value;

                      return Stack(
                        children: [
                          Container(
                            width: 100, height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: inputGrey),
                            child: kIsWeb
                                ? Image.network(file.path, fit: BoxFit.cover) 
                                : Image.file(File(file.path), fit: BoxFit.cover), 
                          ),
                          Positioned(
                            right: 12, top: 0,
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
                  Expanded(
                    child: _buildCustomTextField(
                      '가격을 입력해주세요', _costController, isNumber: true, formatters: [ThousandsSeparatorInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(child: _buildCustomTextField('날짜 선택', _dateController)),
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
                  maxLines: 5, maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: '내용을 입력해주세요', hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none, contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '해시태그 입력 후 엔터', filled: true, fillColor: inputGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: _addTag,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: _tags.map((tag) => InputChip(label: Text(tag), backgroundColor: mainYellow, onDeleted: () => _removeTag(tag))).toList(),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildCustomTextField('장소를 입력 해주세요', _locationController)),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined, size: 40, color: Colors.black),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                '📍 상세 위치 픽 (지도를 터치하여 정확한 마커를 꽂으시오!)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                height: 220, width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black26, width: 1)),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _selectedLatLng, zoom: 16.0),
                  onTap: (LatLng newLatLng) async {
                    setState(() { _selectedLatLng = newLatLng; });
                    print('🎯 픽한 위치 좌표: ${newLatLng.latitude}, ${newLatLng.longitude}');

                    if (kIsWeb) {
                      setState(() { _locationController.text = "웹 테스트 중 (실제 주소를 직접 입력하시오!)"; });
                    } else {
                      try {
                        List<Placemark> placemarks = await placemarkFromCoordinates(newLatLng.latitude, newLatLng.longitude);
                        if (placemarks.isNotEmpty) {
                          Placemark place = placemarks[0]; 
                          String fullAddress = '${place.administrativeArea} ${place.locality} ${place.subLocality} ${place.thoroughfare} ${place.subThoroughfare}';
                          fullAddress = fullAddress.replaceAll('null', '').replaceAll(RegExp(r'\s+'), ' ').trim();
                          setState(() { _locationController.text = fullAddress; });
                        }
                      } catch (e) {
                        print("🚨 주소 번역 마법 실패: $e");
                        setState(() { _locationController.text = "주소를 불러오지 못했소!"; });
                      }
                    }
                  },
                  onMapCreated: (GoogleMapController controller) { _mapController = controller; },
                  markers: {
                    Marker(
                      markerId: const MarkerId('picked_errand_location'),
                      position: _selectedLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  mapToolbarEnabled: false, zoomControlsEnabled: true, myLocationButtonEnabled: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '현재 픽한 위도: ${_selectedLatLng.latitude.toStringAsFixed(8)} / 경도: ${_selectedLatLng.longitude.toStringAsFixed(8)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _submitErrand,
                  style: ElevatedButton.styleFrom(backgroundColor: mainYellow, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  // 🌟 버튼 텍스트도 똑똑하게 바뀜!
                  child: Text(isEditMode ? '수정 완료' : '작성 완료', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
        maxLength: maxLength, inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}