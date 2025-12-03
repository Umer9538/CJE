import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// User model representing a student council member
class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? city;
  final UserRole role;
  final UserStatus status;
  final String? schoolId;
  final String? schoolName;
  final String? className; // e.g., "12A", "11B"
  final DepartmentType? department; // Only for department members
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? fcmToken; // For push notifications
  final List<UserWarning> warnings; // Warning history
  final List<UserAbsence> absences; // Absence tracking

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.phoneNumber,
    this.city,
    required this.role,
    required this.status,
    this.schoolId,
    this.schoolName,
    this.className,
    this.department,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.fcmToken,
    this.warnings = const [],
    this.absences = const [],
  });

  /// Create empty user (for initial state)
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      fullName: '',
      role: UserRole.student,
      status: UserStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if user is empty/not logged in
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Check if user is a council member (not just a student)
  bool get isCouncilMember => role != UserRole.student;

  /// Check if user can manage school-level content
  bool get canManageSchool =>
      role == UserRole.schoolRep ||
      role == UserRole.bex ||
      role == UserRole.superadmin;

  /// Check if user can manage county-level content
  bool get canManageCounty =>
      role == UserRole.bex || role == UserRole.superadmin;

  /// Check if user is BEX or higher
  bool get isBEXOrHigher =>
      role == UserRole.bex || role == UserRole.superadmin;

  /// Get total warning count
  int get warningCount => warnings.length;

  /// Get total absence count
  int get absenceCount => absences.length;

  /// Check if user has active warnings
  bool get hasActiveWarnings => warnings.any((w) => w.isActive);

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      city: data['city'] as String?,
      role: UserRole.fromFirestore(data['role'] as String? ?? 'student'),
      status: UserStatus.fromFirestore(data['status'] as String? ?? 'pending'),
      schoolId: data['schoolId'] as String?,
      schoolName: data['schoolName'] as String?,
      className: data['className'] as String?,
      department: data['department'] != null
          ? DepartmentType.fromFirestore(data['department'] as String)
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
      warnings: (data['warnings'] as List<dynamic>?)
              ?.map((w) => UserWarning.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
      absences: (data['absences'] as List<dynamic>?)
              ?.map((a) => UserAbsence.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'city': city,
      'role': role.toFirestore(),
      'status': status.toFirestore(),
      'schoolId': schoolId,
      'schoolName': schoolName,
      'className': className,
      'department': department?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'fcmToken': fcmToken,
      'warnings': warnings.map((w) => w.toMap()).toList(),
      'absences': absences.map((a) => a.toMap()).toList(),
    };
  }

  /// Copy with new values
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    String? phoneNumber,
    String? city,
    UserRole? role,
    UserStatus? status,
    String? schoolId,
    String? schoolName,
    String? className,
    DepartmentType? department,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? fcmToken,
    List<UserWarning>? warnings,
    List<UserAbsence>? absences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      role: role ?? this.role,
      status: status ?? this.status,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      fcmToken: fcmToken ?? this.fcmToken,
      warnings: warnings ?? this.warnings,
      absences: absences ?? this.absences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        photoUrl,
        phoneNumber,
        city,
        role,
        status,
        schoolId,
        schoolName,
        className,
        department,
        createdAt,
        updatedAt,
        lastLoginAt,
        fcmToken,
        warnings,
        absences,
      ];
}

/// Warning model for user warnings
class UserWarning extends Equatable {
  final String id;
  final String reason;
  final String issuedById;
  final String issuedByName;
  final DateTime issuedAt;
  final DateTime? resolvedAt;
  final String? resolvedByName;
  final String? resolutionNote;

  const UserWarning({
    required this.id,
    required this.reason,
    required this.issuedById,
    required this.issuedByName,
    required this.issuedAt,
    this.resolvedAt,
    this.resolvedByName,
    this.resolutionNote,
  });

  /// Check if warning is still active
  bool get isActive => resolvedAt == null;

  factory UserWarning.fromMap(Map<String, dynamic> map) {
    return UserWarning(
      id: map['id'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      issuedById: map['issuedById'] as String? ?? '',
      issuedByName: map['issuedByName'] as String? ?? '',
      issuedAt: (map['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedByName: map['resolvedByName'] as String?,
      resolutionNote: map['resolutionNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'issuedById': issuedById,
      'issuedByName': issuedByName,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedByName': resolvedByName,
      'resolutionNote': resolutionNote,
    };
  }

  UserWarning copyWith({
    String? id,
    String? reason,
    String? issuedById,
    String? issuedByName,
    DateTime? issuedAt,
    DateTime? resolvedAt,
    String? resolvedByName,
    String? resolutionNote,
  }) {
    return UserWarning(
      id: id ?? this.id,
      reason: reason ?? this.reason,
      issuedById: issuedById ?? this.issuedById,
      issuedByName: issuedByName ?? this.issuedByName,
      issuedAt: issuedAt ?? this.issuedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }

  @override
  List<Object?> get props => [id, reason, issuedById, issuedByName, issuedAt, resolvedAt, resolvedByName, resolutionNote];
}

/// Absence model for tracking user absences
class UserAbsence extends Equatable {
  final String id;
  final String meetingId;
  final String meetingTitle;
  final DateTime meetingDate;
  final String? reason;
  final bool isExcused;
  final String recordedById;
  final String recordedByName;
  final DateTime recordedAt;

  const UserAbsence({
    required this.id,
    required this.meetingId,
    required this.meetingTitle,
    required this.meetingDate,
    this.reason,
    this.isExcused = false,
    required this.recordedById,
    required this.recordedByName,
    required this.recordedAt,
  });

  factory UserAbsence.fromMap(Map<String, dynamic> map) {
    return UserAbsence(
      id: map['id'] as String? ?? '',
      meetingId: map['meetingId'] as String? ?? '',
      meetingTitle: map['meetingTitle'] as String? ?? '',
      meetingDate: (map['meetingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: map['reason'] as String?,
      isExcused: map['isExcused'] as bool? ?? false,
      recordedById: map['recordedById'] as String? ?? '',
      recordedByName: map['recordedByName'] as String? ?? '',
      recordedAt: (map['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      'meetingDate': Timestamp.fromDate(meetingDate),
      'reason': reason,
      'isExcused': isExcused,
      'recordedById': recordedById,
      'recordedByName': recordedByName,
      'recordedAt': Timestamp.fromDate(recordedAt),
    };
  }

  UserAbsence copyWith({
    String? id,
    String? meetingId,
    String? meetingTitle,
    DateTime? meetingDate,
    String? reason,
    bool? isExcused,
    String? recordedById,
    String? recordedByName,
    DateTime? recordedAt,
  }) {
    return UserAbsence(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      meetingDate: meetingDate ?? this.meetingDate,
      reason: reason ?? this.reason,
      isExcused: isExcused ?? this.isExcused,
      recordedById: recordedById ?? this.recordedById,
      recordedByName: recordedByName ?? this.recordedByName,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props => [id, meetingId, meetingTitle, meetingDate, reason, isExcused, recordedById, recordedByName, recordedAt];
}
