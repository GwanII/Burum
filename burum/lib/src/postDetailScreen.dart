import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http; // 💡 서버 통신을 위한 마법책 추가!
import 'dart:convert'; // 💡 JSON 변환용 마법책 추가!
import '../config.dart';

class PostDetailScreen extends StatelessWidget {
  // 1. 홈 화면에서 넘겨받을 데이터들
  final String postId; // 🌟 추가됨: 어떤 게시물에 지원하는지 백엔드에 알려주기 위한 고유 ID!
  final String title;
  final String content;
  final String currentUserId;
  final String price;
  final String date;
  final String nickname;
  final List<String> tags;
  final String? imageUrl;

  // 2. 생성자
  const PostDetailScreen({
    super.key,
    required this.postId, // 🌟 필수값으로 추가! (이전 화면에서 넘겨줘야 합니다)
    required this.title,
    required this.content,
    required this.currentUserId,
    required this.price,
    required this.date,
    required this.nickname,
    required this.tags,
    this.imageUrl,
  });

  // 🌟 지원하기 버튼을 눌렀을 때 실행될 통신 함수!
  Future<void> _submitApplication(BuildContext context, String message) async {
    // 백엔드 API 주소 (상황에 맞게 수정하세요!)
    final url = Uri.parse('${Config.baseUrl}/api/posts/applyErrand'); 
    

    // 임시 유저 ID (실제로는 로그인한 유저의 ID를 가져와야 합니다)
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postId': postId,        // 어떤 게시물인지
          'userId': currentUserId, // 누가 지원하는지
          'message': message,      // 지원 멘트
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ 1. 통신 성공 (처음 지원함)
        if (context.mounted) {
          Navigator.pop(context); // 지원 팝업(다이얼로그) 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 지원이 성공적으로 완료되었습니다!')),
          );
        }
      } else if (response.statusCode == 409) {
        // 🛡️ 2. 중복 지원 방어 (이미 지원한 유저)
        print("적의 방어! 상태 코드: 409 (중복 지원 시도)");
        if (context.mounted) {
          Navigator.pop(context); // 열려있는 창이 있다면 닫아주기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 지원한 심부름입니다! 🙅‍♂️'),
              backgroundColor: Colors.orange, // 경고 느낌을 주려면 색상을 바꿔도 좋아요
            ),
          );
        }
      } else {
        // ❌ 3. 통신 실패 (기타 400, 500 등 서버 에러)
        print("적의 방어! 상태 코드: ${response.statusCode}");
        print("서버의 답변: ${response.body}"); // 디버깅을 위해 서버 메시지도 출력!
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('앗! 지원에 실패했어요. 다시 시도해주세요.')),
          );
        }
      }
    } catch (e) {
      // 🔌 4. 아예 인터넷이 끊겼거나 서버가 꺼진 경우
      print("통신망 단절 에러: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네트워크 오류가 발생했습니다. 서버 상태를 확인해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 이미지 (받아온 이미지가 있으면 띄우고, 없으면 회색 박스)
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),

            const SizedBox(height: 15),

            // 프로필 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage('https://picsum.photos/200'),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '심부름 마스터',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'B급',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(thickness: 1, color: Colors.black12),
            ),

            // 본문 내용 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    tags.map((tag) => '#$tag').join(' '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Text('마감일: $date', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    '의뢰비: $price',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    content,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(thickness: 1, color: Colors.black12),
            ),

            // 지도 및 주소 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '주소 : 경상남도 진주시 가좌길36번길 17',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    height: 180,
                    width: double.infinity,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(35.154, 128.114),
                        zoom: 16.0,
                      ),
                      markers: {
                        const Marker(
                          markerId: MarkerId('target_location'),
                          position: LatLng(35.154, 128.114),
                        ),
                      },
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // 하단 고정 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              // 채팅하기 버튼
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 채팅 화면으로 넘어가는 기능 추가
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90B2AB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '채팅하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // 지원하기 버튼
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // 🌟 팝업창 띄우기 전, 입력창의 텍스트를 감시할 컨트롤러 생성!
                    TextEditingController applyMessageController =
                        TextEditingController();

                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 25,
                            left: 20,
                            right: 20,
                            bottom: 5,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '심부름 지원',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),

                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: TextField(
                                  controller:
                                      applyMessageController, // 🌟 컨트롤러 연결!
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    hintText: '자기 소개, 각오 등 하고싶은 말을 적어주세요!',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                '취소',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // 🌟 지원 버튼을 누르면 컨트롤러에서 텍스트를 뽑아 서버로 보냅니다!
                                String message = applyMessageController.text
                                    .trim();
                                if (message.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('지원 멘트를 작성해주세요!'),
                                    ),
                                  );
                                  return;
                                }

                                // 통신 함수 실행!
                                _submitApplication(context, message);
                              },
                              child: const Text(
                                '지원',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90B2AB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '지원하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
