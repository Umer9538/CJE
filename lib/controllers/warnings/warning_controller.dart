import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/repositories/warning_repository.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Warning repository provider
final warningRepositoryProvider = Provider<WarningRepository>((ref) {
  return WarningRepository();
});

/// Filter for warnings
class WarningFilter {
  final String? countyId;
  final String? userId;
  final bool? isActive;
  final int limit;

  const WarningFilter({
    this.countyId,
    this.userId,
    this.isActive,
    this.limit = 50,
  });
}

/// Filter for absences
class AbsenceFilter {
  final String? countyId;
  final String? userId;
  final String? meetingId;
  final int limit;

  const AbsenceFilter({
    this.countyId,
    this.userId,
    this.meetingId,
    this.limit = 50,
  });
}

/// Warnings provider
final warningsProvider = FutureProvider.family<List<WarningModel>, WarningFilter>((ref, filter) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getWarnings(
    countyId: filter.countyId,
    userId: filter.userId,
    isActive: filter.isActive,
    limit: filter.limit,
  );
});

/// User warnings provider
final userWarningsProvider = FutureProvider.family<List<WarningModel>, String>((ref, userId) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getUserWarnings(userId);
});

/// Absences provider
final absencesProvider = FutureProvider.family<List<AbsenceModel>, AbsenceFilter>((ref, filter) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getAbsences(
    countyId: filter.countyId,
    userId: filter.userId,
    meetingId: filter.meetingId,
    limit: filter.limit,
  );
});

/// User absences provider
final userAbsencesProvider = FutureProvider.family<List<AbsenceModel>, String>((ref, userId) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getUserAbsences(userId);
});

/// Meeting absences provider
final meetingAbsencesProvider = FutureProvider.family<List<AbsenceModel>, String>((ref, meetingId) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getMeetingAbsences(meetingId);
});

/// Warning count provider
final warningCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getWarningCount(userId);
});

/// Absence count provider
final absenceCountProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final repository = ref.read(warningRepositoryProvider);
  return repository.getAbsenceCount(userId);
});

/// Warning controller for managing warnings and absences
class WarningController extends StateNotifier<AsyncValue<void>> {
  final WarningRepository _repository;
  final Ref _ref;

  WarningController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Issue a warning to a user
  Future<bool> issueWarning({
    required String userId,
    required String userName,
    String? userSchoolId,
    String? userSchoolName,
    required WarningType type,
    required String reason,
    String? details,
    DateTime? expiresAt,
    String? meetingId,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();

    final warning = WarningModel(
      id: '',
      userId: userId,
      userName: userName,
      userSchoolId: userSchoolId,
      userSchoolName: userSchoolName,
      type: type,
      reason: reason,
      details: details,
      issuedById: currentUser.id,
      issuedByName: currentUser.fullName,
      issuedAt: DateTime.now(),
      expiresAt: expiresAt,
      isActive: true,
      meetingId: meetingId,
      countyId: currentUser.city ?? '',
    );

    final id = await _repository.createWarning(warning);

    if (id != null) {
      state = const AsyncValue.data(null);
      _invalidateWarningProviders(userId);
      return true;
    } else {
      state = AsyncValue.error('Failed to create warning', StackTrace.current);
      return false;
    }
  }

  /// Deactivate a warning
  Future<bool> deactivateWarning(String warningId, String userId) async {
    state = const AsyncValue.loading();

    final success = await _repository.deactivateWarning(warningId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateWarningProviders(userId);
      return true;
    } else {
      state = AsyncValue.error('Failed to deactivate warning', StackTrace.current);
      return false;
    }
  }

  /// Delete a warning
  Future<bool> deleteWarning(String warningId, String userId) async {
    state = const AsyncValue.loading();

    final success = await _repository.deleteWarning(warningId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateWarningProviders(userId);
      return true;
    } else {
      state = AsyncValue.error('Failed to delete warning', StackTrace.current);
      return false;
    }
  }

  /// Record an absence
  Future<bool> recordAbsence({
    required String meetingId,
    required String meetingTitle,
    required DateTime meetingDate,
    required String userId,
    required String userName,
    String? userSchoolId,
    String? userSchoolName,
    required AbsenceType type,
    String? reason,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();

    final absence = AbsenceModel(
      id: '',
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      meetingDate: meetingDate,
      userId: userId,
      userName: userName,
      userSchoolId: userSchoolId,
      userSchoolName: userSchoolName,
      type: type,
      reason: reason,
      recordedById: currentUser.id,
      recordedByName: currentUser.fullName,
      recordedAt: DateTime.now(),
      countyId: currentUser.city ?? '',
    );

    final id = await _repository.createAbsence(absence);

    if (id != null) {
      state = const AsyncValue.data(null);
      _invalidateAbsenceProviders(userId, meetingId);
      return true;
    } else {
      state = AsyncValue.error('Failed to record absence', StackTrace.current);
      return false;
    }
  }

  /// Update absence type (e.g., change from unexcused to excused)
  Future<bool> updateAbsenceType(String absenceId, AbsenceType type, String userId, String meetingId) async {
    state = const AsyncValue.loading();

    final success = await _repository.updateAbsence(absenceId, {'type': type.name});

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateAbsenceProviders(userId, meetingId);
      return true;
    } else {
      state = AsyncValue.error('Failed to update absence', StackTrace.current);
      return false;
    }
  }

  /// Delete an absence
  Future<bool> deleteAbsence(String absenceId, String userId, String meetingId) async {
    state = const AsyncValue.loading();

    final success = await _repository.deleteAbsence(absenceId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateAbsenceProviders(userId, meetingId);
      return true;
    } else {
      state = AsyncValue.error('Failed to delete absence', StackTrace.current);
      return false;
    }
  }

  void _invalidateWarningProviders(String userId) {
    _ref.invalidate(warningsProvider);
    _ref.invalidate(userWarningsProvider(userId));
    _ref.invalidate(warningCountProvider(userId));
  }

  void _invalidateAbsenceProviders(String userId, String meetingId) {
    _ref.invalidate(absencesProvider);
    _ref.invalidate(userAbsencesProvider(userId));
    _ref.invalidate(meetingAbsencesProvider(meetingId));
    _ref.invalidate(absenceCountProvider(userId));
  }
}

/// Warning controller provider
final warningControllerProvider =
    StateNotifierProvider<WarningController, AsyncValue<void>>((ref) {
  return WarningController(
    ref.watch(warningRepositoryProvider),
    ref,
  );
});

/// Check if current user can manage warnings (BEX only)
final canManageWarningsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});
