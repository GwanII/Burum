import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // 위도, 경도 다루는 도구

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. 상단 앱바 (뒤로가기 버튼이 자동으로 생깁니다)
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176), // 노란색 테마
        title: const Text(
          '지도로 보기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black), // 뒤로가기 버튼 검정색
        centerTitle: true,
      ),

      // 2. 지도 영역
      body: FlutterMap(
        options: const MapOptions(
        initialCenter: LatLng(35.1567, 128.1045), 
          initialZoom: 17.0, // 건물 찾기 좋게 좀 더 확대
        ),
        children: [
          // (1) 지도 타일 (오픈스트리트맵 - 무료)
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.burum',
          ),

          // (2) 심부름 마커들 (핀)
          MarkerLayer(
            markers: [
              // 마커 1: 카레 심부름
              Marker(
                point: const LatLng(35.1568, 128.1045), 
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
              // 마커 2: 수리검 심부름
              Marker(
                point: const LatLng(35.1567, 128.105), 
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
              // 마커 3: 헬스 보조
              Marker(
                point: const LatLng(35.159, 128.108), 
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}