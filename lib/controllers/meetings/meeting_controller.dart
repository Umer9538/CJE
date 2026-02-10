import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/repositories.dart';
import '../../core/constants/enums.dart';
import '../../core/services/translation_service.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';
import '../admin/admin_controller.dart';
import '../notifications/notification_controller.dart';

/// Meeting repository provider
final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository();
});

/// Helper function to check if user can view content based on visibility role
bool _canViewMeeting(UserRole? userRole, UserRole? minVisibilityRole) {
  // If no visibility restriction, everyone can view
  if (minVisibilityRole == null) return true;
  // If user is not logged in, they can't view restricted content
  if (userRole == null) return false;
  // BEX and Superadmin always bypass visibility restrictions
  if (userRole == UserRole.bex || userRole == UserRole.superadmin) return true;
  // Check if user's hierarchy level meets the minimum required
  return userRole.hierarchyLevel >= minVisibilityRole.hierarchyLevel;
}

/// Meetings list provider (FutureProvider for one-time fetch)
final meetingsProvider = FutureProvider.family<List<MeetingModel>, MeetingFilter>((ref, filter) async {
  // Use ref.watch for reactive dependencies so provider rebuilds when user changes
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return <MeetingModel>[];
  }

  final repository = ref.read(meetingRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For BEX/Superadmin, don't filter by school - they see ALL meetings
  // For regular users, ALWAYS use their schoolId for filtering (not filter.schoolId)
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  try {
    final meetings = await repository.getMeetings(
      type: filter.type,
      schoolId: effectiveSchoolId,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
      department: filter.department,
      upcomingOnly: filter.upcomingOnly,
      pastOnly: filter.pastOnly,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <MeetingModel>[],
    );
    // Filter by visibility role
    return meetings.where((m) => _canViewMeeting(user.role, m.minVisibilityRole)).toList();
  } catch (e) {
    return <MeetingModel>[];
  }
});

/// Meetings stream provider (for real-time updates)
final meetingsStreamProvider = StreamProvider.family<List<MeetingModel>, MeetingFilter>((ref, filter) {
  final repository = ref.watch(meetingRepositoryProvider);
  // Use ref.watch for reactive dependencies
  final user = ref.watch(currentUserProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For BEX/Superadmin, don't filter by school - they see ALL meetings
  // For regular users, ALWAYS use their schoolId for filtering (not filter.schoolId)
  final shouldFilterBySchool = user?.role != UserRole.superadmin && user?.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user?.schoolId : null;

  return repository.getMeetingsStream(
    type: filter.type,
    schoolId: effectiveSchoolId,
    countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
    upcomingOnly: filter.upcomingOnly,
    pastOnly: filter.pastOnly,
    limit: filter.limit,
  ).map((meetings) {
    // Filter by visibility role
    return meetings.where((m) => _canViewMeeting(user?.role, m.minVisibilityRole)).toList();
  });
});

/// Single meeting provider
final meetingProvider = FutureProvider.family<MeetingModel?, String>((ref, id) async {
  final repository = ref.watch(meetingRepositoryProvider);
  return repository.getMeetingById(id);
});

/// Upcoming meetings for home screen (FutureProvider - one-time fetch)
final upcomingMeetingsProvider = FutureProvider<List<MeetingModel>>((ref) async {
  // Use ref.watch for reactive dependencies so provider rebuilds when user changes
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('upcomingMeetingsProvider: user is null, returning empty list');
    return <MeetingModel>[];
  }

  final repository = ref.read(meetingRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For BEX/Superadmin, don't filter by school - they see ALL upcoming meetings
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  debugPrint('upcomingMeetingsProvider: user=${user.fullName}, role=${user.role}, county=$effectiveCounty, schoolId=$effectiveSchoolId');

  try {
    final meetings = await repository.getUpcomingMeetings(
      schoolId: effectiveSchoolId,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('upcomingMeetingsProvider: timeout');
        return <MeetingModel>[];
      },
    );
    // Filter by visibility role
    final filtered = meetings.where((m) => _canViewMeeting(user.role, m.minVisibilityRole)).toList();
    debugPrint('upcomingMeetingsProvider: returned ${filtered.length} meetings (after visibility filter)');
    return filtered;
  } catch (e) {
    debugPrint('upcomingMeetingsProvider: error $e');
    return <MeetingModel>[];
  }
});

