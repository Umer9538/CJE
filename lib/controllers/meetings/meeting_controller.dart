import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/repositories.dart';
import '../../core/constants/enums.dart';
import '../../core/services/translation_service.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_controller.dart';

/// Meeting repository provider
final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository();
});

/// Meetings list provider
final meetingsProvider = FutureProvider.family<List<MeetingModel>, MeetingFilter>((ref, filter) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return <MeetingModel>[];
  }

  final repository = ref.read(meetingRepositoryProvider);

  try {
    return await repository.getMeetings(
      type: filter.type,
      schoolId: filter.schoolId,
      department: filter.department,
      upcomingOnly: filter.upcomingOnly,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <MeetingModel>[],
    );
  } catch (e) {
    return <MeetingModel>[];
  }
});

/// Meetings stream provider
final meetingsStreamProvider = StreamProvider.family<List<MeetingModel>, MeetingFilter>((ref, filter) {
  final repository = ref.watch(meetingRepositoryProvider);

  return repository.getMeetingsStream(
    type: filter.type,
    schoolId: filter.schoolId,
    upcomingOnly: filter.upcomingOnly,
    limit: filter.limit,
  );
});

/// Single meeting provider
final meetingProvider = FutureProvider.family<MeetingModel?, String>((ref, id) async {
  final repository = ref.watch(meetingRepositoryProvider);
  return repository.getMeetingById(id);
});

/// Upcoming meetings for home screen
final upcomingMeetingsProvider = FutureProvider<List<MeetingModel>>((ref) async {
  final user = ref.read(currentUserProvider); // Use read instead of watch to avoid rebuilds
  if (user == null) {
    return <MeetingModel>[];
  }

  final repository = ref.read(meetingRepositoryProvider);
  try {
    return await repository.getUpcomingMeetings(
      schoolId: user.schoolId,
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <MeetingModel>[],
    );
  } catch (e) {
    return <MeetingModel>[];
  }
});

/// Provider for department meetings (filtered by current user's department)
final departmentMeetingsProvider = FutureProvider<List<MeetingModel>>((ref) async {
  final user = ref.read(currentUserProvider);
  debugPrint('departmentMeetingsProvider: user=${user?.fullName}, role=${user?.role}, department=${user?.department}');

  if (user == null) {
    debugPrint('departmentMeetingsProvider: user is null, returning empty list');
    return <MeetingModel>[];
  }

  final repository = ref.read(meetingRepositoryProvider);
  try {
    // If user has a specific department assigned, filter by it
    // Otherwise, show all department-type meetings for users with department role
    final meetings = await repository.getMeetings(
      type: MeetingType.department,
      department: user.department, // null means show all department meetings
      limit: 20,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <MeetingModel>[],
    );
    debugPrint('departmentMeetingsProvider: found ${meetings.length} meetings');
    return meetings;
  } catch (e) {
    debugPrint('departmentMeetingsProvider: error $e');
    return <MeetingModel>[];
  }
});

/// Next meeting provider
final nextMeetingProvider = FutureProvider<MeetingModel?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return null;
  }

  final repository = ref.read(meetingRepositoryProvider);
  return repository.getNextMeeting(schoolId: user.schoolId);
});

/// Meeting attendance provider
final meetingAttendanceProvider = FutureProvider.family<List<MeetingAttendance>, String>((ref, meetingId) async {
  final repository = ref.watch(meetingRepositoryProvider);
  return repository.getMeetingAttendance(meetingId);
});

/// Provider to get users by their IDs (for showing participant names)
final usersByIdsProvider = FutureProvider.family<List<UserModel>, List<String>>((ref, userIds) async {
  if (userIds.isEmpty) return [];
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUsersByIds(userIds);
});

/// Provider for searchable users (for adding participants)
final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(userRepositoryProvider);
  return repository.searchUsers(query);
});

