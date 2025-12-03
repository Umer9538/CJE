import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Announcement/Communication model
class AnnouncementModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? summary; // Short preview text
  final AnnouncementType type;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String? schoolId; // Only for school announcements
  final String? schoolName;
  final String? imageUrl; // Featured image
  final List<String> attachmentUrls;
  final List<String> tags;
  final bool isPinned;
  final bool isPublished;
  final DateTime? publishedAt;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.type,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.schoolId,
    this.schoolName,
    this.imageUrl,
    this.attachmentUrls = const [],
    this.tags = const [],
    this.isPinned = false,
    this.isPublished = false,
    this.publishedAt,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty announcement
  factory AnnouncementModel.empty() {
    return AnnouncementModel(
      id: '',
      title: '',
      content: '',
      type: AnnouncementType.school,
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Check if this is a county-level announcement
  bool get isCountyAnnouncement => type == AnnouncementType.county;

  /// Get preview text (summary or truncated content)
  String get previewText {
    if (summary != null && summary!.isNotEmpty) return summary!;
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  /// Create from Firestore document
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      summary: data['summary'] as String?,
      type: AnnouncementType.fromFirestore(data['type'] as String? ?? 'school'),
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      schoolId: data['schoolId'] as String?,
      schoolName: data['schoolName'] as String?,
      imageUrl: data['imageUrl'] as String?,
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isPinned: data['isPinned'] as bool? ?? false,
      isPublished: data['isPublished'] as bool? ?? false,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'type': type.toFirestore(),
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'imageUrl': imageUrl,
      'attachmentUrls': attachmentUrls,
      'tags': tags,
      'isPinned': isPinned,
      'isPublished': isPublished,
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    AnnouncementType? type,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? schoolId,
    String? schoolName,
    String? imageUrl,
    List<String>? attachmentUrls,
    List<String>? tags,
    bool? isPinned,
    bool? isPublished,
    DateTime? publishedAt,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      imageUrl: imageUrl ?? this.imageUrl,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        summary,
        type,
        authorId,
        authorName,
        authorPhotoUrl,
        schoolId,
        schoolName,
        imageUrl,
        attachmentUrls,
        tags,
        isPinned,
        isPublished,
        publishedAt,
        viewCount,
        createdAt,
        updatedAt,
      ];
}
