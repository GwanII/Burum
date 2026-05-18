import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
<<<<<<< Updated upstream

class MapScreen extends StatefulWidget {
=======
import 'dart:convert'; // 해시태그 파싱을 위한 마법 주문
import 'postDetailScreen.dart'; // 🌟 마커 클릭 시 상세 페이지로 이동하기 위해 임포트!

class MapScreen extends StatefulWidget {
  // 🌟 [핵심] 홈 화면의 전사들이 들고 온 심부름 리스트 바구니를 받을 칸을 마련하오!
  final List<dynamic> posts;

  const MapScreen({super.key, required this.posts}); // 생성자에서 필수값으로 받도록 개조!

>>>>>>> Stashed changes
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
<<<<<<< Updated upstream
  // 지도의 처음 시작 위치 (위도, 경도)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780), // 서울 시청 좌표
    zoom: 14.0, // 숫자(줌인/아웃)를 조절해 보세요!
  );
=======
  // 📍 초기 지도 중심점 (동료가 점찍어둔 진주시 가좌길 근처!)
  final LatLng _initialCenter = const LatLng(35.154, 128.114);
  
  GoogleMapController? _mapController;
  
  // 🌟 지도 위에 뿌려질 무적의 마커 군단 리스트!
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _spawnErrandMarkers(); // 🌟 화면이 켜지자마자 마커를 소환하는 마법 발동!
  }

  // 🔮 DB에서 올라온 위도/경도를 분석하여 마커를 연성하는 함수
  void _spawnErrandMarkers() {
    final Set<Marker> tempMarkers = {};

    for (var post in widget.posts) {
      // 1. DB의 decimal(10,8) 좌표 데이터를 안전하게 실수(double)로 번역하오!
      double? lat = double.tryParse(post['latitude']?.toString() ?? '');
      double? lng = double.tryParse(post['longitude']?.toString() ?? '');

      // 2. 위도와 경도가 정상적으로 존재하는 심부름만 골라내어 핑을 찍소!
      if (lat != null && lng != null) {
        String postId = post['id']?.toString() ?? post['postId']?.toString() ?? '0';
        String title = post['title'] ?? '심부름 게시글';
        String cost = post['cost']?.toString() ?? '0';
        String locationName = post['location'] ?? '상세 위치';

        // 3. 마커 요정 연성!
        tempMarkers.add(
          Marker(
            markerId: MarkerId('errand_marker_$postId'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // 붉은색 핑!
            
            // 4. 마커를 터치했을 때 머리 위에 뜰 아름다운 말풍선(정보창) 설정!
            infoWindow: InfoWindow(
              title: title,
              snippet: '💰 수당: $cost원 ($locationName)',
              
              // 🔥 [궁극의 연계 마법] 말풍선을 딱! 누르면 해당 심부름 상세 페이지로 순간이동!!!!!
              onTap: () {
                List<String> parsedTags = [];
                try {
                  if (post['tags'] is String) {
                    parsedTags = List<String>.from(jsonDecode(post['tags']));
                  } else if (post['tags'] is List) {
                    parsedTags = List<String>.from(post['tags']);
                  }
                } catch (e) {
                  print("태그 파싱 실패: $e");
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: postId,
                      currentUserId: '', // 인증 토큰 세션이 필요하다면 적절히 연동 가능하오!
                      writerId: post['user_id']?.toString() ?? '',
                      title: title,
                      content: post['content'] ?? '',
                      price: '${cost}원',
                      date: post['deadline'] ?? '마감일 없음',
                      nickname: post['nickname'] ?? '익명 대장',
                      tags: parsedTags,
                      imageUrl: post['image_url'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    // 5. 연성된 마커 군단을 실시간으로 스크린에 반영!
    setState(() {
      _markers = tempMarkers;
    });
    print('🔮 총 ${_markers.length}개의 심부름 핑을 지도 위에 쾅쾅 찍었소!!!!!');
  }
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
      appBar: AppBar(
        title: Text('My First Map!'),
=======
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF59D), // 메인 노란색 테마 일치!
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // 홈 화면으로 복귀!
          },
        ),
        title: const Text(
          '주변 심부름 지도로 보기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialCenter,
          zoom: 15.0, // 진주시 가좌길이 한눈에 보이는 줌 배율!
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        
        // 🌟🌟🌟 요괴 퇴치 핵심: 생성된 마커 목록을 지도에 주입하오!!!!! 🌟🌟🌟
        markers: _markers, 
        
        mapToolbarEnabled: true,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
>>>>>>> Stashed changes
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(35.154, 128.114), // 진주시 가좌길 좌표
          zoom: 16.0, // 숫자(줌 레벨)가 클수록 더 가깝게 확대됩니다
    ),
    onMapCreated: (GoogleMapController controller) {
    // 맵 컨트롤러 설정
  },
)
      
    );
  }
}