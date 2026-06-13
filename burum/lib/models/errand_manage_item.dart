import 'dart:convert';

class ErrandManageItem {
  final int id;
  final int userId;
  final String title;
  final String content;
  final int cost;
  final String status;
  final DateTime? deadline;
  final String? imageUrl;
  final String location;
  final int? assignedUserId;
  final int applicantCount;
  final int unreadApplicantCount;
  final bool assignedNoticeRead;
  final String nickname;
  final List<String> tags;

  ErrandManageItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.cost,
    required this.status,
    required this.deadline,
    required this.imageUrl,
    required this.location,
    required this.assignedUserId,
    required this.applicantCount,
    required this.unreadApplicantCount,
    required this.assignedNoticeRead,
    required this.nickname,
    required this.tags,
  });

  factory ErrandManageItem.fromJson(
    Map<String, dynamic> json, {
    int applicantCount = 0,
    int unreadApplicantCount = 0,
  }) {
    return ErrandManageItem(
      id: _toInt(json['id'] ?? json['post_id']),
      userId: _toInt(json['user_id'] ?? json['writer_id'] ?? json['writerId']),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      cost: _toInt(json['cost']),
      status: (json['status'] ?? 'WAITING').toString(),
      deadline: _parseDateTime(json['deadline']),
      imageUrl: _parseImageUrl(json['image_url']),
      location: (json['location'] ?? '').toString(),
      assignedUserId:
          (json['assigned_user_id'] ??
                  json['assignedUserId'] ??
                  json['assigned_id'] ??
                  json['worker_id']) ==
              null
          ? null
          : _toInt(
              json['assigned_user_id'] ??
                  json['assignedUserId'] ??
                  json['assigned_id'] ??
                  json['worker_id'],
            ),
      applicantCount: applicantCount,
      unreadApplicantCount: unreadApplicantCount,
      assignedNoticeRead: _toBool(json['assigned_notice_read']),
      nickname: _parseNickname(json),
      tags: _parseTags(json['tags']),
    );
  }

  bool get isWaiting => status.trim().toUpperCase() == 'WAITING';

  bool get isInProgress {
    // 🌟 대기 중(WAITING)도 아니고 완료(COMPLETED)도 아니면 진행 중인 것으로 간주합니다.
    // 이 방식은 서버에서 매칭된 상대 ID를 누락해서 보내주더라도 상태값만 맞으면 버튼을 띄워줍니다.
    final s = status.trim().toUpperCase();
    if (s == 'WAITING' || isCompleted) return false;
    return true;
  }

  bool get isCompleted {
    final s = status.trim().toUpperCase();
    // 🌟 다양한 완료 상태 키워드에 대응합니다.
    return s == 'COMPLETE' ||
        s == 'COMPLETED' ||
        s == 'FINISH' ||
        s == 'FINISHED';
  }

  bool get hasNewApplicantNotice {
    return isWaiting && unreadApplicantCount > 0;
  }

  bool get hasAssignedNotice {
    return isInProgress && assignedUserId != null && !assignedNoticeRead;
  }

  static String _parseNickname(Map<String, dynamic> json) {
    final dynamic user = json['user'];
    final dynamic writer = json['writer'];

    final String? found =
        json['nickname']?.toString() ??
        json['writerNickname']?.toString() ??
        json['writer_nickname']?.toString() ??
        json['author_nickname']?.toString() ??
        json['authorNickname']?.toString() ??
        // 객체 형태일 경우 ( { "user": { "nickname": "..." } } )
        (user is Map ? user['nickname']?.toString() : user?.toString()) ??
        (writer is Map ? writer['nickname']?.toString() : writer?.toString());

    if (found == null || found.trim().isEmpty || found == 'null')
      return '알 수 없음';
    return found;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _parseImageUrl(dynamic value) {
    if (value == null) return null;

    // 🌟 서버에서 이제 List<String> 형태로 내려주므로 직접 처리합니다.
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null' || text.startsWith('[')) {
      // 혹시라도 구버전(문자열)이 섞여있을 경우를 위한 방어 로직
      try {
        final decoded = jsonDecode(text);
        if (decoded is List && decoded.isNotEmpty)
          return decoded.first.toString();
      } catch (_) {}
    }

    return text;
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return [];

    // 🌟 서버에서 이제 List 형태로 내려주므로 바로 변환합니다.
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null' || text.startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return [];
  }
}
