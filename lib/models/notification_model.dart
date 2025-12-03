import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Notification model for push notifications and in-app notifications
class NotificationModel extends Equatable {
  final String id;
  final String userId; // Recipient user ID
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data; // Additional data (e.g., meetingId, announcementId)
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Create empty notification
  factory NotificationModel.empty() {
    return NotificationModel(
      id: '',
      userId: '',
      type: NotificationType.systemAlert,
      title: '',
      body: '',
      createdAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Get the route to navigate to when notification is tapped
  String? get targetRoute {
    if (data == null) return null;

    switch (type) {
      case NotificationType.meetingReminder:
        final meetingId = data!['meetingId'] as String?;
        return meetingId != null ? '/meetings/$meetingId' : '/meetings';
      case NotificationType.newAnnouncement:
        final announcementId = data!['announcementId'] as String?;
        return announcementId != null ? '/announcements/$announcementId' : '/announcements';
      case NotificationType.initiativeUpdate:
        final initiativeId = data!['initiativeId'] as String?;
        return initiativeId != null ? '/initiatives/$initiativeId' : '/initiatives';
      case NotificationType.pollReminder:
        final pollId = data!['pollId'] as String?;
        return pollId != null ? '/polls/$pollId' : '/polls';
      case NotificationType.systemAlert:
        return null;
    }
  }

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: NotificationType.fromFirestore(data['type'] as String? ?? 'systemAlert'),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toFirestore(),
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Copy with new values
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Mark as read
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        data,
        isRead,
        createdAt,
        readAt,
      ];
}
