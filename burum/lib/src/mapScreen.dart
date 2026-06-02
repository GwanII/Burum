import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert'; // 해시태그 파싱을 위한 마법 주문
import 'postDetailScreen.dart'; // 🌟 마커 클릭 시 상세 페이지로 이동하기 위해 임포트!
import '../config.dart'; // 이미지 URL 연성을 위해

class MapScreen extends StatefulWidget {
  // 🌟 [핵심] 홈 화면의 전사들이 들고 온 심부름 리스트 바구니를 받을 칸을 마련하오!
  final List<dynamic> posts;

  const MapScreen({super.key, required this.posts}); // 생성자에서 필수값으로 받도록 개조!

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 📍 초기 지도 중심점 (동료가 점찍어둔 진주시 가좌길 근처!)
  final LatLng _initialCenter = const LatLng(35.154, 128.114);

  GoogleMapController? _mapController;

  // 🌟 지도 위에 뿌려질 무적의 마커 군단 리스트!
  Set<Marker> _markers = {};

  // 🌟 하단에 표시할 유효한(위치 정보가 있는) 심부름 리스트!
  List<dynamic> _validPosts = [];

  @override
  void initState() {
    super.initState();
    _spawnErrandMarkers(); // 🌟 화면이 켜지자마자 마커를 소환하는 마법 발동!
  }

  // 🔮 DB에서 올라온 위도/경도를 분석하여 마커를 연성하는 함수
  void _spawnErrandMarkers() {
    final Set<Marker> tempMarkers = {};
    final List<dynamic> tempValidPosts = [];

    for (var post in widget.posts) {
      // 1. DB의 decimal(10,8) 좌표 데이터를 안전하게 실수(double)로 번역하오!
      double? lat = double.tryParse(post['latitude']?.toString() ?? '');
      double? lng = double.tryParse(post['longitude']?.toString() ?? '');

      // 2. 위도와 경도가 정상적으로 존재하는 심부름만 골라내어 핑을 찍소!
      if (lat != null && lng != null) {
        tempValidPosts.add(post); // 🌟 하단 리스트에도 추가!
        String postId =
            post['id']?.toString() ?? post['postId']?.toString() ?? '0';
        String title = post['title'] ?? '심부름 게시글';
        String cost = post['cost']?.toString() ?? '0';
        String locationName = post['location'] ?? '상세 위치';

        // 3. 마커 요정 연성!
        tempMarkers.add(
          Marker(
            markerId: MarkerId('errand_marker_$postId'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ), // 붉은색 핑!
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
      _validPosts = tempValidPosts;
    });
    print('🔮 총 ${_markers.length}개의 심부름 핑을 지도 위에 쾅쾅 찍었소!!!!!');
  }

  // 🌟 이미지 URL 변환 마법
  String getRealImageUrl(String? rawImageUrl) {
    if (rawImageUrl == null || rawImageUrl.isEmpty) return '';
    try {
      List<dynamic> parsedList = jsonDecode(rawImageUrl);
      if (parsedList.isNotEmpty) {
        return '${Config.baseUrl}${parsedList[0]}';
      }
    } catch (e) {
      if (rawImageUrl.startsWith('/uploads')) {
        return '${Config.baseUrl}$rawImageUrl';
      }
      return rawImageUrl;
    }
    return '';
  }

  // 🌟 날짜 포맷팅 함수
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')} 마감';
    } catch (e) {
      return '';
    }
  }

  // 🌟 태그 파싱 함수
  List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    try {
      if (tags is List) return List<String>.from(tags);
      if (tags is String) return List<String>.from(jsonDecode(tags));
      return [];
    } catch (e) {
      return [];
    }
  }

  // 🌟 하단에 표시할 심부름 아이템 위젯
  Widget _buildErrandItem({
    required String postId,
    required String writerId,
    required String title,
    required String desc,
    required String price,
    required String deadlineInfo,
    required String nickname,
    required List<String> tags,
    String? imageUrl,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: postId,
              title: title,
              content: desc,
              currentUserId: '', // 인증 토큰 세션이 필요하다면 적절히 연동
              writerId: writerId,
              price: price,
              date: deadlineInfo,
              nickname: nickname,
              tags: tags,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 박스
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.hardEdge,
              child: Hero(
                tag: 'post_image_map_$postId',
                child: getRealImageUrl(imageUrl).isEmpty
                    ? Container(color: const Color(0xFFFFF176))
                    : Image.network(
                        getRealImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://via.placeholder.com/300/FFF176/000000?text=No+Image',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 15),
            // 텍스트 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...tags.map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // 🌟 Spacer()로 인한 무한 높이 에러 해결!
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$deadlineInfo | $nickname',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 15.0, // 진주시 가좌길이 한눈에 보이는 줌 배율!
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },

            // 🌟 바텀 시트에 가려지지 않도록 지도 기본 UI(확대/축소 버튼, 구글 로고 등)를 위로 밀어올립니다!
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.35,
            ),

            // 🌟🌟🌟 요괴 퇴치 핵심: 생성된 마커 목록을 지도에 주입하오!!!!! 🌟🌟🌟
            markers: _markers,

            mapToolbarEnabled: true,
            zoomControlsEnabled: false, // 🌟 기본 확대/축소 버튼은 숨깁니다!
            myLocationButtonEnabled: false,
          ),

          // 🌟 우측 상단 커스텀 확대/축소 버튼!
          Positioned(
            top: 20, // 상단바 바로 밑 여백
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(Icons.add, color: Colors.black87),
                    ),
                  ),
                  Container(width: 30, height: 1, color: Colors.grey.shade200),
                  InkWell(
                    onTap: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(Icons.remove, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🌟 지도 하단에 심부름 리스트 띄우기!
          DraggableScrollableSheet(
            initialChildSize: 0.35, // 처음 띄웠을 때 화면의 35% 차지
            minChildSize: 0.1, // 최소 10% (손잡이만 살짝 보이게)
            maxChildSize: 0.9, // 최대 90% (거의 전체 화면)
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white, // 바텀 시트 배경색
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 🌟 드래그 손잡이 (Handle)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // 🌟 리스트 영역
                    Expanded(
                      child: _validPosts.isEmpty
                          ? const Center(
                              child: Text(
                                '지도 주변에 등록된 심부름이 없어요 🥲',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller:
                                  scrollController, // 🌟 필수! 드래그와 스크롤 연동
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _validPosts.length,
                              itemBuilder: (context, index) {
                                var post = _validPosts[index];
                                return Column(
                                  children: [
                                    _buildErrandItem(
                                      postId:
                                          post['id']?.toString() ??
                                          post['post_id']?.toString() ??
                                          post['_id']?.toString() ??
                                          '',
                                      writerId:
                                          post['writer_id']?.toString() ??
                                          post['user_id']?.toString() ??
                                          post['writerId']?.toString() ??
                                          '',
                                      title: post['title'] ?? '',
                                      desc: post['content'] ?? '',
                                      price: '${post['cost']}원',
                                      deadlineInfo: _formatDate(
                                        post['deadline'],
                                      ),
                                      nickname: post['nickname'] ?? '익명',
                                      tags: _parseTags(post['tags']),
                                      imageUrl: post['image_url'],
                                    ),
                                    const Divider(
                                      color: Colors.grey,
                                      thickness: 0.5,
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
