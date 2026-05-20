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
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      cost: _toInt(json['cost']),
      status: (json['status'] ?? 'WAITING').toString(),
      deadline: _parseDateTime(json['deadline']),
      imageUrl: _parseImageUrl(json['image_url']),
      location: (json['location'] ?? '').toString(),
      assignedUserId: json['assigned_user_id'] == null
          ? null
          : _toInt(json['assigned_user_id']),
      applicantCount: applicantCount,
      unreadApplicantCount: unreadApplicantCount,
      assignedNoticeRead: _toBool(json['assigned_notice_read']),
      nickname: (json['nickname'] ??
              json['writerNickname'] ??
              json['writer_nickname'] ??
              '알 수 없음')
          .toString(),
      tags: _parseTags(json['tags']),
    );
  }

  bool get isWaiting => status == 'WAITING';
  
bool get isInProgress {
  final s = status.trim().toUpperCase();
  return s == 'MATCHED' || s == 'IN_PROGRESS';
}

bool get isCompleted {
  final s = status.trim().toUpperCase();
  return s == 'COMPLETE' || s == 'COMPLETED';
}
  bool get hasNewApplicantNotice {
    return isWaiting && unreadApplicantCount > 0;
  }

  bool get hasAssignedNotice {
    return isInProgress && assignedUserId != null && !assignedNoticeRead;
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

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    try {
      final decoded = jsonDecode(text);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded.first.toString();
      }
    } catch (_) {}

    return text;
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return [];

    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return [];
  }
}