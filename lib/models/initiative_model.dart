import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Initiative model representing student council initiatives/proposals
class InitiativeModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? problem; // Problem statement
  final String? solution; // Proposed solution
  final String? impact; // Expected impact
  final InitiativeStatus status;
  final String authorId;
  final String authorName;
  final String? schoolId; // If school-level initiative
  final String? schoolName;
  final List<String> supporterIds; // Users who support this initiative
  final int supportCount;
  final int requiredSupport; // Number of supporters needed to proceed
  final List<String> tags;
  final List<String> attachmentUrls;
  final DateTime? submittedAt;
  final DateTime? reviewStartedAt;
  final DateTime? debateStartedAt;
  final DateTime? votingStartedAt;
  final DateTime? votingEndedAt;
  final int? votesFor;
  final int? votesAgainst;
  final int? votesAbstain;
  final String? rejectionReason;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InitiativeModel({
    required this.id,
    required this.title,
    required this.description,
    this.problem,
    this.solution,
    this.impact,
    required this.status,
    required this.authorId,
    required this.authorName,
    this.schoolId,
    this.schoolName,
    this.supporterIds = const [],
    this.supportCount = 0,
    this.requiredSupport = 10,
    this.tags = const [],
    this.attachmentUrls = const [],
    this.submittedAt,
    this.reviewStartedAt,
    this.debateStartedAt,
    this.votingStartedAt,
    this.votingEndedAt,
    this.votesFor,
    this.votesAgainst,
    this.votesAbstain,
    this.rejectionReason,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty initiative
  factory InitiativeModel.empty() {
    return InitiativeModel(
      id: '',
      title: '',
      description: '',
      status: InitiativeStatus.draft,
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Check if initiative has enough support to proceed
  bool get hasEnoughSupport => supportCount >= requiredSupport;

  /// Calculate support percentage
  double get supportPercentage =>
      requiredSupport > 0 ? (supportCount / requiredSupport * 100).clamp(0, 100) : 0;

  /// Check if voting has ended
  bool get hasVotingEnded =>
      votingEndedAt != null && DateTime.now().isAfter(votingEndedAt!);

  /// Get total votes
  int get totalVotes => (votesFor ?? 0) + (votesAgainst ?? 0) + (votesAbstain ?? 0);

  /// Get approval percentage (excluding abstentions)
  double get approvalPercentage {
    final validVotes = (votesFor ?? 0) + (votesAgainst ?? 0);
    if (validVotes == 0) return 0;
    return (votesFor ?? 0) / validVotes * 100;
  }

  /// Create from Firestore document
  factory InitiativeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InitiativeModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      problem: data['problem'] as String?,
      solution: data['solution'] as String?,
      impact: data['impact'] as String?,
      status: InitiativeStatus.fromFirestore(data['status'] as String? ?? 'draft'),
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      schoolId: data['schoolId'] as String?,
      schoolName: data['schoolName'] as String?,
      supporterIds: List<String>.from(data['supporterIds'] ?? []),
      supportCount: data['supportCount'] as int? ?? 0,
      requiredSupport: data['requiredSupport'] as int? ?? 10,
      tags: List<String>.from(data['tags'] ?? []),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      reviewStartedAt: (data['reviewStartedAt'] as Timestamp?)?.toDate(),
      debateStartedAt: (data['debateStartedAt'] as Timestamp?)?.toDate(),
      votingStartedAt: (data['votingStartedAt'] as Timestamp?)?.toDate(),
      votingEndedAt: (data['votingEndedAt'] as Timestamp?)?.toDate(),
      votesFor: data['votesFor'] as int?,
      votesAgainst: data['votesAgainst'] as int?,
      votesAbstain: data['votesAbstain'] as int?,
      rejectionReason: data['rejectionReason'] as String?,
      reviewNotes: data['reviewNotes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'problem': problem,
      'solution': solution,
      'impact': impact,
      'status': status.toFirestore(),
      'authorId': authorId,
      'authorName': authorName,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'supporterIds': supporterIds,
      'supportCount': supportCount,
      'requiredSupport': requiredSupport,
      'tags': tags,
      'attachmentUrls': attachmentUrls,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'reviewStartedAt': reviewStartedAt != null ? Timestamp.fromDate(reviewStartedAt!) : null,
      'debateStartedAt': debateStartedAt != null ? Timestamp.fromDate(debateStartedAt!) : null,
      'votingStartedAt': votingStartedAt != null ? Timestamp.fromDate(votingStartedAt!) : null,
      'votingEndedAt': votingEndedAt != null ? Timestamp.fromDate(votingEndedAt!) : null,
      'votesFor': votesFor,
      'votesAgainst': votesAgainst,
      'votesAbstain': votesAbstain,
      'rejectionReason': rejectionReason,
      'reviewNotes': reviewNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  InitiativeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? problem,
    String? solution,
    String? impact,
    InitiativeStatus? status,
    String? authorId,
    String? authorName,
    String? schoolId,
    String? schoolName,
    List<String>? supporterIds,
    int? supportCount,
    int? requiredSupport,
    List<String>? tags,
    List<String>? attachmentUrls,
    DateTime? submittedAt,
    DateTime? reviewStartedAt,
    DateTime? debateStartedAt,
    DateTime? votingStartedAt,
    DateTime? votingEndedAt,
    int? votesFor,
    int? votesAgainst,
    int? votesAbstain,
    String? rejectionReason,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InitiativeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      problem: problem ?? this.problem,
      solution: solution ?? this.solution,
      impact: impact ?? this.impact,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      supporterIds: supporterIds ?? this.supporterIds,
      supportCount: supportCount ?? this.supportCount,
      requiredSupport: requiredSupport ?? this.requiredSupport,
      tags: tags ?? this.tags,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewStartedAt: reviewStartedAt ?? this.reviewStartedAt,
      debateStartedAt: debateStartedAt ?? this.debateStartedAt,
      votingStartedAt: votingStartedAt ?? this.votingStartedAt,
      votingEndedAt: votingEndedAt ?? this.votingEndedAt,
      votesFor: votesFor ?? this.votesFor,
      votesAgainst: votesAgainst ?? this.votesAgainst,
      votesAbstain: votesAbstain ?? this.votesAbstain,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        problem,
        solution,
        impact,
        status,
        authorId,
        authorName,
        schoolId,
        schoolName,
        supporterIds,
        supportCount,
        requiredSupport,
        tags,
        attachmentUrls,
        submittedAt,
        reviewStartedAt,
        debateStartedAt,
        votingStartedAt,
        votingEndedAt,
        votesFor,
        votesAgainst,
        votesAbstain,
        rejectionReason,
        reviewNotes,
        createdAt,
        updatedAt,
      ];
}

/// Initiative comment model
class InitiativeComment extends Equatable {
  final String id;
  final String initiativeId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final bool isOfficial; // Official response from BEX/admin
  final DateTime createdAt;

  const InitiativeComment({
    required this.id,
    required this.initiativeId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.isOfficial = false,
    required this.createdAt,
  });

  factory InitiativeComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InitiativeComment(
      id: doc.id,
      initiativeId: data['initiativeId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      content: data['content'] as String? ?? '',
      isOfficial: data['isOfficial'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'initiativeId': initiativeId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'isOfficial': isOfficial,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        initiativeId,
        authorId,
        authorName,
        authorPhotoUrl,
        content,
        isOfficial,
        createdAt,
      ];
}
