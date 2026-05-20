import 'package:dio/dio.dart';
import 'package:burum/dio_client.dart';
import 'package:burum/models/errand_manage_item.dart';

class ErrandManagementService {
  final Dio _dio = DioClient.instance;

  Future<int> getMyUserId() async {
    final response = await _dio.get('/api/posts/profile');
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final id = data['id'];
      if (id is int) return id;
      return int.tryParse(id.toString()) ?? 0;
    }

    throw Exception('유저 정보를 불러오지 못했습니다.');
  }

  Future<List<dynamic>> getAllPosts() async {
    final response = await _dio.get('/api/posts');
    final data = response.data;

    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> getApplicants(int postId) async {
    final response = await _dio.get('/api/posts/$postId/applicants');
    final data = response.data;

    if (data is List) return data;
    return [];
  }

  Future<List<ErrandManageItem>> getMyRequestedErrands(int myId) async {
    final posts = await getAllPosts();

    final requestedPosts = posts.where((e) {
      if (e is! Map) return false;
      final userId = int.tryParse(e['user_id'].toString()) ?? 0;
      return userId == myId;
    }).toList();

    final items = await Future.wait(
      requestedPosts.map((post) async {
        final map = Map<String, dynamic>.from(post as Map);
        final postId = int.tryParse(map['id'].toString()) ?? 0;

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
    final posts = await getAllPosts();

    final assignedPosts = posts.where((e) {
      if (e is! Map) return false;

      final assignedUserId = e['assigned_user_id'];
      if (assignedUserId == null) return false;

      final parsed = int.tryParse(assignedUserId.toString()) ?? 0;
      return parsed == myId;
    }).toList();

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

  Future<void> completeErrand(int postId) async {
    await _dio.post('/api/createErrand/$postId/complete');
  }

  Future<void> addToCalendar(ErrandManageItem item) async {
  final scheduleDate = item.deadline ?? DateTime.now().add(const Duration(hours: 1));

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