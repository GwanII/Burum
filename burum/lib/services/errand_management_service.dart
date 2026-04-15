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

  Future<List<ErrandManageItem>> getMyRequestedErrands() async {
    final myId = await getMyUserId();
    final posts = await getAllPosts();

    final requestedPosts = posts.where((e) {
      if (e is! Map<String, dynamic>) return false;
      final userId = int.tryParse(e['user_id'].toString()) ?? 0;
      return userId == myId;
    }).toList();

    final items = await Future.wait(
      requestedPosts.map((post) async {
        final postId = int.tryParse(post['id'].toString()) ?? 0;
        int applicantCount = 0;

        try {
          final applicants = await getApplicants(postId);
          applicantCount = applicants.length;
        } catch (_) {
          applicantCount = 0;
        }

        return ErrandManageItem.fromJson(
          Map<String, dynamic>.from(post),
          applicantCount: applicantCount,
        );
      }),
    );

    items.sort((a, b) {
      final aTime = a.deadline?.millisecondsSinceEpoch ?? 0;
      final bTime = b.deadline?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return items;
  }

  Future<List<ErrandManageItem>> getMyAssignedErrands() async {
    final myId = await getMyUserId();
    final posts = await getAllPosts();

    final assignedPosts = posts.where((e) {
      if (e is! Map<String, dynamic>) return false;
      final assignedUserId = e['assigned_user_id'];
      if (assignedUserId == null) return false;
      final parsed = int.tryParse(assignedUserId.toString()) ?? 0;
      return parsed == myId;
    }).toList();

    final items = assignedPosts.map((post) {
      return ErrandManageItem.fromJson(
        Map<String, dynamic>.from(post),
        applicantCount: 0,
      );
    }).toList();

    items.sort((a, b) {
      final aTime = a.deadline?.millisecondsSinceEpoch ?? 0;
      final bTime = b.deadline?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return items;
  }

  Future<void> completeErrand(int postId) async {
    await _dio.put('/api/createErrand/$postId/complete');
  }

  Future<void> addToCalendar(ErrandManageItem item) async {
    final now = DateTime.now();
    final scheduleDate = item.deadline ?? now.add(const Duration(hours: 1));

    await _dio.post(
      '/api/calendar',
      data: {
        'title': item.title,
        'content': item.content.isEmpty ? '심부름 일정' : item.content,
        'location': item.location,
        'color': '#FFF59D',
        'alarm': '정각',
        'schedules': [
          {
            'datetime': scheduleDate.toIso8601String(),
          }
        ],
      },
    );
  }
}