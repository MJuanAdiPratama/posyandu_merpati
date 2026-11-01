class NotificationModel {
  final String id;
  final String userId;
  final String? balitaId;
  final String title;
  final String message;
  final String type;
  final DateTime? scheduledAt;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.balitaId,
    required this.title,
    required this.message,
    required this.type,
    this.scheduledAt,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balitaId: json['balita_id'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balita_id': balitaId,
      'title': title,
      'message': message,
      'type': type,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      balitaId: balitaId,
      title: title,
      message: message,
      type: type,
      scheduledAt: scheduledAt,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
