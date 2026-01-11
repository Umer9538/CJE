import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Poll model for surveys and voting
class PollModel extends Equatable {
  final String id;
  final String question;
  final String? description;

  // Translated content (stored in Firestore)
  final Map<String, String>? questionTranslations; // {'en': '...', 'ro': '...'}
  final Map<String, String>? descriptionTranslations;

  final PollType type;
  final List<PollOption> options;
  final String createdById;
  final String createdByName;
  final String? countyId; // County this poll belongs to
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
    this.questionTranslations,
    this.descriptionTranslations,
    required this.type,
    required this.options,
    required this.createdById,
    required this.createdByName,
    this.countyId,
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

  /// Get question for specific language (with fallback)
  String getQuestion(String languageCode) {
    if (questionTranslations != null && questionTranslations!.containsKey(languageCode)) {
      return questionTranslations![languageCode]!;
    }
    return question;
  }

  /// Get description for specific language (with fallback)
  String? getDescription(String languageCode) {
    if (descriptionTranslations != null && descriptionTranslations!.containsKey(languageCode)) {
      return descriptionTranslations![languageCode];
    }
    return description;
  }

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
      questionTranslations: data['questionTranslations'] != null
          ? Map<String, String>.from(data['questionTranslations'])
          : null,
      descriptionTranslations: data['descriptionTranslations'] != null
          ? Map<String, String>.from(data['descriptionTranslations'])
          : null,
      type: PollType.fromFirestore(data['type'] as String? ?? 'school'),
      options: (data['options'] as List<dynamic>?)
              ?.map((o) => PollOption.fromMap(o as Map<String, dynamic>))
              .toList() ??
          [],
      createdById: data['createdById'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      countyId: data['countyId'] as String?,
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
      'questionTranslations': questionTranslations,
      'descriptionTranslations': descriptionTranslations,
      'type': type.toFirestore(),
      'options': options.map((o) => o.toMap()).toList(),
      'createdById': createdById,
      'createdByName': createdByName,
      'countyId': countyId,
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
    Map<String, String>? questionTranslations,
    Map<String, String>? descriptionTranslations,
    PollType? type,
    List<PollOption>? options,
    String? createdById,
    String? createdByName,
    String? countyId,
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
      questionTranslations: questionTranslations ?? this.questionTranslations,
      descriptionTranslations: descriptionTranslations ?? this.descriptionTranslations,
      type: type ?? this.type,
      options: options ?? this.options,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      countyId: countyId ?? this.countyId,
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
        questionTranslations,
        descriptionTranslations,
        type,
        options,
        createdById,
        createdByName,
        countyId,
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
  final Map<String, String>? textTranslations; // {'en': '...', 'ro': '...'}
  final int voteCount;

  const PollOption({
    required this.id,
    required this.text,
    this.textTranslations,
    this.voteCount = 0,
  });

  /// Get text for specific language (with fallback)
  String getText(String languageCode) {
    if (textTranslations != null && textTranslations!.containsKey(languageCode)) {
      return textTranslations![languageCode]!;
    }
    return text;
  }

  /// Get vote percentage
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return voteCount / totalVotes * 100;
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      textTranslations: map['textTranslations'] != null
          ? Map<String, String>.from(map['textTranslations'])
          : null,
      voteCount: map['voteCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'textTranslations': textTranslations,
      'voteCount': voteCount,
    };
  }

  PollOption copyWith({
    String? id,
    String? text,
    Map<String, String>? textTranslations,
    int? voteCount,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      textTranslations: textTranslations ?? this.textTranslations,
      voteCount: voteCount ?? this.voteCount,
    );
  }

  @override
  List<Object?> get props => [id, text, textTranslations, voteCount];
}

/// Poll vote model for tracking individual votes (when poll is not anonymous)
class PollVote extends Equatable {
  final String id;
  final String pollId;
  final String voterId;
  final String voterName;
  final String? voterSchoolId;
  final String? voterSchoolName;
  final List<String> optionIds; // Which option(s) they voted for
  final List<String> optionTexts; // Option texts for display
  final DateTime createdAt;

  const PollVote({
    required this.id,
    required this.pollId,
    required this.voterId,
    required this.voterName,
    this.voterSchoolId,
    this.voterSchoolName,
    required this.optionIds,
    this.optionTexts = const [],
    required this.createdAt,
  });

  factory PollVote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollVote(
      id: doc.id,
      pollId: data['pollId'] as String? ?? '',
      voterId: data['voterId'] as String? ?? '',
      voterName: data['voterName'] as String? ?? '',
      voterSchoolId: data['voterSchoolId'] as String?,
      voterSchoolName: data['voterSchoolName'] as String?,
      optionIds: List<String>.from(data['optionIds'] ?? []),
      optionTexts: List<String>.from(data['optionTexts'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pollId': pollId,
      'voterId': voterId,
      'voterName': voterName,
      'voterSchoolId': voterSchoolId,
      'voterSchoolName': voterSchoolName,
      'optionIds': optionIds,
      'optionTexts': optionTexts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        pollId,
        voterId,
        voterName,
        voterSchoolId,
        voterSchoolName,
        optionIds,
        optionTexts,
        createdAt,
      ];
}
