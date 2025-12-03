import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Meeting model representing council meetings
class MeetingModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final MeetingType type;
  final DateTime dateTime;
  final int durationMinutes;
  final String? location; // Physical location or online link
  final bool isOnline;
  final String? onlineLink; // Zoom/Meet link
  final String? schoolId; // Only for school meetings
  final String? schoolName;
  final DepartmentType? department; // Only for department meetings
  final String createdById;
  final String createdByName;
  final List<String> agendaItems;
  final List<String> attendeeIds; // Invited users
  final String? minutesDocumentUrl; // Meeting minutes PDF
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetingModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.dateTime,
    this.durationMinutes = 60,
    this.location,
    this.isOnline = false,
    this.onlineLink,
    this.schoolId,
    this.schoolName,
    this.department,
    required this.createdById,
    required this.createdByName,
    this.agendaItems = const [],
    this.attendeeIds = const [],
    this.minutesDocumentUrl,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty meeting
  factory MeetingModel.empty() {
    return MeetingModel(
      id: '',
      title: '',
      type: MeetingType.school,
      dateTime: DateTime.now(),
      createdById: '',
      createdByName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Check if meeting is upcoming
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  /// Check if meeting is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Get end time
  DateTime get endDateTime => dateTime.add(Duration(minutes: durationMinutes));

  /// Check if meeting is happening now
  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(dateTime) && now.isBefore(endDateTime);
  }

  /// Create from Firestore document
  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      type: MeetingType.fromFirestore(data['type'] as String? ?? 'school'),
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] as int? ?? 60,
      location: data['location'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      onlineLink: data['onlineLink'] as String?,
      schoolId: data['schoolId'] as String?,
      schoolName: data['schoolName'] as String?,
      department: data['department'] != null
          ? DepartmentType.fromFirestore(data['department'] as String)
          : null,
      createdById: data['createdById'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      agendaItems: List<String>.from(data['agendaItems'] ?? []),
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      minutesDocumentUrl: data['minutesDocumentUrl'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.toFirestore(),
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'location': location,
      'isOnline': isOnline,
      'onlineLink': onlineLink,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'department': department?.toFirestore(),
      'createdById': createdById,
      'createdByName': createdByName,
      'agendaItems': agendaItems,
      'attendeeIds': attendeeIds,
      'minutesDocumentUrl': minutesDocumentUrl,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    MeetingType? type,
    DateTime? dateTime,
    int? durationMinutes,
    String? location,
    bool? isOnline,
    String? onlineLink,
    String? schoolId,
    String? schoolName,
    DepartmentType? department,
    String? createdById,
    String? createdByName,
    List<String>? agendaItems,
    List<String>? attendeeIds,
    String? minutesDocumentUrl,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      onlineLink: onlineLink ?? this.onlineLink,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      department: department ?? this.department,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      agendaItems: agendaItems ?? this.agendaItems,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      minutesDocumentUrl: minutesDocumentUrl ?? this.minutesDocumentUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        dateTime,
        durationMinutes,
        location,
        isOnline,
        onlineLink,
        schoolId,
        schoolName,
        department,
        createdById,
        createdByName,
        agendaItems,
        attendeeIds,
        minutesDocumentUrl,
        isCompleted,
        createdAt,
        updatedAt,
      ];
}

/// Meeting attendance record
class MeetingAttendance extends Equatable {
  final String id;
  final String meetingId;
  final String userId;
  final String userName;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final String? notes;

  const MeetingAttendance({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.userName,
    required this.status,
    this.checkInTime,
    this.notes,
  });

  factory MeetingAttendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingAttendance(
      id: doc.id,
      meetingId: data['meetingId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      status: AttendanceStatus.fromFirestore(data['status'] as String? ?? 'absent'),
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'userId': userId,
      'userName': userName,
      'status': status.toFirestore(),
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, meetingId, userId, userName, status, checkInTime, notes];
}
