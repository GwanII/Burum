import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert'; // 해시태그 파싱을 위한 마법 주문
import 'dart:ui' as ui; // --성빈 숫자가 적힌 클러스터 핑을 실시간으로 그리기 위한 캔버스 마법 도구! -성빈-
import 'dart:typed_data'; // --성빈 그림을 바이트 데이터로 변환하기 위한 마법 주문! -성빈-
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

  // --성빈 카메라 줌 레벨과 현재 화면 영역, 새로고침 버튼 상태를 기억하는 마법의 구슬들! -성빈-
  double _currentZoom = 15.0; // 기본 줌 배율
  LatLngBounds? _currentBounds; // 현재 화면에 보이는 지도 영역
  bool _showRefreshButton = false; // '이 지역 재검색' 버튼 표시 여부

  // --성빈 🌟 [구조 개조] 단일 데이터 보관함에서 여러 개를 품을 수 있는 리스트 상자로 진화! -성빈-
  bool _isSheetVisible = false; // 바텀 시트가 보일지 말지 결정하는 스위치!
  List<dynamic> _selectedPosts = []; // --성빈 콕! 찍은 핑(들)의 데이터를 담아둘 보물 바구니! -성빈-

  @override
  void initState() {
    super.initState();
    // --성빈 화면이 켜지자마자 실행되는 마커 소환 주문을 비동기 마법으로 업그레이드! -성빈-
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _spawnErrandMarkersAsync();
    });
  }

  // 🔮 DB에서 올라온 위도/경도를 분석하여 마커를 연성하는 함수
  // --성빈 기존 동기식 함수는 하위 호환성을 위해 남겨두고 내부에서 비동기 함수를 호출하도록 변경했소! -성빈-
  void _spawnErrandMarkers() {
    _spawnErrandMarkersAsync();
  }

  // --성빈 숫자가 적힌 그룹 마커 이미지를 실시간으로 그려내는 궁극의 연금술! -성빈-
  Future<BitmapDescriptor> _createCustomClusterMarker(int count) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = const Color(0xFFF44336); // 강렬한 붉은색!
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    final double size = 120.0;

    // 동그란 마커 배경 그리기
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, borderPaint);

    // 마커 안에 심부름 개수 숫자 텍스트 새기기
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: count.toString(),
      style: TextStyle(
        fontSize: size / 2.5,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );

    // 그림을 마커 이미지로 변환!
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // --성빈 렉을 줄이고 클러스터링을 적용한 진정한 마커 소환 비동기 마법! -성빈-
  Future<void> _spawnErrandMarkersAsync() async {
    final Set<Marker> tempMarkers = {};
    final List<dynamic> tempValidPosts = [];
    final Map<String, List<dynamic>> clusterMap = {};

    for (var post in widget.posts) {
      // 1. DB의 decimal(10,8) 좌표 데이터를 안전하게 실수(double)로 번역하오!
      double? lat = double.tryParse(post['latitude']?.toString() ?? '');
      double? lng = double.tryParse(post['longitude']?.toString() ?? '');

      // 2. 위도와 경도가 정상적으로 존재하는 심부름만 골라내어 핑을 찍소!
      if (lat != null && lng != null) {
        
        // --성빈 🌟 화면 범위 필터링! 현재 보이는 지도 영역 밖의 심부름은 렌더링하지 않아 렉을 폭파시킵니다! -성빈-
        if (_currentBounds != null) {
          if (lat < _currentBounds!.southwest.latitude ||
              lat > _currentBounds!.northeast.latitude ||
              lng < _currentBounds!.southwest.longitude ||
              lng > _currentBounds!.northeast.longitude) {
            continue; // 화면 밖이면 과감하게 스킵!
          }
        }

        tempValidPosts.add(post); // 🌟 하단 리스트에도 추가! (현재 화면에 있는 것만!)

        // --성빈 🌟 줌 레벨이 13.5 미만(축소 상태)이면 근처 지역을 숫자로 묶어버립니다! -성빈-
        if (_currentZoom < 13.5) {
          // 좌표에 50을 곱해 반올림하여 대략 2km 반경을 하나의 그리드로 묶는 마법!
          String gridKey = '${(lat * 50).round()}_${(lng * 50).round()}';
          if (!clusterMap.containsKey(gridKey)) {
            clusterMap[gridKey] = [];
          }
          clusterMap[gridKey]!.add(post);
        } else {
          // --성빈 🌟 지도를 충분히 확대했다면 개별 심부름 위치에 핑이 보이게! (기존 로직 유지) -성빈-
          String postId = post['id']?.toString() ?? post['postId']?.toString() ?? '0';

          // 3. 마커 요정 연성!
          tempMarkers.add(
            Marker(
              markerId: MarkerId('errand_marker_$postId'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ), // 붉은색 핑!
              
              // --성빈 🌟 개별 핑을 터치하면 단 하나의 심부름 리스트만 바구니에 쏙 담아 띄웁니다! -성빈-
              onTap: () {
                setState(() {
                  _selectedPosts = [post];
                  _isSheetVisible = true;
                });
                // 선택한 핑이 화면 중앙으로 예쁘게 오도록 카메라 이동!
                _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
              },
            ),
          );
        }
      }
    }

    // --성빈 축소 상태일 때 묶여진 그룹(클러스터) 마커들을 지도에 소환합니다! -성빈-
    if (_currentZoom < 13.5) {
      for (var entry in clusterMap.entries) {
        List<dynamic> group = entry.value;
        if (group.length == 1) {
          // 그룹에 하나뿐이라면 굳이 숫자를 안 달고 일반 마커로 출력!
          var post = group[0];
          double lat = double.parse(post['latitude'].toString());
          double lng = double.parse(post['longitude'].toString());
          String postId = post['id']?.toString() ?? post['postId']?.toString() ?? '0';
          tempMarkers.add(
            Marker(
              markerId: MarkerId('errand_marker_$postId'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              // --성빈 외톨이 마커도 누르면 시트가 올라오게 연결! -성빈-
              onTap: () {
                setState(() {
                  _selectedPosts = [post];
                  _isSheetVisible = true;
                });
                _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
              },
            )
          );
        } else {
          // 여러 개가 묶였다면 평균 좌표를 구해 숫자가 적힌 거대한 핑 소환!
          double latSum = 0;
          double lngSum = 0;
          for(var p in group) {
            latSum += double.parse(p['latitude'].toString());
            lngSum += double.parse(p['longitude'].toString());
          }
          double avgLat = latSum / group.length;
          double avgLng = lngSum / group.length;

          BitmapDescriptor clusterIcon = await _createCustomClusterMarker(group.length);

          tempMarkers.add(
            Marker(
              markerId: MarkerId('cluster_${entry.key}'),
              position: LatLng(avgLat, avgLng),
              icon: clusterIcon,
              // --성빈 🌟 [특급 개조] 숫자 핑을 누르면 포함된 심부름들을 다 하단 바에 바인딩하고 확대도 해줍니다! -성빈-
              onTap: () {
                setState(() {
                  _selectedPosts = group; // 포함된 테스트(게시글)들 전부 장착!
                  _isSheetVisible = true;
                });
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(avgLat, avgLng), 14.5));
              }
            )
          );
        }
      }
    }

    // 5. 연성된 마커 군단을 실시간으로 스크린에 반영!
    setState(() {
      _markers = tempMarkers;
      _validPosts = tempValidPosts;
    });
    print('🔮 총 ${_markers.length}개의 심부름 핑(클러스터 포함)을 지도 위에 쾅쾅 찍었소!!!!!');
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
              heroTag: 'map_image_$postId',
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
            // --성빈 지도의 빈 공간을 터치하면 열려있던 시트가 쏙! 들어가게 마법 추가! -성빈-
            onTap: (_) {
              if (_isSheetVisible) {
                setState(() {
                  _isSheetVisible = false;
                });
              }
            },
            // --성빈 지도가 움직일 때마다 줌 레벨을 기록하고 새로고침 버튼을 깨워줍니다! -성빈-
            onCameraMove: (CameraPosition position) {
              _currentZoom = position.zoom;
              if (!_showRefreshButton) {
                setState(() {
                  _showRefreshButton = true;
                });
              }
            },
            // --성빈 🌟 [자동화 핵심 마법] 이지역 재검색을 누르지 않아도 화면 줌이나 이동이 끝나면 자동으로 핑 상태를 변환하오! -성빈-
            onCameraIdle: () async {
              if (_mapController != null) {
                _currentBounds = await _mapController!.getVisibleRegion();
                setState(() {
                  _showRefreshButton = false; // 자동으로 변환 완료했으니 수동 버튼은 숨겨주는 센스!
                });
                await _spawnErrandMarkersAsync();
              }
            },
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              // --성빈 지도가 만들어지면 최초의 화면 경계를 파악하여 렉을 방지합니다! -성빈-
              _currentBounds = await controller.getVisibleRegion();
            },

            // 🌟🌟🌟 요괴 퇴치 핵심: 생성된 마커 목록을 지도에 주입하오!!!!! 🌟🌟🌟
            markers: _markers,

            mapToolbarEnabled: true,
            zoomControlsEnabled: false, // 🌟 기본 확대/축소 버튼은 숨깁니다!
            myLocationButtonEnabled: false,
          ),

          // --성빈 화면 이동 시 상단에 등장하는 '현 지도에서 검색' 버튼 요정! (자동화로 인해 평소엔 안 뜹니다!) -성빈-
          if (_showRefreshButton)
            Positioned(
              top: 20, // 지도 최상단 여백
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_mapController != null) {
                        _currentBounds = await _mapController!.getVisibleRegion();
                        setState(() {
                          _showRefreshButton = false;
                          _isSheetVisible = false; // --성빈 재검색 시 깔끔하게 시트 닫기! -성빈-
                        });
                        // 옮긴 화면을 기준으로 옛날 핑은 날리고 새로운 핑들을 소환!
                        await _spawnErrandMarkersAsync();
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Colors.black87),
                    label: const Text(
                      '이 지역 재검색',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 5, // 그림자로 입체감 빵빵하게!
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
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

          // --성빈 🌟 [대망의 개조 완료] 여러 개의 리스트를 품을 수 있게 고도화된 하단 슬라이드 시트! -성빈-
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // 0.3초 만에 슈루룩!
            curve: Curves.easeInOut,
            bottom: _isSheetVisible ? 0 : -380, // 안 보일 땐 화면 아래로 전사들을 격리!
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 유연하게 높이 차지!
                children: [
                  // 🌟 X 버튼 (닫기) 와 손잡이 장식
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // 좌우 대칭을 위한 투명 망토!
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () {
                            // X 버튼 누르면 시트 즉시 닫기!
                            setState(() {
                              _isSheetVisible = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // --성빈 🌟 [멀티 렌더링] 선택된 리스트의 개수만큼 아래로 쫙 나열해 줍니다! 오버플로우 절대 방어막 장착! -성빈-
                  if (_selectedPosts.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4, // 최대 높이를 40%로 제한해 렉과 화면 뚫림 방지!
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(), // 스크롤을 아주 찰지게!
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _selectedPosts.length,
                        itemBuilder: (context, index) {
                          var post = _selectedPosts[index];
                          return Column(
                            children: [
                              _buildErrandItem(
                                postId: post['id']?.toString() ??
                                        post['postId']?.toString() ??
                                        post['_id']?.toString() ??
                                        '',
                                writerId: post['writer_id']?.toString() ??
                                          post['user_id']?.toString() ??
                                          post['writerId']?.toString() ??
                                          '',
                                title: post['title'] ?? '제목 없음',
                                desc: post['content'] ?? '내용 없음',
                                price: '${post['cost']}원',
                                deadlineInfo: _formatDate(post['deadline']),
                                nickname: post['nickname'] ?? '익명',
                                tags: _parseTags(post['tags']),
                                imageUrl: post['image_url'],
                              ),
                              if (index < _selectedPosts.length - 1)
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
            ),
          ),
        ],
      ),
    );
  }
}