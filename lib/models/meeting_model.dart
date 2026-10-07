import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Meeting model representing council meetings
class MeetingModel extends Equatable {
  final String id;
  final String title;
  final String? description;

  // Translated content (stored in Firestore)
  final Map<String, String>? titleTranslations; // {'en': '...', 'ro': '...'}
  final Map<String, String>? descriptionTranslations;

  final MeetingType type;
  final DateTime dateTime;
  final int durationMinutes;
  final String? location; // Physical location or online link
  final bool isOnline;
  final String? onlineLink; // Zoom/Meet link
  final String? countyId; // County this meeting belongs to
  final MeetingStatus status; // scheduled sau cancelled
  /// Cate inregistrari de prezenta are sedinta.
  ///
  /// Intretinut EXCLUSIV de trigger-ul onAttendanceWritten din Cloud
  /// Functions, prin FieldValue.increment, ca sa fie atomic. Clientul nu il
  /// scrie niciodata. Regula de stergere pe meetings il citeste ca sa refuze
  /// stergerea unei sedinte cu prezenta inregistrata -- garda din
  /// MeetingController nu poate fi impusa server-side, fiindca regulile nu pot
  /// interoga meeting_attendance.
  final int attendanceCount;
  final String? schoolId; // Only for school meetings
  final String? schoolName;
  final DepartmentType? department; // Only for department meetings
  final String createdById;
  final String createdByName;
  final List<String> agendaItems;
  final List<String> attendeeIds; // Invited users
  final List<MeetingDocument> documents; // Meeting documents
  final String? minutesDocumentUrl; // Meeting minutes PDF (legacy)
  final bool isCompleted;
  final UserRole? minVisibilityRole; // Minimum role required to view (null = visible to all)
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetingModel({
    required this.id,
    required this.title,
    this.description,
    this.titleTranslations,
    this.descriptionTranslations,
    required this.type,
    required this.dateTime,
    this.durationMinutes = 60,
    this.location,
    this.isOnline = false,
    this.onlineLink,
    this.countyId,
    this.status = MeetingStatus.scheduled,
    this.attendanceCount = 0,
    this.schoolId,
    this.schoolName,
    this.department,
    required this.createdById,
    required this.createdByName,
    this.agendaItems = const [],
    this.attendeeIds = const [],
    this.documents = const [],
    this.minutesDocumentUrl,
    this.isCompleted = false,
    this.minVisibilityRole,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get title for specific language (with fallback)
  String getTitle(String languageCode) {
    if (titleTranslations != null && titleTranslations!.containsKey(languageCode)) {
      return titleTranslations![languageCode]!;
    }
    return title;
  }

  /// Get description for specific language (with fallback)
  String? getDescription(String languageCode) {
    if (descriptionTranslations != null && descriptionTranslations!.containsKey(languageCode)) {
      return descriptionTranslations![languageCode];
    }
    return description;
  }

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
      titleTranslations: data['titleTranslations'] != null
          ? Map<String, String>.from(data['titleTranslations'])
          : null,
      descriptionTranslations: data['descriptionTranslations'] != null
          ? Map<String, String>.from(data['descriptionTranslations'])
          : null,
      type: MeetingType.fromFirestore(data['type'] as String? ?? 'school'),
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] as int? ?? 60,
      location: data['location'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      onlineLink: data['onlineLink'] as String?,
      countyId: data['countyId'] as String?,
      status: MeetingStatus.fromFirestore(
          data['status'] as String? ?? 'scheduled'),
      attendanceCount: (data['attendanceCount'] as num?)?.toInt() ?? 0,
      schoolId: data['schoolId'] as String?,
      schoolName: data['schoolName'] as String?,
      department: data['department'] != null
          ? DepartmentType.fromFirestore(data['department'] as String)
          : null,
      createdById: data['createdById'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      agendaItems: List<String>.from(data['agendaItems'] ?? []),
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      documents: (data['documents'] as List<dynamic>?)
          ?.map((d) => MeetingDocument.fromMap(d as Map<String, dynamic>))
          .toList() ?? [],
      minutesDocumentUrl: data['minutesDocumentUrl'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      minVisibilityRole: data['minVisibilityRole'] != null
          ? UserRole.fromFirestore(data['minVisibilityRole'] as String)
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'titleTranslations': titleTranslations,
      'descriptionTranslations': descriptionTranslations,
      'type': type.toFirestore(),
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'location': location,
      'isOnline': isOnline,
      'onlineLink': onlineLink,
      'countyId': countyId,
      'status': status.toFirestore(),
      // attendanceCount NU se scrie de aici: e intretinut doar de trigger-ul din
      // Cloud Functions, prin FieldValue.increment. Daca l-am include, orice
      // salvare a sedintei din aplicatie ar suprascrie contorul cu o valoare
      // invechita, iar garda de stergere ar deveni nesigura.
      'schoolId': schoolId,
      'schoolName': schoolName,
      'department': department?.toFirestore(),
      'createdById': createdById,
      'createdByName': createdByName,
      'agendaItems': agendaItems,
      'attendeeIds': attendeeIds,
      'documents': documents.map((d) => d.toMap()).toList(),
      'minutesDocumentUrl': minutesDocumentUrl,
      'isCompleted': isCompleted,
      'minVisibilityRole': minVisibilityRole?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    Map<String, String>? titleTranslations,
    Map<String, String>? descriptionTranslations,
    MeetingType? type,
    DateTime? dateTime,
    int? durationMinutes,
    String? location,
    bool? isOnline,
    String? onlineLink,
    String? countyId,
    MeetingStatus? status,
    int? attendanceCount,
    String? schoolId,
    String? schoolName,
    DepartmentType? department,
    String? createdById,
    String? createdByName,
    List<String>? agendaItems,
    List<String>? attendeeIds,
    List<MeetingDocument>? documents,
    String? minutesDocumentUrl,
    bool? isCompleted,
    UserRole? minVisibilityRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      titleTranslations: titleTranslations ?? this.titleTranslations,
      descriptionTranslations: descriptionTranslations ?? this.descriptionTranslations,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      onlineLink: onlineLink ?? this.onlineLink,
      countyId: countyId ?? this.countyId,
      status: status ?? this.status,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      department: department ?? this.department,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      agendaItems: agendaItems ?? this.agendaItems,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      documents: documents ?? this.documents,
      minutesDocumentUrl: minutesDocumentUrl ?? this.minutesDocumentUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      minVisibilityRole: minVisibilityRole ?? this.minVisibilityRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        titleTranslations,
        descriptionTranslations,
        type,
        dateTime,
        durationMinutes,
        location,
        isOnline,
        onlineLink,
        countyId,
        status,
        attendanceCount,
        schoolId,
        schoolName,
        department,
        createdById,
        createdByName,
        agendaItems,
        attendeeIds,
        documents,
        minutesDocumentUrl,
        isCompleted,
        minVisibilityRole,
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

/// Meeting document model
class MeetingDocument extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? fileType; // pdf, docx, etc.
  final DateTime uploadedAt;

  const MeetingDocument({
    required this.id,
    required this.name,
    required this.url,
    this.fileType,
    required this.uploadedAt,
  });

  factory MeetingDocument.fromMap(Map<String, dynamic> data) {
    return MeetingDocument(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
      fileType: data['fileType'] as String?,
      uploadedAt: data['uploadedAt'] is Timestamp
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'fileType': fileType,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  @override
  List<Object?> get props => [id, name, url, fileType, uploadedAt];
}
