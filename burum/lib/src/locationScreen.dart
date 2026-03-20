import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main_Screen.dart';
import '../config.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;

  // 기본 위치 (초기 로딩 시 띄워줄 임시 위치 - 서울 시청)
  LatLng _mapCenterPosition = const LatLng(37.5665, 126.9780);

  String _currentDong = '위치 찾는 중...';
  bool _isLoading = true;
  bool _isMapMoving = false; // 지도를 움직이는 중인지 체크

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  // 1. 내 현재 GPS 위치 가져오기
  Future<void> _initCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 켜져 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('스마트폰의 위치(GPS) 서비스를 켜주세요.');
      return;
    }

    // 권한 확인 및 요청
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('위치 권한을 허용해야 동네 설정이 가능합니다.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('앱 설정에서 위치 권한을 직접 허용해주세요.');
      return;
    }

    // 현재 위치 좌표 가져오기
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 지도를 내 위치로 이동시키기
    LatLng myLatLng = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(myLatLng, 16.0));

    // 가져온 좌표를 주소(동네 이름)로 변환
    await _updateAddressFromLatLng(myLatLng);
  }

  // 2. 좌표를 글자(주소)로 변환하는 함수 (Reverse Geocoding)
  Future<void> _updateAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      print('구글 주소 데이터: ${place.toString()}');

      setState(() {
        String city = place.locality ?? '';

        String dong = place.thoroughfare ?? place.subLocality ?? '';

        String combinedAddress = '$city $dong'.trim();

        if (combinedAddress.isEmpty) {
          _currentDong = '동네 이름 없음';
        } else {
          _currentDong = combinedAddress;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('주소 변환 에러 발생!: $e');
      setState(() {
        _currentDong = '위치 변환 실패';
        _isLoading = false;
      });
    }
  }

  // 백엔드에 내 동네 저장하기 (PATCH 요청)
  Future<void> _verifyLocation() async {
    if (_currentDong == '위치 찾는 중...' ||
        _currentDong == '위치 변환 실패' ||
        _isMapMoving) {
      _showMessage('정확한 동네를 찾은 후 인증해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    final accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      _showMessage('로그인 정보가 없습니다. 다시 로그인해주세요.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('${Config.baseUrl}/api/users/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'location': _currentDong}), // '가좌동' 등의 문자열 전송
      );

      print(' 백엔드 응답 코드: ${response.statusCode}');
      print(' 백엔드 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        _showMessage('$_currentDong 인증이 완료되었습니다! 🎉');
        // 인증 성공 시 메인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage(errorData['message'] ?? '위치 인증에 실패했습니다.');
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('위치 인증 통신 에러: $error');
      _showMessage('서버 통신 에러가 발생했습니다.');
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '동네 설정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // 살짝 그림자 추가
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // 1. 구글 지도 영역
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mapCenterPosition,
              zoom: 16.0,
            ),
            myLocationEnabled: true, // 내 위치 파란 점 표시
            myLocationButtonEnabled: false, // 기본 버튼 숨김
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            // 지도를 드래그하기 시작할 때
            onCameraMoveStarted: () {
              setState(() {
                _isMapMoving = true;
                _currentDong = '위치 찾는 중...';
              });
            },
            // 지도를 드래그하는 중 (중심점 업데이트)
            onCameraMove: (CameraPosition position) {
              _mapCenterPosition = position.target;
            },
            // 지도를 멈췄을 때 (새로운 중심점의 주소 변환)
            onCameraIdle: () {
              setState(() => _isMapMoving = false);
              _updateAddressFromLatLng(_mapCenterPosition);
            },
          ),

          // 2. 화면 정중앙 고정 마커 (유저가 지도를 움직일 때 기준점)
          Center(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: _isMapMoving ? 50.0 : 35.0),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: const Color(0xFFFF7E36),
              ), // 당근마켓/BURUM 테마색
            ),
          ),

          // 3. 내 위치로 다시 돌아오는 버튼
          Positioned(
            right: 16,
            bottom: 230, // 바텀시트 위에 위치하도록
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _initCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // 4. 하단 바텀 시트 (동네 인증 정보 표시 영역)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 30.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 동네',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1, color: Color(0xFFE8E8E8)),
                  const SizedBox(height: 12),

                  // 현재 위치 텍스트
                  Text(
                    '현재 위치: $_currentDong',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isMapMoving ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 우리 동네 인증하기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isMapMoving)
                          ? null
                          : _verifyLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5ADBB5), // 사진 속 민트색
                        disabledBackgroundColor: Colors.grey[300], // 비활성화 시 색상
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                          : const Text(
                              '우리 동네 인증하기',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
