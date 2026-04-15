import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
  final String status;

  Applicant({
    required this.userId,
    required this.profileImageUrl,
    required this.name,
    required this.level,
    required this.timeAgo,
    required this.specialty,
    required this.introduction,
    required this.status,
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
      status: json['status'] ?? 'PENDING',
    );
  }
}

class ApplicantListPage extends StatefulWidget {
  final String postId;
  final String postTitle;
  final String postDeadline;

  const ApplicantListPage({
    super.key, 
    required this.postId,
    required this.postTitle,    // 🌟 성빈이가 추가 
    required this.postDeadline  // 🌟 성빈이가 추가
  });

  @override
  State<ApplicantListPage> createState() => _ApplicantListPageState();
}

class _ApplicantListPageState extends State<ApplicantListPage> {
  List<Applicant> applicants = []; // 전체 지원자 (숨겨지지 않은)
  List<Applicant> hiddenApplicants = []; // 🌟 숨겨진 지원자들 보관함
  List<bool> _isExpandedList = [];
  List<bool> _isHiddenExpandedList = []; // 가린 사람들 전용 확장 상태

  bool isLoading = true;
  bool isShowingHiddenOnly = false; // 🌟 현재 가린 사람만 보고 있는지 여부

  List<int> selectedApplicantIds = [];
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    try {
      final url = '${Config.baseUrl}/api/posts/${widget.postId}/applicants';
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        setState(() {
          applicants = data.map((json) => Applicant.fromJson(json)).toList();
          _isExpandedList = List.generate(applicants.length, (index) => true);
          hiddenApplicants = [];
          _isHiddenExpandedList = [];

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

  // 🌟 지원자 숨기기 함수
  void _hideApplicant(int index) {
    setState(() {
      final target = applicants.removeAt(index);
      _isExpandedList.removeAt(index);
      hiddenApplicants.add(target);
      _isHiddenExpandedList.add(true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('지원자를 가렸습니다.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // 🌟 가린 지원자 다시 보이기 함수
  void _unhideApplicant(int index) {
    setState(() {
      final target = hiddenApplicants.removeAt(index);
      _isHiddenExpandedList.removeAt(index);
      applicants.add(target);
      _isExpandedList.add(true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('지원자를 다시 리스트에 표시합니다.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

// 🌟 선택하기 (수락) 로직
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
                child: const Text(
                  '확인',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

    try {
      final response = await dio.put(
        '${Config.baseUrl}/api/createErrand/${widget.postId}/assign',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {'userId': applicantId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        
        // 🌟 성빈이가 추가한 부분: 심부름 확정 성공 시 캘린더 자동 등록 API 호출!
        try {
          await dio.post(
            '${Config.baseUrl}/api/calendar/errand/dual', // 👈 주소 확인!
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            data: {
              'applicantId': applicantId, 
              'title': widget.postTitle, 
              'deadline': widget.postDeadline,
            },
          );

        } catch (calendarError) {
          print('🚨 캘린더 등록 실패: $calendarError');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🎉 $applicantName님이 선택되고 캘린더에 등록되었습니다!')),
          );
          setState(() => selectedApplicantIds.add(applicantId));
        }
      }
    } catch (e) {
      print(e);
    }
  }

  // 🌟 선택 취소하기
  Future<void> _cancelApplicant(int applicantId, String applicantName) async {
    String? selectedReason;
    final List<String> reasons = [
      '사용자가 연락을 받지 않음',
      '심부름 수행이 불가능한 환경',
      '부적절한 심부름 내용',
      '단순 변심 및 기타',
    ];

    // 1단계: 사유 선택 팝업
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext stateContext, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                '선택 취소 사유',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason, style: const TextStyle(fontSize: 15)),
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: Colors.redAccent,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (String? value) {
                        setDialogState(() {
                          selectedReason = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('닫기', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedReason != null) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('취소 사유를 선택해주세요.')),
                      );
                    }
                  },
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // 2단계: 최종 경고 팝업
    if (shouldCancel == true) {
      final bool? finalConfirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext confirmContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '선택 취소 경고',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              '$applicantName님에게 취소 알림이 전송됩니다.\n정말 선택을 취소하시겠습니까?\n\n※ 잦은 취소는 서비스 이용에 불이익이 있을 수 있으니 신중하게 결정해 주세요.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmContext, false),
                child: const Text('돌아가기', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(confirmContext, true),
                child: const Text(
                  '최종 취소하기',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      // 3단계: 확인 시 Dio 통신 진행
      if (finalConfirm == true) {
        const storage = FlutterSecureStorage();
        final token =
            await storage.read(key: 'accessToken') ??
            await storage.read(key: 'FlutterSecureStorage.accessToken');

        try {
          final url =
              '${Config.baseUrl}/api/createErrand/${widget.postId}/cancelAssign';
          final response = await dio.put(
            url,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
            data: {'userId': applicantId, 'reason': selectedReason},
          );

          if (response.statusCode == 200) {
            
            // 🌟 성빈이가 추가한 부분: 심부름 취소 성공 시 캘린더 일정 자동 삭제 API 호출!
            try {
              await dio.delete(
                '${Config.baseUrl}/api/calendar/errand/dual',
                options: Options(headers: {'Authorization': 'Bearer $token'}),
                data: {
                  'applicantId': applicantId,
                  'title': widget.postTitle, 
                },
              );
            } catch (calendarError) {
              print('🚨 캘린더 삭제 실패: $calendarError');
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ $applicantName님 선택이 취소되고 캘린더에서 삭제되었습니다.')),
              );
              setState(() => selectedApplicantIds.remove(applicantId));
            }
          } else {
            print("취소 실패: ${response.statusCode}");
          }
        } catch (e) {
          print("통신 에러: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 현재 모드에 따라 보여줄 리스트를 결정합니다.
    final currentList = isShowingHiddenOnly ? hiddenApplicants : applicants;
    final currentExpandedList = isShowingHiddenOnly
        ? _isHiddenExpandedList
        : _isExpandedList;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF799),
        elevation: 0,
        title: Text(
          isShowingHiddenOnly ? '가린 지원자' : '지원자 목록',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🌟 상단 눈 모양 필터 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            isShowingHiddenOnly = !isShowingHiddenOnly;
                          });
                        },
                        icon: Icon(
                          isShowingHiddenOnly
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: Colors.black87,
                        ),
                        label: Text(
                          isShowingHiddenOnly ? '전체 보기' : '가린 사람 보기',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 🌟 리스트 영역
                Expanded(
                  child: currentList.isEmpty
                      ? Center(
                          child: Text(
                            isShowingHiddenOnly
                                ? '가린 지원자가 없습니다.'
                                : '아직 지원자가 없습니다.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            final applicant = currentList[index];
                            final isExpanded = currentExpandedList[index];
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
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                      const SizedBox(width: 12),
                                      Row(
                                        children: [
                                          // 🌟 눈 아이콘 (숨기기 / 보이기)
                                          GestureDetector(
                                            onTap: () => isShowingHiddenOnly
                                                ? _unhideApplicant(index)
                                                : _hideApplicant(index),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ),
                                              child: Icon(
                                                isShowingHiddenOnly
                                                    ? Icons.visibility
                                                    : Icons
                                                          .visibility_off_outlined,
                                                color: isShowingHiddenOnly
                                                    ? Colors.blue
                                                    : Colors.black45,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => setState(
                                              () => currentExpandedList[index] =
                                                  !isExpanded,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ),
                                              child: Icon(
                                                isExpanded
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(height: 16),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFEEEEEE),
                                    ),
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
                                              print(
                                                "${applicant.name}님과 채팅 시작!",
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFFF9C4,
                                              ),
                                              foregroundColor: Colors.black,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                ),
              ],
            ),
    );
  }
}
