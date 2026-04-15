import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import '../dio_client.dart';

// 🌟 상태가 변해야 하므로 StatefulWidget으로 변경!
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String title;
  final String content;
  final String currentUserId;
  final String writerId; // 다은 게시물 작성자 id 추가 ********
  final String price;
  final String date;
  final String nickname;
  final List<String> tags;
  final String? imageUrl;

  // 💡 홈 화면에서 이 게시물에 이미 지원했는지 여부를 넘겨받으면 좋습니다.
  // 기본값은 false로 설정했습니다.
  final bool initialIsApplied;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.currentUserId,
    required this.writerId, // 다은 ********
    required this.price,
    required this.date,
    required this.nickname,
    required this.tags,
    this.imageUrl,
    this.initialIsApplied = false, // 기본값 false
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // 🌟 현재 지원 상태를 추적하는 변수
  late bool _isApplied;

  @override
  void initState() {
    super.initState();
    // 화면이 켜질 때 초기 지원 상태를 가져옵니다.
    _isApplied = widget.initialIsApplied;
  }

  // 🌟 지원하기 통신 함수
  Future<void> _submitApplication(BuildContext context, String message) async {
    try {
      final response = await DioClient.instance.post(
        '/api/posts/applyErrand',
        data: {
          'postId': widget.postId,
          'userId': widget.currentUserId,
          'message': message,
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // 팝업 닫기
        setState(() {
          _isApplied = true; // 🌟 지원 완료 상태로 변경! (버튼이 바뀜)
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('🎉 지원이 성공적으로 완료되었습니다!')));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        if (context.mounted) {
          Navigator.pop(context);
          setState(() {
            _isApplied = true; // 💡 이미 지원한 경우이므로 상태를 바꿔줍니다.
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 지원한 심부름입니다! 🙅‍♂️'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('앗! 지원에 실패했어요. 다시 시도해주세요.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네트워크 오류가 발생했습니다. 연결 상태를 확인해주세요.')),
        );
      }
    }
  }

  // 🌟 지원 취소하기 통신 함수
  Future<void> _cancelApplication(BuildContext context, String reason) async {
    try {
      // 💡 취소 API 주소는 서버 설정에 맞게 변경해주세요!
      final response = await DioClient.instance.post(
        '/api/posts/cancelErrand',
        data: {
          'postId': widget.postId,
          'userId': widget.currentUserId,
          'reason': reason, // 🌟 선택한 취소 사유 전송
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // 팝업 닫기
        setState(() {
          _isApplied = false; // 🌟 다시 지원하기 상태로 변경!
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 지원이 취소되었습니다.')));
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('취소 처리에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('네트워크 오류가 발생했습니다.')));
      }
    }
  }

  // 🌟 취소 사유 다이얼로그 띄우기
  void _showCancelDialog() {
    // 4가지 취소 사유 리스트
    final List<String> cancelReasons = [
      '단순 변심',
      '일정 및 시간 변경',
      '조건 불일치',
      '기타 사유',
    ];
    String selectedReason = cancelReasons[0]; // 기본 선택값

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // 💡 팝업 안에서 라디오 버튼 상태를 실시간으로 바꾸기 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                '지원 취소 사유',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: cancelReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason, style: const TextStyle(fontSize: 14)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: Colors.redAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedReason = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('닫기', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    _cancelApplication(context, selectedReason);
                  },
                  child: const Text(
                    '취소 제출',
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
      },
    );
  }

  // 🌟 기존 지원하기 다이얼로그
  void _showApplyDialog() {
    TextEditingController applyMessageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.only(
            top: 25,
            left: 20,
            right: 20,
            bottom: 5,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '심부름 지원',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: applyMessageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '자기 소개, 각오 등 하고싶은 말을 적어주세요!',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                String message = applyMessageController.text.trim();
                if (message.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('지원 멘트를 작성해주세요!')),
                  );
                  return;
                }
                _submitApplication(context, message);
              },
              child: const Text(
                '지원',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 다은: ********
    final bool isWriter = widget.currentUserId == widget.writerId;
    //
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 이미지
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  ? Image.network(widget.imageUrl!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(height: 15),

            // 프로필 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage('https://picsum.photos/200'),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '심부름 마스터',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'B급',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(thickness: 1, color: Colors.black12),
            ),

            // 본문 내용 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.tags.map((tag) => '#$tag').join(' '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '마감일: ${widget.date}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '의뢰비: ${widget.price}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.content,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(thickness: 1, color: Colors.black12),
            ),

            // 지도 및 주소 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '주소 : 경상남도 진주시 가좌길36번길 17',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 180,
                    width: double.infinity,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(35.154, 128.114),
                        zoom: 16.0,
                      ),
                      markers: {
                        const Marker(
                          markerId: MarkerId('target_location'),
                          position: LatLng(35.154, 128.114),
                        ),
                      },
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // 하단 고정 버튼
      bottomNavigationBar: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(15.0),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_isApplied) {
            _showCancelDialog();
          } else {
            _showApplyDialog();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isApplied
              ? Colors.grey.shade300
              : const Color(0xFFFFF176),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          _isApplied ? '지원 취소하기' : '지원하기',
          style: TextStyle(
            color: _isApplied ? Colors.redAccent : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ),
),
    );
  }
}