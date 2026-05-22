import 'dart:convert';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.isCancelled,
    required this.createdAt,
    this.foreignId,
    this.payload,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int,
      foreignId: map['foreign_id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      isCancelled: (map['is_cancelled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      payload: map['payload'] != null
          ? jsonDecode(map['payload'] as String) as Map<String, dynamic>
          : null,
    );
  }

  final int id;
  final int? foreignId;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool isCancelled;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'foreign_id': foreignId,
    'title': title,
    'body': body,
    'payload': payload != null ? jsonEncode(payload) : null,
    'scheduled_at': scheduledAt.toIso8601String(),
    'is_cancelled': isCancelled ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };
}

class NewNotificationModel {
  const NewNotificationModel({
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.foreignId,
    this.payload,
  });

  final String title;
  final String body;
  final DateTime scheduledAt;
  final int? foreignId;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'foreign_id': foreignId,
    'title': title,
    'body': body,
    'scheduled_at': scheduledAt.toIso8601String(),
    'is_cancelled': 0,
    'payload': payload != null ? jsonEncode(payload) : null,
  };
}
