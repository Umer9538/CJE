import 'package:cloud_firestore/cloud_firestore.dart';

/// Warning type enumeration
enum WarningType {
  verbal,
  written,
  suspension,
  removal,
}

extension WarningTypeExtension on WarningType {
  String get displayName {
    switch (this) {
      case WarningType.verbal:
        return 'Verbal Warning';
      case WarningType.written:
        return 'Written Warning';
      case WarningType.suspension:
        return 'Suspension';
      case WarningType.removal:
        return 'Removal';
    }
  }

  String get displayNameRo {
    switch (this) {
      case WarningType.verbal:
        return 'Avertisment Verbal';
      case WarningType.written:
        return 'Avertisment Scris';
      case WarningType.suspension:
        return 'Suspendare';
      case WarningType.removal:
        return 'Excludere';
    }
  }

  int get severity {
    switch (this) {
      case WarningType.verbal:
        return 1;
      case WarningType.written:
        return 2;
      case WarningType.suspension:
        return 3;
      case WarningType.removal:
        return 4;
    }
  }
}

/// Absence type enumeration
enum AbsenceType {
  excused,
  unexcused,
}

extension AbsenceTypeExtension on AbsenceType {
  String get displayName {
    switch (this) {
      case AbsenceType.excused:
        return 'Excused';
      case AbsenceType.unexcused:
        return 'Unexcused';
    }
  }

  String get displayNameRo {
    switch (this) {
      case AbsenceType.excused:
        return 'Motivată';
      case AbsenceType.unexcused:
        return 'Nemotivată';
    }
  }
}

/// Warning model for tracking user warnings
class WarningModel {
  final String id;
  final String userId;
  final String userName;
  final String? userSchoolId;
  final String? userSchoolName;
  final WarningType type;
  final String reason;
  final String? details;
  final String issuedById;
  final String issuedByName;
  final DateTime issuedAt;
  final DateTime? expiresAt; // For suspensions
  final bool isActive;
  final String? meetingId; // Related meeting if applicable
  final String countyId;

  const WarningModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userSchoolId,
    this.userSchoolName,
    required this.type,
    required this.reason,
    this.details,
    required this.issuedById,
    required this.issuedByName,
    required this.issuedAt,
    this.expiresAt,
    this.isActive = true,
    this.meetingId,
    required this.countyId,
  });

  factory WarningModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarningModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userSchoolId: data['userSchoolId'] as String?,
      userSchoolName: data['userSchoolName'] as String?,
      type: WarningType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => WarningType.verbal,
      ),
      reason: data['reason'] as String? ?? '',
      details: data['details'] as String?,
      issuedById: data['issuedById'] as String? ?? '',
      issuedByName: data['issuedByName'] as String? ?? '',
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      meetingId: data['meetingId'] as String?,
      countyId: data['countyId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userSchoolId': userSchoolId,
      'userSchoolName': userSchoolName,
      'type': type.name,
      'reason': reason,
      'details': details,
      'issuedById': issuedById,
      'issuedByName': issuedByName,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'meetingId': meetingId,
      'countyId': countyId,
    };
  }

  WarningModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userSchoolId,
    String? userSchoolName,
    WarningType? type,
    String? reason,
    String? details,
    String? issuedById,
    String? issuedByName,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? isActive,
    String? meetingId,
    String? countyId,
  }) {
    return WarningModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userSchoolId: userSchoolId ?? this.userSchoolId,
      userSchoolName: userSchoolName ?? this.userSchoolName,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      issuedById: issuedById ?? this.issuedById,
      issuedByName: issuedByName ?? this.issuedByName,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      meetingId: meetingId ?? this.meetingId,
      countyId: countyId ?? this.countyId,
    );
  }
}

/// Absence model for tracking meeting absences
class AbsenceModel {
  final String id;
  final String meetingId;
  final String meetingTitle;
  final DateTime meetingDate;
  final String userId;
  final String userName;
  final String? userSchoolId;
  final String? userSchoolName;
  final AbsenceType type;
  final String? reason;
  final String? justificationUrl; // Document proving excuse
  final String recordedById;
  final String recordedByName;
  final DateTime recordedAt;
  final String countyId;

  const AbsenceModel({
    required this.id,
    required this.meetingId,
    required this.meetingTitle,
    required this.meetingDate,
    required this.userId,
    required this.userName,
    this.userSchoolId,
    this.userSchoolName,
    required this.type,
    this.reason,
    this.justificationUrl,
    required this.recordedById,
    required this.recordedByName,
    required this.recordedAt,
    required this.countyId,
  });

  factory AbsenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AbsenceModel(
      id: doc.id,
      meetingId: data['meetingId'] as String? ?? '',
      meetingTitle: data['meetingTitle'] as String? ?? '',
      meetingDate: (data['meetingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userSchoolId: data['userSchoolId'] as String?,
      userSchoolName: data['userSchoolName'] as String?,
      type: AbsenceType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => AbsenceType.unexcused,
      ),
      reason: data['reason'] as String?,
      justificationUrl: data['justificationUrl'] as String?,
      recordedById: data['recordedById'] as String? ?? '',
      recordedByName: data['recordedByName'] as String? ?? '',
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      countyId: data['countyId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      'meetingDate': Timestamp.fromDate(meetingDate),
      'userId': userId,
      'userName': userName,
      'userSchoolId': userSchoolId,
      'userSchoolName': userSchoolName,
      'type': type.name,
      'reason': reason,
      'justificationUrl': justificationUrl,
      'recordedById': recordedById,
      'recordedByName': recordedByName,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'countyId': countyId,
    };
  }

  AbsenceModel copyWith({
    String? id,
    String? meetingId,
    String? meetingTitle,
    DateTime? meetingDate,
    String? userId,
    String? userName,
    String? userSchoolId,
    String? userSchoolName,
    AbsenceType? type,
    String? reason,
    String? justificationUrl,
    String? recordedById,
    String? recordedByName,
    DateTime? recordedAt,
    String? countyId,
  }) {
    return AbsenceModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      meetingDate: meetingDate ?? this.meetingDate,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userSchoolId: userSchoolId ?? this.userSchoolId,
      userSchoolName: userSchoolName ?? this.userSchoolName,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      justificationUrl: justificationUrl ?? this.justificationUrl,
      recordedById: recordedById ?? this.recordedById,
      recordedByName: recordedByName ?? this.recordedByName,
      recordedAt: recordedAt ?? this.recordedAt,
      countyId: countyId ?? this.countyId,
    );
  }
}
