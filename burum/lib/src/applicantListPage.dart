import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// DB 구조에 맞게 Applicant 모델
class Applicant {
  final int userId;
  final String profileImageUrl;
  final String name;
  final String level;
  final String timeAgo;
  final String specialty;
  final String introduction;
  // 🌟 [다중 선택 변경점 1] 백엔드에서 내려주는 status 값을 받을 변수 추가!
  final String status;

  Applicant({
    required this.userId,
    required this.profileImageUrl,
    required this.name,
    required this.level,
    required this.timeAgo,
    required this.specialty,
    required this.introduction,
    required this.status, // 추가됨
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      userId: json['user_id'] ?? 0,
      profileImageUrl: json['profile_image_url'] ?? 'https://picsum.photos/200',
      name: json['nickname'] ?? '이름 없음',
      level: json['grade'] ?? '등급 없음',
      timeAgo: '최근', // TODO: 시간 계산 로직
      specialty: json['user_title'] ?? '타이틀 없음',
      introduction: json['apply_message'] ?? '지원 메시지가 없습니다.',
      // 🌟 JSON에서 status 값을 파싱합니다. 없으면 기본값 'PENDING'
      status: json['status'] ?? 'PENDING',
    );
  }
}

class ApplicantListPage extends StatefulWidget {
  final String postId;

  const ApplicantListPage({super.key, required this.postId});

  @override
  State<ApplicantListPage> createState() => _ApplicantListPageState();
}

class _ApplicantListPageState extends State<ApplicantListPage> {
  List<Applicant> applicants = [];
  List<bool> _isExpandedList = [];
  bool isLoading = true;

  // 🌟 [다중 선택 변경점 2] 한 명만 기억하던 변수를 '바구니(List)'로 변경!
  List<int> selectedApplicantIds = [];

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    try {
      final url = Uri.parse(
        '${Config.baseUrl}/api/posts/${widget.postId}/applicants',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          applicants = data.map((json) => Applicant.fromJson(json)).toList();
          _isExpandedList = List.generate(applicants.length, (index) => true);

          // 🌟 [다중 선택 변경점 3] 서버에서 받아온 사람 중 상태가 'ACCEPTED'인 사람만 바구니에 쏙쏙 담습니다!
          selectedApplicantIds.clear();
          for (var applicant in applicants) {
            if (applicant.status == 'ACCEPTED') {
              selectedApplicantIds.add(applicant.userId);
            }
          }

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

  Future<void> _assignApplicant(int applicantId, String applicantName) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('지원자 선택'),
            content: Text('$applicantName님에게 이 심부름을 맡기시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('확인'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    const storage = FlutterSecureStorage();
    final token =
        await storage.read(key: 'accessToken') ??
        await storage.read(key: 'FlutterSecureStorage.accessToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
      );
      return;
    }

    try {
      final url = Uri.parse(
        '${Config.baseUrl}/api/createErrand/${widget.postId}/assign',
      );

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': applicantId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🎉 $applicantName님이 선택되었습니다!')),
          );
          setState(() {
            // 🌟 [다중 선택 변경점 4] 선택된 사람을 바구니에 '추가(add)' 합니다!
            selectedApplicantIds.add(applicantId);
          });
        }
      } else {
        print("선택 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("통신 에러: $e");
    }
  }

  Future<void> _cancelApplicant(int applicantId, String applicantName) async {
    const storage = FlutterSecureStorage();
    final token =
        await storage.read(key: 'accessToken') ??
        await storage.read(key: 'FlutterSecureStorage.accessToken');

    try {
      // 💡 이 부분은 백엔드에 만들어둔 '선택 취소' API 주소에 맞게 확인해 주세요!
      final url = Uri.parse(
        '${Config.baseUrl}/api/createErrand/${widget.postId}/cancelAssign',
      );

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // 취소할 유저 아이디도 백엔드에 보내줘야 할 수 있으니 바디를 추가합니다.
        body: jsonEncode({'userId': applicantId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $applicantName님 선택이 취소되었습니다.')),
          );
          setState(() {
            // 🌟 [다중 선택 변경점 5] 선택 취소된 사람을 바구니에서 '제거(remove)' 합니다!
            selectedApplicantIds.remove(applicantId);
          });
        }
      }
    } catch (e) {
      print("통신 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : applicants.isEmpty
          ? const Center(child: Text('아직 지원자가 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final applicant = applicants[index];
                final isExpanded = _isExpandedList[index];

                // 🌟 [다중 선택 변경점 6] 이 유저의 ID가 바구니(List) 안에 들어있는지 확인!
                final isSelected = selectedApplicantIds.contains(
                  applicant.userId,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(
                              applicant.profileImageUrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  applicant.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  applicant.specialty,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility_off_outlined,
                                color: Colors.black54,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpandedList[index] =
                                        !_isExpandedList[index];
                                  });
                                },
                                child: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 16),
                        Text(
                          applicant.introduction,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  print("${applicant.name}님과 채팅 시작!");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFF9C4),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  '채팅하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isSelected) {
                                    _cancelApplicant(
                                      applicant.userId,
                                      applicant.name,
                                    );
                                  } else {
                                    _assignApplicant(
                                      applicant.userId,
                                      applicant.name,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.grey[300]
                                      : const Color(0xFFFFF9C4),
                                  foregroundColor: isSelected
                                      ? Colors.black54
                                      : Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  isSelected ? '선택취소하기' : '선택하기',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
