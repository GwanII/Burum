import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart'; // 💡 삭제 예외 처리를 위해 추가!
import 'createErrandScreen.dart';
import 'applicantListPage.dart';
import '../dio_client.dart'; // 🌟 우리의 전담 우체부(행동대장) 모셔오기!

class writerDetailPage extends StatelessWidget {
  // 1. 홈 화면에서 넘겨받을 데이터들
  final String postId;
  final String title;
  final String content;
  final String price;
  final String date;
  final String nickname;
  final List<String> tags;
  final String? imageUrl;

  // 2. 생성자
  const writerDetailPage({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.price,
    required this.date,
    required this.nickname,
    required this.tags,
    this.imageUrl,
  });

  // 🌟 심폐소생술 1: 작성자 화면이라면 당연히 있어야 할 '삭제' 기능 추가!
  Future<void> _deletePost(BuildContext context) async {
    // 삭제 전 진짜 지울 건지 한 번 물어보기 (안전장치)
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 심부름을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return; // 취소 눌렀으면 여기서 스톱!

    try {
      // 💡 DioClient 출동! 토큰도 알아서 챙겨갑니다. (백엔드 API 주소에 맞게 수정하세요!)
      await DioClient.instance.delete('/api/posts/$postId');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('🗑️ 게시글이 삭제되었습니다.')));
        Navigator.pop(context); // 홈 화면으로 돌아가기!
      }
    } on DioException catch (e) {
      print("삭제 실패: ${e.response?.statusCode} - ${e.message}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('앗! 삭제에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print("알 수 없는 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 앱바와 버튼에 쓰일 메인 노란색
    const Color mainYellow = Color(0xFFFFF176);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // 🌟 심폐소생술 2: 우측 상단에 쓰레기통 아이콘 배치
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deletePost(context),
            tooltip: '게시글 삭제',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 이미지
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

      // 🌟 하단 고정 버튼 (작성자용)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              // 지원자 목록 보기 버튼
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplicantListPage(
                          postId: postId,
                          postTitle: title, // 성빈이가 추가
                          postDeadline: date, // 성빈이가 추가
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainYellow,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '지원자 목록 보기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // 게시물 수정하기 버튼
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // 💡 주의: 백지 상태의 CreateErrandsPage()를 열면 수정이 아니라 '새 글 작성'이 됩니다.
                        // 나중에 CreateErrandsPage 생성자에 기존 데이터(title, content 등)를
                        // 넘겨줄 수 있게 만들면 여기서 인자로 쏴주시면 됩니다!
                        builder: (context) => const CreateErrandsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainYellow,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '게시물 수정하기',
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
