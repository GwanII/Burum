import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

// 🌟 1. DB 구조에 맞게 Applicant 모델 업데이트
class Applicant {
  final int userId;
  final String profileImageUrl;
  final String name;
  final String level;
  final String timeAgo;
  final String specialty;
  final String introduction;

  Applicant({
    required this.userId,
    required this.profileImageUrl,
    required this.name,
    required this.level,
    required this.timeAgo,
    required this.specialty,
    required this.introduction,
  });

  // 서버에서 받은 JSON 데이터를 Dart 객체로 바꿔주는 팩토리 함수
  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      userId: json['user_id'] ?? 0,
      profileImageUrl: json['profile_image_url'] ?? 'https://randomuser.me/api/portraits/lego/1.jpg', // 기본 이미지
      name: json['nickname'] ?? '이름 없음',
      level: json['grade'] ?? '등급 없음',
      timeAgo: '최근', // TODO: created_at을 계산해서 '몇 분 전'으로 바꾸는 로직 추가 가능
      specialty: json['user_title'] ?? '타이틀 없음',
      introduction: json['apply_message'] ?? '지원 메시지가 없습니다.',
    );
  }
}

class ApplicantListPage extends StatefulWidget {
  // 🌟 2. 어떤 게시물의 지원자 목록인지 알기 위해 postId를 받습니다!
  final String postId; 

  const ApplicantListPage({super.key, required this.postId});

  @override
  State<ApplicantListPage> createState() => _ApplicantListPageState();
}

class _ApplicantListPageState extends State<ApplicantListPage> {
  List<Applicant> applicants = [];
  bool isLoading = true; // 서버에서 데이터를 가져오는 동안 뱅글뱅글(로딩) 표시용

  @override
  void initState() {
    super.initState();
    _fetchApplicants(); // 화면이 켜지자마자 데이터 불러오기 시작!
  }

  // 🌟 3. 백엔드에서 지원자 목록을 가져오는 함수
  Future<void> _fetchApplicants() async {
    // ⚠️ 본인의 서버 IP/포트와 라우터 주소에 맞게 수정하세요! (안드로이드 에뮬레이터는 10.0.2.2)
    //final String url = 'http://10.0.2.2:3000/api/posts/${widget.postId}/applicants';

    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/api/posts/${widget.postId}/applicants'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // JSON 배열을 Applicant 객체 리스트로 변환
          applicants = data.map((json) => Applicant.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        print("서버 에러: 상태 코드 ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("통신 에러: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF799),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '지원자 목록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      // 🌟 4. 데이터 상태에 따라 화면을 다르게 보여줍니다.
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) // 로딩 중
          : applicants.isEmpty
              ? const Center(child: Text('아직 지원자가 없습니다.', style: TextStyle(fontSize: 16))) // 데이터 없음
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {
                    final applicant = applicants[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(applicant.profileImageUrl),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    applicant.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    applicant.specialty,
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    applicant.level,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5C6BC0),
                                    ),
                                  ),
                                  Text(
                                    applicant.timeAgo,
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Row(
                                children: [
                                  Icon(Icons.visibility_off_outlined, color: Colors.black54, size: 18),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_up, color: Colors.black54),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            applicant.introduction,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: 채팅하기
                                    print("${applicant.name}님과 채팅 시작!");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF9C4),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('채팅하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: 선택하기
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF9C4),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('선택하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}