import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_strings.dart';

/// ============================================
/// USER ROLE ENUM
/// ============================================
/// 6 user roles in the CJE Platform hierarchy
enum UserRole {
  student,
  classRep,
  schoolRep,
  department,
  bex,
  superadmin;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case UserRole.student:
        return AppStrings.roleStudent;
      case UserRole.classRep:
        return AppStrings.roleClassRep;
      case UserRole.schoolRep:
        return AppStrings.roleSchoolRep;
      case UserRole.department:
        return AppStrings.roleDepartment;
      case UserRole.bex:
        return AppStrings.roleBEX;
      case UserRole.superadmin:
        return AppStrings.roleSuperadmin;
    }
  }

  /// Get badge background color
  Color get badgeBackgroundColor {
    switch (this) {
      case UserRole.student:
        return AppColors.badgeStudentBg;
      case UserRole.classRep:
        return AppColors.badgeClassRepBg;
      case UserRole.schoolRep:
        return AppColors.badgeSchoolRepBg;
      case UserRole.department:
        return AppColors.badgeDepartmentBg;
      case UserRole.bex:
        return AppColors.badgeBEXBg;
      case UserRole.superadmin:
        return AppColors.badgeSuperadminBg;
    }
  }

  /// Get badge text color
  Color get badgeTextColor {
    switch (this) {
      case UserRole.student:
        return AppColors.badgeStudentText;
      case UserRole.classRep:
        return AppColors.badgeClassRepText;
      case UserRole.schoolRep:
        return AppColors.badgeSchoolRepText;
      case UserRole.department:
        return AppColors.badgeDepartmentText;
      case UserRole.bex:
        return AppColors.badgeBEXText;
      case UserRole.superadmin:
        return AppColors.badgeSuperadminText;
    }
  }

  /// Get hierarchy level (higher = more permissions)
  int get hierarchyLevel {
    switch (this) {
      case UserRole.student:
        return 1;
      case UserRole.classRep:
        return 2;
      case UserRole.schoolRep:
        return 3;
      case UserRole.department:
        return 3; // Same level as school rep
      case UserRole.bex:
        return 4;
      case UserRole.superadmin:
        return 5;
    }
  }

  /// Check if this role has higher or equal permissions than another role
  bool hasPermissionOver(UserRole other) {
    return hierarchyLevel >= other.hierarchyLevel;
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static UserRole fromFirestore(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.student,
    );
  }
}

/// ============================================
/// USER STATUS ENUM
/// ============================================
enum UserStatus {
  active,
  suspended,
  pending;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return AppStrings.statusActive;
      case UserStatus.suspended:
        return AppStrings.statusSuspended;
      case UserStatus.pending:
        return AppStrings.statusPending;
    }
  }

  /// Get status color
  Color get color {
    switch (this) {
      case UserStatus.active:
        return AppColors.successLight;
      case UserStatus.suspended:
        return AppColors.errorLight;
      case UserStatus.pending:
        return AppColors.warningLight;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static UserStatus fromFirestore(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserStatus.pending,
    );
  }
}

/// ============================================
/// DEPARTMENT TYPE ENUM
/// ============================================
/// 3 departments in the CJE structure
enum DepartmentType {
  prCommunications,
  volunteering,
  schoolInclusion;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case DepartmentType.prCommunications:
        return AppStrings.deptPRCommunications;
      case DepartmentType.volunteering:
        return AppStrings.deptVolunteering;
      case DepartmentType.schoolInclusion:
        return AppStrings.deptSchoolInclusion;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static DepartmentType fromFirestore(String value) {
    return DepartmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DepartmentType.prCommunications,
    );
  }
}

