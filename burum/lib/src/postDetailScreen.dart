import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PostDetailScreen extends StatelessWidget {
  // 1. 홈 화면에서 넘겨받을 데이터(택배 내용물)들을 선언해줍니다.
  final String title;
  final String content;
  final String price;
  final String date;
  final String nickname;
  final List<String> tags;
  final String? imageUrl;

  // 2. 생성자(Constructor): "이 화면을 열려면 이 데이터들을 필수로 넣어줘!" 라는 뜻입니다.
  const PostDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.price,
    required this.date,
    required this.nickname,
    required this.tags,
    this.imageUrl,
  });

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
                  : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
            
            const SizedBox(height: 15),

            // 프로필 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://picsum.photos/200')),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('심부름 마스터', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  const Text('B급', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0))),
                ],
              ),
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(thickness: 1, color: Colors.black12)),

            // 본문 내용 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  Text(
                    tags.map((tag) => '#$tag').join(' '),
                    style: TextStyle(fontSize: 14, color: Colors.blueAccent.shade700, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  
                  Text('마감일: $date', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('의뢰비: $price', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 20),
                  
                  Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
                ],
              ),
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(thickness: 1, color: Colors.black12)),

            // 지도 및 주소 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('주소 : 경상남도 진주시 가좌길36번길 17', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                      // 지도에 빨간색 마커 띄우기
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
                    backgroundColor: const Color(0xFF90B2AB), // 보내주신 사진과 비슷한 민트그레이 색상
                    elevation: 0, 
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('채팅하기', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              
              // 지원하기 버튼
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // 지원하기 팝업창 띄우기
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), 
                          ),
                          contentPadding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 5),
                          content: Column(
                            mainAxisSize: MainAxisSize.min, 
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '심부름 지원',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 15),
                              
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const TextField(
                                  maxLines: 5, 
                                  decoration: InputDecoration(
                                    hintText: '자기 소개, 각오 등 하고싶은 말을 적어주세요!',
                                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                    border: InputBorder.none, 
                                    contentPadding: EdgeInsets.all(15), 
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소', style: TextStyle(color: Colors.black)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // 팝업 닫기
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('지원이 완료되었습니다!')),
                                );
                              },
                              child: const Text('지원', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90B2AB), // 보내주신 사진과 비슷한 민트그레이 색상
                    elevation: 0, 
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('지원하기', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}