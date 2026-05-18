import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 지도의 처음 시작 위치 (위도, 경도)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780), // 서울 시청 좌표
    zoom: 14.0, // 숫자(줌인/아웃)를 조절해 보세요!
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My First Map!'),
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