/// ============================================
/// MEETING TYPE ENUM
/// ============================================
/// 4 types of meetings
enum MeetingType {
  countyAG,
  bex,
  department,
  school;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case MeetingType.countyAG:
        return AppStrings.meetingCountyAG;
      case MeetingType.bex:
        return AppStrings.meetingBEX;
      case MeetingType.department:
        return AppStrings.meetingDepartment;
      case MeetingType.school:
        return AppStrings.meetingSchool;
    }
  }

  /// Get meeting type color
  Color get color {
    switch (this) {
      case MeetingType.countyAG:
        return AppColors.meetingCountyAG;
      case MeetingType.bex:
        return AppColors.meetingBEX;
      case MeetingType.department:
        return AppColors.meetingDepartment;
      case MeetingType.school:
        return AppColors.meetingSchool;
    }
  }

  /// Get accent color (for county AG)
  Color get accentColor {
    switch (this) {
      case MeetingType.countyAG:
        return AppColors.meetingCountyAGAccent;
      default:
        return color;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static MeetingType fromFirestore(String value) {
    return MeetingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeetingType.school,
    );
  }
}

/// ============================================
/// INITIATIVE STATUS ENUM
/// ============================================
/// Initiative lifecycle: Draft → Submitted → Review → Debate → Voting → Adopted/Rejected
enum InitiativeStatus {
  draft,
  submitted,
  review,
  debate,
  voting,
  adopted,
  rejected;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case InitiativeStatus.draft:
        return AppStrings.initiativeStatusDraft;
      case InitiativeStatus.submitted:
        return AppStrings.initiativeStatusSubmitted;
      case InitiativeStatus.review:
        return AppStrings.initiativeStatusReview;
      case InitiativeStatus.debate:
        return AppStrings.initiativeStatusDebate;
      case InitiativeStatus.voting:
        return AppStrings.initiativeStatusVoting;
      case InitiativeStatus.adopted:
        return AppStrings.initiativeStatusAdopted;
      case InitiativeStatus.rejected:
        return AppStrings.initiativeStatusRejected;
    }
  }

  /// Get status color
  Color get color {
    switch (this) {
      case InitiativeStatus.draft:
        return AppColors.initiativeDraft;
      case InitiativeStatus.submitted:
        return AppColors.initiativeSubmitted;
      case InitiativeStatus.review:
        return AppColors.initiativeReview;
      case InitiativeStatus.debate:
        return AppColors.initiativeDebate;
      case InitiativeStatus.voting:
        return AppColors.initiativeVoting;
      case InitiativeStatus.adopted:
        return AppColors.initiativeAdopted;
      case InitiativeStatus.rejected:
        return AppColors.initiativeRejected;
    }
  }

  /// Check if initiative is in a final state
  bool get isFinal => this == InitiativeStatus.adopted || this == InitiativeStatus.rejected;

  /// Check if initiative is editable
  bool get isEditable => this == InitiativeStatus.draft;

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static InitiativeStatus fromFirestore(String value) {
    return InitiativeStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InitiativeStatus.draft,
    );
  }
}

/// ============================================
/// ANNOUNCEMENT TYPE ENUM
/// ============================================
enum AnnouncementType {
  county,
  school;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case AnnouncementType.county:
        return AppStrings.announcementCJE;
      case AnnouncementType.school:
        return AppStrings.announcementSchool;
    }
  }

  /// Get filter display name
  String get filterName {
    switch (this) {
      case AnnouncementType.county:
        return AppStrings.filterCJE;
      case AnnouncementType.school:
        return AppStrings.filterSchool;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static AnnouncementType fromFirestore(String value) {
    return AnnouncementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnnouncementType.school,
    );
  }
}

