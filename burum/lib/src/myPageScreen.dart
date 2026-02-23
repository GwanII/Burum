import 'package:flutter/material.dart';
import 'homeScreen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF59D), // 피그마 노란색 배경
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 프로필 영역
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 이미지 (임시로 기본 아이콘 사용)
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage(
                        'https://picsum.photos/200'), // 실제 이미지 URL 또는 AssetImage로 변경
                  ),
                  const SizedBox(width: 20),
                  
                  // 닉네임 & 칭호 정보 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 닉네임 행
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '닉네임',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '가황 진짜\n씹간지네',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            // 우측 화살표
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 칭호 & 등급 행
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '칭호',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '심부름 마스터',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            // 등급 표시
                            Column(
                              children: const [
                                Text(
                                  '등급',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                Text(
                                  'B급',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo), // 피그마의 파란색 텍스트
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 2. 구분선
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 10),

              // 3. 심부름 메뉴 영역
              const Text(
                '심부름',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              
              // 작성한 심부름 / 완료한 심부름 (1열)
              Row(
                children: [
                  // 왼쪽 칸 (50%)
                  Expanded(
                    child: _buildMenuButton('작성한 심부름', () {
                      // TODO: 작성한 심부름 화면으로 이동
                    }),
                  ),
                  // 오른쪽 칸 (50%)
                  Expanded(
                    child: _buildMenuButton('완료한 심부름', () {
                      // TODO: 완료한 심부름 화면으로 이동
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  // 왼쪽 칸 (50%) - 위와 완벽하게 줄이 맞습니다!
                  Expanded(
                    child: _buildMenuButton('지원한 심부름', () {
                      // TODO: 지원한 심부름 화면으로 이동
                    }),
                  ),
                  // 오른쪽 칸 (50%) - 빈 공간으로 채워둠
                  const Expanded(
                    child: SizedBox(), 
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // 메뉴 텍스트 버튼을 만드는 도우미 함수
  Widget _buildMenuButton(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}