/// Filter model for meetings
class MeetingFilter {
  final MeetingType? type;
  final String? schoolId;
  final DepartmentType? department;
  final bool upcomingOnly;
  final int limit;

  const MeetingFilter({
    this.type,
    this.schoolId,
    this.department,
    this.upcomingOnly = false,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          schoolId == other.schoolId &&
          department == other.department &&
          upcomingOnly == other.upcomingOnly &&
          limit == other.limit;

  @override
  int get hashCode =>
      type.hashCode ^ schoolId.hashCode ^ department.hashCode ^ upcomingOnly.hashCode ^ limit.hashCode;
}

/// Meeting controller for CRUD operations
class MeetingController extends StateNotifier<AsyncValue<void>> {
  final MeetingRepository _repository;
  final Ref _ref;

  MeetingController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Check if user can create/edit a specific meeting type
  bool _canManageMeetingType(UserRole role, MeetingType type) {
    // County AG and BEX meetings can only be managed by BEX and Superadmin
    if (type == MeetingType.countyAG || type == MeetingType.bex) {
      return role == UserRole.bex || role == UserRole.superadmin;
    }
    // School meetings can be managed by schoolRep, bex, superadmin (NOT department)
    if (type == MeetingType.school) {
      return role == UserRole.schoolRep ||
             role == UserRole.bex ||
             role == UserRole.superadmin;
    }
    // Department meetings can be managed by department, bex, superadmin
    if (type == MeetingType.department) {
      return role == UserRole.department ||
             role == UserRole.bex ||
             role == UserRole.superadmin;
    }
    return false;
  }

  /// Create new meeting
  /// - SchoolRep can create school and department meetings only
  /// - BEX and Superadmin can create any meeting type
  Future<String?> createMeeting({
    required String title,
    required MeetingType type,
    required DateTime dateTime,
    String? description,
    int durationMinutes = 60,
    String? location,
    bool isOnline = false,
    String? onlineLink,
    String? schoolId,
    String? schoolName,
    DepartmentType? department,
    List<String>? agendaItems,
    List<String>? attendeeIds,
    List<MeetingDocument>? documents,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    debugPrint('createMeeting: user=${user?.fullName}, role=${user?.role}, type=$type');

    if (user == null) {
      debugPrint('createMeeting: User is null');
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    // Permission check
    if (!_canManageMeetingType(user.role, type)) {
      debugPrint('createMeeting: Permission denied for role ${user.role} to create $type meetings');
      state = AsyncValue.error('Permission denied: Cannot create ${type.displayName} meetings', StackTrace.current);
      return null;
    }

    debugPrint('createMeeting: Permission check passed');

    // Use provided school/department or fall back to user's values
    final meetingSchoolId = type == MeetingType.school
        ? (schoolId ?? user.schoolId)
        : null;
    final meetingSchoolName = type == MeetingType.school
        ? (schoolName ?? user.schoolName)
        : null;
    final meetingDepartment = type == MeetingType.department
        ? (department ?? user.department)
        : null;

    // Translate content to both languages
    Map<String, String>? titleTranslations;
    Map<String, String>? descriptionTranslations;

    try {
      final translatedTitle = await TranslatableContent.fromText(title);
      titleTranslations = {'en': translatedTitle.en, 'ro': translatedTitle.ro};

      if (description != null && description.isNotEmpty) {
        final translatedDescription = await TranslatableContent.fromText(description);
        descriptionTranslations = {'en': translatedDescription.en, 'ro': translatedDescription.ro};
      }

      debugPrint('MeetingController: Content translated successfully');
    } catch (e) {
      debugPrint('MeetingController: Translation failed - $e');
      // Continue without translations if translation fails
    }

    final meeting = MeetingModel(
      id: '',
      title: title,
      description: description,
      titleTranslations: titleTranslations,
      descriptionTranslations: descriptionTranslations,
      type: type,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      location: location,
      isOnline: isOnline,
      onlineLink: onlineLink,
      schoolId: meetingSchoolId,
      schoolName: meetingSchoolName,
      department: meetingDepartment,
      createdById: user.id,
      createdByName: user.fullName,
      agendaItems: agendaItems ?? [],
      attendeeIds: attendeeIds ?? [],
      documents: documents ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createMeeting(meeting);

    if (id != null) {
      state = const AsyncValue.data(null);
      _ref.invalidate(meetingsProvider);
      _ref.invalidate(upcomingMeetingsProvider);
      _ref.invalidate(nextMeetingProvider);
      // Invalidate department meetings if it's a department meeting
      if (type == MeetingType.department) {
        _ref.invalidate(departmentMeetingsProvider);
      }

      // Send automatic notification for new meeting
      await _sendMeetingNotification(
        title: title,
        dateTime: dateTime,
        type: type,
        schoolId: meetingSchoolId,
        location: isOnline ? 'Online' : location,
        meetingId: id,
      );
    } else {
      state = AsyncValue.error('Failed to create meeting', StackTrace.current);
    }

    return id;
  }

  /// Update meeting
  /// - SchoolRep can only update school and department meetings
  /// - Cannot edit county AG or BEX meetings
  Future<bool> updateMeeting(MeetingModel meeting) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    // Permission check - cannot edit county AG or BEX meetings unless BEX/Superadmin
    if (!_canManageMeetingType(user.role, meeting.type)) {
      state = AsyncValue.error('Permission denied: Cannot edit ${meeting.type.displayName} meetings', StackTrace.current);
      return false;
    }

    final success = await _repository.updateMeeting(meeting);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(meetingsProvider);
      _ref.invalidate(meetingProvider(meeting.id));
      _ref.invalidate(upcomingMeetingsProvider);
      // Invalidate department meetings if it's a department meeting
      if (meeting.type == MeetingType.department) {
        _ref.invalidate(departmentMeetingsProvider);
      }
    } else {
      state = AsyncValue.error('Failed to update meeting', StackTrace.current);
    }

    return success;
  }

  /// Delete meeting
  Future<bool> deleteMeeting(String id) async {
    state = const AsyncValue.loading();

    final success = await _repository.deleteMeeting(id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(meetingsProvider);
      _ref.invalidate(upcomingMeetingsProvider);
      _ref.invalidate(nextMeetingProvider);
      _ref.invalidate(departmentMeetingsProvider);
    } else {
      state = AsyncValue.error('Failed to delete meeting', StackTrace.current);
    }

    return success;
  }

  /// Mark meeting as completed
  Future<bool> completeMeeting(String id) async {
    final success = await _repository.completeMeeting(id);
    if (success) {
      _ref.invalidate(meetingsProvider);
      _ref.invalidate(meetingProvider(id));
    }
    return success;
  }

  /// Record attendance
  Future<bool> recordAttendance({
    required String meetingId,
    required String oderId,
    required String userName,
    required AttendanceStatus status,
  }) async {
    final attendance = MeetingAttendance(
      id: '${meetingId}_$oderId',
      meetingId: meetingId,
      userId: oderId,
      userName: userName,
      status: status,
      checkInTime: status == AttendanceStatus.present ? DateTime.now() : null,
    );

    final success = await _repository.recordAttendance(attendance);
    if (success) {
      _ref.invalidate(meetingAttendanceProvider(meetingId));
    }
    return success;
  }

  /// Update attendance status
  Future<bool> updateAttendance(String attendanceId, AttendanceStatus status, String meetingId) async {
    final success = await _repository.updateAttendanceStatus(attendanceId, status);
    if (success) {
      _ref.invalidate(meetingAttendanceProvider(meetingId));
    }
    return success;
  }

  /// Add participant to meeting (adds to attendeeIds and creates attendance record)
  Future<bool> addParticipant({
    required String meetingId,
    required String oderId,
    required String userName,
    AttendanceStatus status = AttendanceStatus.present,
  }) async {
    try {
      // First get the current meeting
      final meeting = await _repository.getMeetingById(meetingId);
      if (meeting == null) return false;

      // Add user to attendeeIds if not already there
      if (!meeting.attendeeIds.contains(oderId)) {
        final updatedAttendeeIds = [...meeting.attendeeIds, oderId];
        final updatedMeeting = meeting.copyWith(
          attendeeIds: updatedAttendeeIds,
          updatedAt: DateTime.now(),
        );
        await _repository.updateMeeting(updatedMeeting);
      }

      // Create attendance record
      final success = await recordAttendance(
        meetingId: meetingId,
        oderId: oderId,
        userName: userName,
        status: status,
      );

      if (success) {
        _ref.invalidate(meetingProvider(meetingId));
        _ref.invalidate(usersByIdsProvider(meeting.attendeeIds));
      }

      return success;
    } catch (e) {
      debugPrint('Error adding participant: $e');
      return false;
    }
  }

  /// Remove participant from meeting
  Future<bool> removeParticipant({
    required String meetingId,
    required String oderId,
  }) async {
    try {
      final meeting = await _repository.getMeetingById(meetingId);
      if (meeting == null) return false;

      // Remove from attendeeIds
      final updatedAttendeeIds = meeting.attendeeIds.where((id) => id != oderId).toList();
      final updatedMeeting = meeting.copyWith(
        attendeeIds: updatedAttendeeIds,
        updatedAt: DateTime.now(),
      );
      await _repository.updateMeeting(updatedMeeting);

      // Also delete attendance record if exists
      final attendanceId = '${meetingId}_$oderId';
      try {
        await _repository.deleteAttendance(attendanceId);
      } catch (_) {
        // Attendance might not exist, that's ok
      }

      _ref.invalidate(meetingProvider(meetingId));
      _ref.invalidate(meetingAttendanceProvider(meetingId));
      _ref.invalidate(usersByIdsProvider(updatedAttendeeIds));

      return true;
    } catch (e) {
      debugPrint('Error removing participant: $e');
      return false;
    }
  }

  /// Send notification for a new meeting
  Future<void> _sendMeetingNotification({
    required String title,
    required DateTime dateTime,
    required MeetingType type,
    String? schoolId,
    String? location,
    required String meetingId,
  }) async {
    try {
      final notificationRepo = _ref.read(notificationRepositoryProvider);
      final user = _ref.read(currentUserProvider);

      // Format date and time for notification
      final dateFormat = DateFormat('MMM d, yyyy');
      final timeFormat = DateFormat('h:mm a');
      final dateStr = dateFormat.format(dateTime);
      final timeStr = timeFormat.format(dateTime);

      final notificationBody = 'Scheduled for $dateStr at $timeStr${location != null ? ' - $location' : ''}';

      await notificationRepo.sendCountyWideNotification(
        title: 'New ${type.displayName} Meeting: $title',
        body: notificationBody,
        type: NotificationType.meetingReminder,
        schoolId: type == MeetingType.school ? schoolId : null,
        senderId: user?.id ?? '',
        senderName: user?.fullName ?? 'System',
        additionalData: {'meetingId': meetingId},
      );

      debugPrint('Sent notification for meeting: $title');
    } catch (e) {
      debugPrint('Error sending meeting notification: $e');
    }
  }
}

/// Meeting controller provider
final meetingControllerProvider =
    StateNotifierProvider<MeetingController, AsyncValue<void>>((ref) {
  return MeetingController(
    ref.watch(meetingRepositoryProvider),
    ref,
  );
});

/// Check if current user can create meetings
/// - BEX and Superadmin can create any meeting type
/// - SchoolRep can create school meetings
/// - Department can create department meetings
final canCreateMeetingsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can create county AG meetings (BEX only)
final canCreateCountyMeetingsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Check if current user can manage attendance (BEX only)
final canManageAttendanceProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});
