import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Poll model for surveys and voting
class PollModel extends Equatable {
  final String id;
  final String question;
  final String? description;
  final PollType type;
  final List<PollOption> options;
  final String createdById;
  final String createdByName;
  final String? schoolId; // Only for school polls
  final String? schoolName;
  final bool isAnonymous;
  final bool allowMultipleVotes;
  final DateTime startDate;
  final DateTime endDate;
  final int totalVotes;
  final List<String> voterIds; // Track who voted (not which option if anonymous)
  final DateTime createdAt;
  final DateTime updatedAt;

  const PollModel({
    required this.id,
    required this.question,
    this.description,
    required this.type,
    required this.options,
    required this.createdById,
    required this.createdByName,
    this.schoolId,
    this.schoolName,
    this.isAnonymous = true,
    this.allowMultipleVotes = false,
    required this.startDate,
    required this.endDate,
    this.totalVotes = 0,
    this.voterIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty poll
  factory PollModel.empty() {
    return PollModel(
      id: '',
      question: '',
      type: PollType.school,
      options: const [],
      createdById: '',
      createdByName: '',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Check if poll is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if poll has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  /// Check if poll hasn't started yet
  bool get isPending => DateTime.now().isBefore(startDate);

  /// Get poll status
  PollStatus get status => hasEnded ? PollStatus.ended : PollStatus.active;

  /// Check if user has voted
  bool hasUserVoted(String userId) => voterIds.contains(userId);

  /// Get winning option(s)
  List<PollOption> get winningOptions {
    if (options.isEmpty) return [];
    final maxVotes = options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b);
    return options.where((o) => o.voteCount == maxVotes).toList();
  }

  /// Create from Firestore document
  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollModel(
      id: doc.id,
      question: data['question'] as String? ?? '',
      description: data['description'] as String?,
      type: PollType.fromFirestore(data['type'] as String? ?? 'school'),
      options: (data['options'] as List<dynamic>?)
              ?.map((o) => PollOption.fromMap(o as Map<String, dynamic>))
              .toList() ??
          [],
      createdById: data['createdById'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      schoolId: data['schoolId'] as String?,
      schoolName: data['schoolName'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      allowMultipleVotes: data['allowMultipleVotes'] as bool? ?? false,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      totalVotes: data['totalVotes'] as int? ?? 0,
      voterIds: List<String>.from(data['voterIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'description': description,
      'type': type.toFirestore(),
      'options': options.map((o) => o.toMap()).toList(),
      'createdById': createdById,
      'createdByName': createdByName,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'isAnonymous': isAnonymous,
      'allowMultipleVotes': allowMultipleVotes,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalVotes': totalVotes,
      'voterIds': voterIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  PollModel copyWith({
    String? id,
    String? question,
    String? description,
    PollType? type,
    List<PollOption>? options,
    String? createdById,
    String? createdByName,
    String? schoolId,
    String? schoolName,
    bool? isAnonymous,
    bool? allowMultipleVotes,
    DateTime? startDate,
    DateTime? endDate,
    int? totalVotes,
    List<String>? voterIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PollModel(
      id: id ?? this.id,
      question: question ?? this.question,
      description: description ?? this.description,
      type: type ?? this.type,
      options: options ?? this.options,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      allowMultipleVotes: allowMultipleVotes ?? this.allowMultipleVotes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalVotes: totalVotes ?? this.totalVotes,
      voterIds: voterIds ?? this.voterIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        description,
        type,
        options,
        createdById,
        createdByName,
        schoolId,
        schoolName,
        isAnonymous,
        allowMultipleVotes,
        startDate,
        endDate,
        totalVotes,
        voterIds,
        createdAt,
        updatedAt,
      ];
}

/// Poll option model
class PollOption extends Equatable {
  final String id;
  final String text;
  final int voteCount;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
  });

  /// Get vote percentage
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return voteCount / totalVotes * 100;
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      voteCount: map['voteCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
    };
  }

  PollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
    );
  }

  @override
  List<Object?> get props => [id, text, voteCount];
}
