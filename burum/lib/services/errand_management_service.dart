import 'package:dio/dio.dart';
import 'package:burum/dio_client.dart';
import 'package:burum/models/errand_manage_item.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ErrandManagementService {
  final Dio _dio = DioClient.instance;
  final _storage = const FlutterSecureStorage();

  Future<int> getMyUserId() async {
    // 🌟 로그인 시 저장해둔 userId를 경로 파라미터에 넣기 위해 스토리지에서 읽어옵니다.
    final storedId = await _storage.read(key: 'userId');
    if (storedId != null) return int.tryParse(storedId) ?? 0;

    // 스토리지에 없을 경우 기존 프로필 API로 백업 시도
    final response = await _dio.get('/api/posts/profile');
    return int.tryParse(
          (response.data['id'] ?? response.data['userId'] ?? '0').toString(),
        ) ??
        0;
  }

  Future<List<dynamic>> getAllPosts() async {
    // 🌟 [복원] /api/createErrand에서 404가 발생했으므로, 원래 주소인 /api/posts로 복원합니다.
    // 이 주소가 전체 게시물 목록을 가져오는 데 사용될 가능성이 높습니다.
    final response = await _dio.get('/api/posts');

    final data = response.data;

    print('📡 [네트워크 수신] /api/createErrand 데이터: $data');

    if (data is List) return data;
    if (data is Map && data['posts'] is List) return data['posts'];
    if (data is Map && data['data'] is List) return data['data'];
    if (data is Map && data['result'] is List)
      return data['result']; // 🌟 추가: 'result' 키 대응
    return [];
  }

  Future<List<dynamic>> getApplicants(int postId) async {
    final response = await _dio.get('/api/posts/$postId/applicants');
    final data = response.data;

    if (data is List) return data;
    return [];
  }

  Future<List<ErrandManageItem>> getMyRequestedErrands(int myId) async {
    // 🌟 새로운 API 주소 사용: GET /api/users/profile/:id
    final response = await _dio.get('/api/users/profile/$myId');
    final data = response.data;
    print(
      '📡 [네트워크 수신] 프로필 데이터 키 확인: ${data is Map ? data.keys : "데이터가 Map 형식이 아닙니다"}',
    );

    // 🌟 프로필 데이터에서 닉네임을 추출하는 경로를 더 다양화합니다.
    final dynamic userRaw = data['user'];
    final String profileNickname =
        (data['nickname'] ??
                data['userNickname'] ??
                (userRaw is Map ? userRaw['nickname'] : userRaw) ??
                '알 수 없음')
            .toString();

    print('👤 확보된 프로필 닉네임: $profileNickname');

    // 서버 응답 구조 내에서 요청한 심부름 목록을 추출합니다. (createdPosts 키 추가)
    final List<dynamic> requestedPosts =
        data['requestedErrands'] ?? data['createdPosts'] ?? data['posts'] ?? [];

    final items = await Future.wait(
      requestedPosts.map((post) async {
        final map = Map<String, dynamic>.from(post as Map);

        // 💡 내가 작성한 글 리스트에는 닉네임이 생략될 수 있으므로, 없으면 프로필 닉네임을 주입합니다.
        if (map['nickname'] == null &&
            map['writer_nickname'] == null &&
            map['writerNickname'] == null &&
            map['user'] == null &&
            map['writer'] == null) {
          map['nickname'] = profileNickname;
        }

        final postId =
            int.tryParse((map['id'] ?? map['post_id'] ?? '').toString()) ?? 0;

        int applicantCount = 0;
        int unreadApplicantCount = 0;

        try {
          final applicants = await getApplicants(postId);
          applicantCount = applicants.length;

          unreadApplicantCount = applicants.where((applicant) {
            if (applicant is! Map) return false;

            final value = applicant['is_read_by_writer'];

            if (value == null) return true;
            if (value is int) return value == 0;
            if (value is bool) return value == false;

            return value.toString() == '0' ||
                value.toString().toLowerCase() == 'false';
          }).length;
        } catch (_) {
          applicantCount = 0;
          unreadApplicantCount = 0;
        }

        return ErrandManageItem.fromJson(
          map,
          applicantCount: applicantCount,
          unreadApplicantCount: unreadApplicantCount,
        );
      }),
    );

    items.sort((a, b) => b.id.compareTo(a.id));
    return items;
  }

  Future<List<ErrandManageItem>> getMyAssignedErrands(int myId) async {
    // 🌟 새로운 API 주소 사용: GET /api/users/profile/:id
    final response = await _dio.get('/api/users/profile/$myId');
    final data = response.data;

    // 서버 응답 구조 내에서 맡은 심부름 목록을 추출합니다.
    final List<dynamic> assignedPosts =
        data['assignedErrands'] ?? data['assignedPosts'] ?? [];

    final items = assignedPosts.map((post) {
      return ErrandManageItem.fromJson(
        Map<String, dynamic>.from(post as Map),
        applicantCount: 0,
        unreadApplicantCount: 0,
      );
    }).toList();

    items.sort((a, b) => b.id.compareTo(a.id));
    return items;
  }

  Future<void> markApplicantsAsRead(int postId) async {
    await _dio.put('/api/createErrand/$postId/read-applicants');
  }

  Future<void> markAssignedNoticeAsRead(int postId) async {
    await _dio.put('/api/createErrand/$postId/read-assigned');
  }

  Future<void> completeErrand(int postId, int rating, String comment) async {
    await _dio.post(
      '/api/createErrand/$postId/complete',
      data: {'rating': rating, 'comment': comment},
    );
  }

  Future<void> addToCalendar(ErrandManageItem item) async {
    final scheduleDate =
        item.deadline ?? DateTime.now().add(const Duration(hours: 1));

    await _dio.post(
      '/api/calendar',
      data: {
        'applicantId': item.assignedUserId,
        'title': item.title,
        'deadline': scheduleDate.toIso8601String(),
        'location': item.location,
      },
    );
  }
}