/// Upcoming meetings stream for home screen (StreamProvider - real-time updates)
final upcomingMeetingsStreamProvider = StreamProvider<List<MeetingModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<MeetingModel>[]);
  }

  final repository = ref.watch(meetingRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For BEX/Superadmin, don't filter by school - they see ALL upcoming meetings
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  return repository.getUpcomingMeetingsStream(
    schoolId: effectiveSchoolId,
    countyId: effectiveCounty,
    limit: 5,
  ).map((meetings) {
    // Filter by visibility role
    return meetings.where((m) => _canViewMeeting(user.role, m.minVisibilityRole)).toList();
  });
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
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  try {
    // If user has a specific department assigned, filter by it
    // Otherwise, show all department-type meetings for users with department role
    final meetings = await repository.getMeetings(
      type: MeetingType.department,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
      department: user.department, // null means show all department meetings
      limit: 20,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <MeetingModel>[],
    );
    // Filter by visibility role
    final filtered = meetings.where((m) => _canViewMeeting(user.role, m.minVisibilityRole)).toList();
    debugPrint('departmentMeetingsProvider: found ${filtered.length} meetings (after visibility filter)');
    return filtered;
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
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For BEX/Superadmin, don't filter by school - they see ALL meetings
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  return repository.getNextMeeting(schoolId: effectiveSchoolId, countyId: effectiveCounty);
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

/// Provider for searchable users (for adding participants) - filters by current user's county
final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(userRepositoryProvider);
  final currentUser = ref.read(currentUserProvider);
  return repository.searchUsers(query, countyId: currentUser?.city);
});

/// Provider to get all active users from the current user's county
final countyUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  final currentUser = ref.read(currentUserProvider);
  final countyId = currentUser?.city;
  if (countyId == null || countyId.isEmpty) {
    return [];
  }
  return repository.getUsersByCounty(countyId, limit: 50);
});

/// Filter model for meetings
class MeetingFilter {
  final MeetingType? type;
  final String? schoolId;
  final DepartmentType? department;
  final bool upcomingOnly;
  final bool pastOnly;
  final int limit;

