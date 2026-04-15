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
  });

  factory ErrandManageItem.fromJson(
    Map<String, dynamic> json, {
    int applicantCount = 0,
  }) {
    return ErrandManageItem(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      cost: _toInt(json['cost']),
      status: (json['status'] ?? 'WAITING').toString(),
      deadline: _parseDateTime(json['deadline']),
      imageUrl: _parseNullableString(json['image_url']),
      location: (json['location'] ?? '').toString(),
      assignedUserId: json['assigned_user_id'] == null
          ? null
          : _toInt(json['assigned_user_id']),
      applicantCount: applicantCount,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}