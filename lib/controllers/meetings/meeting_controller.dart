import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/repositories.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Meeting repository provider
final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository();
});

/// Meetings list provider
final meetingsProvider = FutureProvider.family<List<MeetingModel>, MeetingFilter>((ref, filter) async {
  final repository = ref.watch(meetingRepositoryProvider);

  return repository.getMeetings(
    type: filter.type,
    schoolId: filter.schoolId,
    department: filter.department,
    upcomingOnly: filter.upcomingOnly,
    limit: filter.limit,
  );
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
  final repository = ref.watch(meetingRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  try {
    return await repository.getUpcomingMeetings(
      schoolId: user?.schoolId,
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <MeetingModel>[],
    );
  } catch (e) {
    return <MeetingModel>[];
  }
});

/// Next meeting provider
final nextMeetingProvider = FutureProvider<MeetingModel?>((ref) async {
  final repository = ref.watch(meetingRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repository.getNextMeeting(schoolId: user?.schoolId);
});

/// Meeting attendance provider
final meetingAttendanceProvider = FutureProvider.family<List<MeetingAttendance>, String>((ref, meetingId) async {
  final repository = ref.watch(meetingRepositoryProvider);
  return repository.getMeetingAttendance(meetingId);
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

  /// Create new meeting
  Future<String?> createMeeting({
    required String title,
    required MeetingType type,
    required DateTime dateTime,
    String? description,
    int durationMinutes = 60,
    String? location,
    bool isOnline = false,
    String? onlineLink,
    List<String>? agendaItems,
    List<String>? attendeeIds,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    final meeting = MeetingModel(
      id: '',
      title: title,
      description: description,
      type: type,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      location: location,
      isOnline: isOnline,
      onlineLink: onlineLink,
      schoolId: type == MeetingType.school ? user.schoolId : null,
      schoolName: type == MeetingType.school ? user.schoolName : null,
      department: type == MeetingType.department ? user.department : null,
      createdById: user.id,
      createdByName: user.fullName,
      agendaItems: agendaItems ?? [],
      attendeeIds: attendeeIds ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createMeeting(meeting);

    if (id != null) {
      state = const AsyncValue.data(null);
      _ref.invalidate(meetingsProvider);
      _ref.invalidate(upcomingMeetingsProvider);
      _ref.invalidate(nextMeetingProvider);
    } else {
      state = AsyncValue.error('Failed to create meeting', StackTrace.current);
    }

    return id;
  }

  /// Update meeting
  Future<bool> updateMeeting(MeetingModel meeting) async {
    state = const AsyncValue.loading();

    final success = await _repository.updateMeeting(meeting);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(meetingsProvider);
      _ref.invalidate(meetingProvider(meeting.id));
      _ref.invalidate(upcomingMeetingsProvider);
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
}

/// Meeting controller provider
final meetingControllerProvider =
    StateNotifierProvider<MeetingController, AsyncValue<void>>((ref) {
  return MeetingController(
    ref.watch(meetingRepositoryProvider),
    ref,
  );
});