  const MeetingFilter({
    this.type,
    this.schoolId,
    this.department,
    this.upcomingOnly = false,
    this.pastOnly = false,
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
          pastOnly == other.pastOnly &&
          limit == other.limit;

  @override
  int get hashCode =>
      type.hashCode ^ schoolId.hashCode ^ department.hashCode ^ upcomingOnly.hashCode ^ pastOnly.hashCode ^ limit.hashCode;
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
    // School meetings can be managed by schoolRep, department, bex, superadmin
    if (type == MeetingType.school) {
      return role == UserRole.schoolRep ||
             role == UserRole.department ||
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
  /// - minVisibilityRole: Optional minimum role required to view this meeting (null = visible to all)
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
    UserRole? minVisibilityRole,
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

    // Determine school/department for the meeting
    // School Reps can ONLY create meetings for their own school - ignore any override
    // BEX/Superadmin can specify a different school
    String? meetingSchoolId;
    String? meetingSchoolName;
    DepartmentType? meetingDepartment;

    if (type == MeetingType.school) {
      // School Reps MUST use their own school - security enforcement
      if (user.role == UserRole.schoolRep) {
        meetingSchoolId = user.schoolId;
        meetingSchoolName = user.schoolName;
      } else {
        // Department/BEX/Superadmin can specify a school or use their own
        meetingSchoolId = schoolId ?? user.schoolId;
        meetingSchoolName = schoolName ?? user.schoolName;
      }
    }

    if (type == MeetingType.department) {
      // Only department, BEX, and Superadmin can create department meetings
      // This is already checked in _canManageMeetingType, but adding extra safety
      if (user.role == UserRole.schoolRep) {
        state = AsyncValue.error('School Representatives cannot create department meetings', StackTrace.current);
        return null;
      }
      meetingDepartment = department ?? user.department;
    }

    // Translate content to both languages (with timeout to prevent hanging)
    Map<String, String>? titleTranslations;
    Map<String, String>? descriptionTranslations;

    debugPrint('MeetingController: Starting translation...');
    try {
      // Add 10 second timeout to entire translation process
      await Future<void>(() async {
        final translatedTitle = await TranslatableContent.fromText(title);
        titleTranslations = {'en': translatedTitle.en, 'ro': translatedTitle.ro};

        if (description != null && description.isNotEmpty) {
          final translatedDescription = await TranslatableContent.fromText(description);
          descriptionTranslations = {'en': translatedDescription.en, 'ro': translatedDescription.ro};
        }
      }).timeout(const Duration(seconds: 10));

      debugPrint('MeetingController: Content translated successfully');
    } catch (e) {
      debugPrint('MeetingController: Translation failed/timeout - $e, continuing without translations');
      // Continue without translations if translation fails or times out
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
      countyId: user.city, // Save the county for data partitioning (city is the county name)
      schoolId: meetingSchoolId,
      schoolName: meetingSchoolName,
      department: meetingDepartment,
      createdById: user.id,
      createdByName: user.fullName,
      agendaItems: agendaItems ?? [],
      attendeeIds: attendeeIds ?? [],
      documents: documents ?? [],
      minVisibilityRole: minVisibilityRole,
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
      // Pass minVisibilityRole to filter recipients
      await _sendMeetingNotification(
        title: title,
        dateTime: dateTime,
        type: type,
        schoolId: meetingSchoolId,
        location: isOnline ? 'Online' : location,
        meetingId: id,
        minVisibilityRole: minVisibilityRole,
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

    // Re-translate title and description so translations reflect the edited text
    Map<String, String>? titleTranslations;
    Map<String, String>? descriptionTranslations;

    try {
      await Future<void>(() async {
        final translatedTitle = await TranslatableContent.fromText(meeting.title);
        titleTranslations = {'en': translatedTitle.en, 'ro': translatedTitle.ro};

        if (meeting.description != null && meeting.description!.isNotEmpty) {
          final translatedDescription = await TranslatableContent.fromText(meeting.description!);
          descriptionTranslations = {'en': translatedDescription.en, 'ro': translatedDescription.ro};
        }
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('MeetingController: Translation failed/timeout during update - $e, continuing without translations');
    }

    final updatedMeeting = meeting.copyWith(
      titleTranslations: titleTranslations ?? {'en': meeting.title, 'ro': meeting.title},
      descriptionTranslations: descriptionTranslations ?? (meeting.description != null ? {'en': meeting.description!, 'ro': meeting.description!} : null),
    );

    final success = await _repository.updateMeeting(updatedMeeting);

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
  /// - minVisibilityRole: Only notify users with this role or higher
  Future<void> _sendMeetingNotification({
    required String title,
    required DateTime dateTime,
    required MeetingType type,
    String? schoolId,
    String? location,
    required String meetingId,
    UserRole? minVisibilityRole,
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

      // Determine effective minVisibilityRole based on meeting type
      // BEx/CountyAG meetings should only notify BEx/Superadmin
      // Department meetings should only notify Department and above
      UserRole? effectiveMinRole = minVisibilityRole;
      if (type == MeetingType.bex || type == MeetingType.countyAG) {
        effectiveMinRole = _higherRole(minVisibilityRole, UserRole.bex);
      } else if (type == MeetingType.department) {
        effectiveMinRole = _higherRole(minVisibilityRole, UserRole.department);
      }

      debugPrint('MeetingNotification: Sending with effectiveMinRole=$effectiveMinRole, schoolId=$schoolId, type=$type, countyId=${user?.city}');

      await notificationRepo.sendCountyWideNotification(
        title: 'New ${type.displayName} Meeting: $title',
        body: notificationBody,
        type: NotificationType.meetingReminder,
        countyId: user?.city,
        schoolId: type == MeetingType.school ? schoolId : null,
        minVisibilityRole: effectiveMinRole,
        senderId: user?.id ?? '',
        senderName: user?.fullName ?? 'System',
        additionalData: {'meetingId': meetingId},
      );

      debugPrint('Sent notification for meeting: $title');
    } catch (e) {
      debugPrint('Error sending meeting notification: $e');
    }
  }

  /// Returns the higher of two roles (by hierarchy level), or the non-null one
  UserRole _higherRole(UserRole? a, UserRole b) {
    if (a == null) return b;
    return a.hierarchyLevel >= b.hierarchyLevel ? a : b;
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
