import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Activity type enum for recent activities
enum ActivityType {
  userRegistered,
  userApproved,
  announcementPublished,
  pollCreated,
  pollEnded,
  meetingCreated,
  initiativeSubmitted,
  initiativeStatusChanged,
  documentUploaded;

  String toFirestore() => name;

  static ActivityType fromFirestore(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityType.userRegistered,
    );
  }
}

/// Activity model for admin dashboard recent activity section
class ActivityModel extends Equatable {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final String? targetId; // ID of related entity (user, announcement, poll, etc.)
  final String? targetType; // Type of related entity
  final String? actorId; // User who performed the action
  final String? actorName;
  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.targetId,
    this.targetType,
    this.actorId,
    this.actorName,
    required this.createdAt,
  });

  /// Create empty activity
  factory ActivityModel.empty() {
    return ActivityModel(
      id: '',
      type: ActivityType.userRegistered,
      title: '',
      subtitle: '',
      createdAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Create from Firestore document
  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      id: doc.id,
      type: ActivityType.fromFirestore(data['type'] as String? ?? 'userRegistered'),
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      targetId: data['targetId'] as String?,
      targetType: data['targetType'] as String?,
      actorId: data['actorId'] as String?,
      actorName: data['actorName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toFirestore(),
      'title': title,
      'subtitle': subtitle,
      'targetId': targetId,
      'targetType': targetType,
      'actorId': actorId,
      'actorName': actorName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy with new values
  ActivityModel copyWith({
    String? id,
    ActivityType? type,
    String? title,
    String? subtitle,
    String? targetId,
    String? targetType,
    String? actorId,
    String? actorName,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        targetId,
        targetType,
        actorId,
        actorName,
        createdAt,
      ];
}