/// ============================================
/// DOCUMENT CATEGORY ENUM
/// ============================================
enum DocumentCategory {
  statutElevului,
  regulamente,
  metodologii,
  formulare;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case DocumentCategory.statutElevului:
        return AppStrings.docCategoryStatut;
      case DocumentCategory.regulamente:
        return AppStrings.docCategoryRegulamente;
      case DocumentCategory.metodologii:
        return AppStrings.docCategoryMetodologii;
      case DocumentCategory.formulare:
        return AppStrings.docCategoryFormulare;
    }
  }

  /// Get category color
  Color get color {
    switch (this) {
      case DocumentCategory.statutElevului:
        return AppColors.docStatutElevului;
      case DocumentCategory.regulamente:
        return AppColors.docRegulamente;
      case DocumentCategory.metodologii:
        return AppColors.docMetodologii;
      case DocumentCategory.formulare:
        return AppColors.docFormulare;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static DocumentCategory fromFirestore(String value) {
    return DocumentCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentCategory.formulare,
    );
  }
}

/// ============================================
/// DOCUMENT FILE TYPE ENUM
/// ============================================
enum DocumentFileType {
  pdf,
  docx,
  png,
  jpg,
  xlsx;

  /// Get display name
  String get displayName => name.toUpperCase();

  /// Get file extension
  String get extension => '.$name';

  /// Get MIME type
  String get mimeType {
    switch (this) {
      case DocumentFileType.pdf:
        return 'application/pdf';
      case DocumentFileType.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case DocumentFileType.png:
        return 'image/png';
      case DocumentFileType.jpg:
        return 'image/jpeg';
      case DocumentFileType.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
  }

  /// Check if it's an image
  bool get isImage => this == DocumentFileType.png || this == DocumentFileType.jpg;

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static DocumentFileType fromFirestore(String value) {
    return DocumentFileType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => DocumentFileType.pdf,
    );
  }

  /// Create from file extension
  static DocumentFileType? fromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    try {
      return DocumentFileType.values.firstWhere((e) => e.name == ext);
    } catch (_) {
      return null;
    }
  }
}

/// ============================================
/// POLL TYPE ENUM
/// ============================================
enum PollType {
  school,
  county;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case PollType.school:
        return AppStrings.pollSchool;
      case PollType.county:
        return AppStrings.pollCounty;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static PollType fromFirestore(String value) {
    return PollType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PollType.school,
    );
  }
}

/// ============================================
/// POLL STATUS ENUM
/// ============================================
enum PollStatus {
  active,
  ended;

  /// Get display name in Romanian
  String get displayName {
    switch (this) {
      case PollStatus.active:
        return AppStrings.pollActive;
      case PollStatus.ended:
        return AppStrings.pollEnded;
    }
  }

  /// Get status color
  Color get color {
    switch (this) {
      case PollStatus.active:
        return AppColors.successLight;
      case PollStatus.ended:
        return AppColors.tertiaryLight;
    }
  }
}

/// ============================================
/// ATTENDANCE STATUS ENUM
/// ============================================
enum AttendanceStatus {
  present,
  absent,
  excused;

  /// Get display name
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Prezent';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.excused:
        return 'Motivat';
    }
  }

  /// Get status color
  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return AppColors.successLight;
      case AttendanceStatus.absent:
        return AppColors.errorLight;
      case AttendanceStatus.excused:
        return AppColors.warningLight;
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static AttendanceStatus fromFirestore(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

/// ============================================
/// NOTIFICATION TYPE ENUM
/// ============================================
enum NotificationType {
  meetingReminder,
  newAnnouncement,
  initiativeUpdate,
  pollReminder,
  systemAlert;

  /// Get display name
  String get displayName {
    switch (this) {
      case NotificationType.meetingReminder:
        return 'Reminder ședință';
      case NotificationType.newAnnouncement:
        return 'Comunicat nou';
      case NotificationType.initiativeUpdate:
        return 'Actualizare inițiativă';
      case NotificationType.pollReminder:
        return 'Sondaj activ';
      case NotificationType.systemAlert:
        return 'Alertă sistem';
    }
  }

  /// Convert to Firestore value
  String toFirestore() => name;

  /// Create from Firestore value
  static NotificationType fromFirestore(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.systemAlert,
    );
  }
}
