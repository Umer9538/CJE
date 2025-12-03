import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/csv_import_service.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

const _uuid = Uuid();

/// User repository provider
final adminUserRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// All users provider
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return <UserModel>[];
  }

  final repository = ref.read(adminUserRepositoryProvider);
  try {
    return await repository.getAllUsers().timeout(
      const Duration(seconds: 15),
      onTimeout: () => <UserModel>[],
    );
  } catch (e) {
    debugPrint('allUsersProvider: error $e');
    return <UserModel>[];
  }
});

/// Users by role provider
final usersByRoleProvider = FutureProvider.family<List<UserModel>, UserRole>((ref, role) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return <UserModel>[];
  }

  final repository = ref.read(adminUserRepositoryProvider);
  try {
    return await repository.getUsersByRole(role).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <UserModel>[],
    );
  } catch (e) {
    return <UserModel>[];
  }
});

/// Pending users provider
final pendingUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return <UserModel>[];
  }

  final repository = ref.read(adminUserRepositoryProvider);
  try {
    return await repository.getPendingUsers(
      schoolId: currentUser.role == UserRole.schoolRep ? currentUser.schoolId : null,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <UserModel>[],
    );
  } catch (e) {
    return <UserModel>[];
  }
});

/// Single user provider
final adminUserProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return null;
  }

  final repository = ref.read(adminUserRepositoryProvider);
  return repository.getUserById(userId);
});

/// Filtered users provider
final filteredUsersProvider = FutureProvider.family<List<UserModel>, UserFilter>((ref, filter) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return <UserModel>[];
  }

  final repository = ref.read(adminUserRepositoryProvider);

  try {
    List<UserModel> users;

    if (filter.role != null) {
      users = await repository.getUsersByRole(filter.role!);
    } else if (filter.status == UserStatus.pending) {
      users = await repository.getPendingUsers(
        schoolId: currentUser.role == UserRole.schoolRep ? currentUser.schoolId : null,
      );
    } else {
      users = await repository.getAllUsers();
    }

    // Apply additional filters
    if (filter.status != null && filter.role != null) {
      users = users.where((u) => u.status == filter.status).toList();
    }

    if (filter.schoolId != null) {
      users = users.where((u) => u.schoolId == filter.schoolId).toList();
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      users = users.where((u) =>
        u.fullName.toLowerCase().contains(query) ||
        u.email.toLowerCase().contains(query)
      ).toList();
    }

    // Sort by name
    users.sort((a, b) => a.fullName.compareTo(b.fullName));

    return users;
  } catch (e) {
    return <UserModel>[];
  }
});

/// User filter model
class UserFilter {
  final UserRole? role;
  final UserStatus? status;
  final String? schoolId;
  final String? searchQuery;

  const UserFilter({
    this.role,
    this.status,
    this.schoolId,
    this.searchQuery,
  });

  UserFilter copyWith({
    UserRole? role,
    UserStatus? status,
    String? schoolId,
    String? searchQuery,
    bool clearRole = false,
    bool clearStatus = false,
    bool clearSchool = false,
    bool clearSearch = false,
  }) {
    return UserFilter(
      role: clearRole ? null : (role ?? this.role),
      status: clearStatus ? null : (status ?? this.status),
      schoolId: clearSchool ? null : (schoolId ?? this.schoolId),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserFilter &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          status == other.status &&
          schoolId == other.schoolId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      role.hashCode ^ status.hashCode ^ schoolId.hashCode ^ searchQuery.hashCode;
}

/// Admin controller for user management operations
class AdminController extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repository;
  final Ref _ref;

  AdminController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Check if current user can manage users
  bool get canManageUsers {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.role == UserRole.bex ||
           user.role == UserRole.superadmin ||
           user.role == UserRole.schoolRep;
  }

  /// Check if current user can change roles (only bex and superadmin)
  bool get canChangeRoles {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.role == UserRole.bex || user.role == UserRole.superadmin;
  }

  /// Change user role
  Future<bool> changeUserRole(String userId, UserRole newRole) async {
    if (!canChangeRoles) return false;

    state = const AsyncValue.loading();

    final success = await _repository.changeUserRole(userId, newRole);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to change role', StackTrace.current);
    }

    return success;
  }

  /// Approve pending user
  Future<bool> approveUser(String userId) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.approveUser(userId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to approve user', StackTrace.current);
    }

    return success;
  }

  /// Suspend user
  Future<bool> suspendUser(String userId) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.suspendUser(userId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to suspend user', StackTrace.current);
    }

    return success;
  }

  /// Reactivate suspended user
  Future<bool> reactivateUser(String userId) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.approveUser(userId); // Same as approve

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to reactivate user', StackTrace.current);
    }

    return success;
  }

  /// Update user fields
  Future<bool> updateUser(String userId, Map<String, dynamic> fields) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.updateUserFields(userId, fields);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to update user', StackTrace.current);
    }

    return success;
  }

  void _invalidateProviders(String userId) {
    _ref.invalidate(allUsersProvider);
    _ref.invalidate(pendingUsersProvider);
    _ref.invalidate(filteredUsersProvider);
    _ref.invalidate(adminUserProvider(userId));
  }

  // ==================== WARNING MANAGEMENT ====================

  /// Add a warning to a user
  Future<bool> addWarning(String userId, String reason) async {
    if (!canManageUsers) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();

    final warning = UserWarning(
      id: _uuid.v4(),
      reason: reason,
      issuedById: currentUser.id,
      issuedByName: currentUser.fullName,
      issuedAt: DateTime.now(),
    );

    final success = await _repository.addWarning(userId, warning);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to add warning', StackTrace.current);
    }

    return success;
  }

  /// Remove a warning from a user
  Future<bool> removeWarning(String userId, String warningId) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.removeWarning(userId, warningId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to remove warning', StackTrace.current);
    }

    return success;
  }

  /// Resolve a warning
  Future<bool> resolveWarning(String userId, String warningId, String? resolutionNote) async {
    if (!canManageUsers) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();

    final success = await _repository.resolveWarning(
      userId,
      warningId,
      currentUser.fullName,
      resolutionNote,
    );

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to resolve warning', StackTrace.current);
    }

    return success;
  }

  // ==================== ABSENCE MANAGEMENT ====================

  /// Add an absence to a user
  Future<bool> addAbsence(
    String userId,
    String meetingId,
    String meetingTitle,
    DateTime meetingDate,
  ) async {
    if (!canManageUsers) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();

    final absence = UserAbsence(
      id: _uuid.v4(),
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      meetingDate: meetingDate,
      recordedById: currentUser.id,
      recordedByName: currentUser.fullName,
      recordedAt: DateTime.now(),
    );

    final success = await _repository.addAbsence(userId, absence);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to add absence', StackTrace.current);
    }

    return success;
  }

  /// Remove an absence from a user
  Future<bool> removeAbsence(String userId, String absenceId) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.removeAbsence(userId, absenceId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to remove absence', StackTrace.current);
    }

    return success;
  }

  /// Excuse an absence
  Future<bool> excuseAbsence(String userId, String absenceId, String reason) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    final success = await _repository.excuseAbsence(userId, absenceId, reason);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to excuse absence', StackTrace.current);
    }

    return success;
  }

  // ==================== CSV IMPORT ====================

  /// Import users from CSV content
  Future<CSVImportResult> importUsersFromCSV(String csvContent) async {
    if (!canChangeRoles) {
      return CSVImportResult(
        successfulUsers: [],
        errors: [CSVImportError(rowNumber: 0, message: 'No permission to import users')],
        totalRows: 0,
      );
    }

    state = const AsyncValue.loading();

    final csvService = CSVImportService();
    final parseResult = csvService.parseCSV(csvContent);

    if (parseResult.successfulUsers.isEmpty) {
      state = const AsyncValue.data(null);
      return parseResult;
    }

    // Check for duplicate emails
    final List<UserModel> usersToCreate = [];
    final List<CSVImportError> additionalErrors = [];

    for (final user in parseResult.successfulUsers) {
      final existingUser = await _repository.getUserByEmail(user.email);
      if (existingUser != null) {
        additionalErrors.add(CSVImportError(
          rowNumber: parseResult.successfulUsers.indexOf(user) + 2, // +2 for header and 0-index
          message: 'Email already exists: ${user.email}',
        ));
      } else {
        usersToCreate.add(user);
      }
    }

    // Create users in Firestore
    final List<UserModel> createdUsers = [];
    for (final user in usersToCreate) {
      final userId = await _repository.createUserWithAutoId(user);
      if (userId != null) {
        createdUsers.add(user.copyWith(id: userId));
      } else {
        additionalErrors.add(CSVImportError(
          rowNumber: parseResult.successfulUsers.indexOf(user) + 2,
          message: 'Failed to create user: ${user.email}',
        ));
      }
    }

    state = const AsyncValue.data(null);
    _ref.invalidate(allUsersProvider);
    _ref.invalidate(pendingUsersProvider);

    return CSVImportResult(
      successfulUsers: createdUsers,
      errors: [...parseResult.errors, ...additionalErrors],
      totalRows: parseResult.totalRows,
    );
  }
}

/// Admin controller provider
final adminControllerProvider =
    StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
  return AdminController(
    ref.watch(adminUserRepositoryProvider),
    ref,
  );
});

/// Check if current user has admin access
final hasAdminAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can change roles
final canChangeRolesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Users by school provider
final usersBySchoolProvider = FutureProvider.family<List<UserModel>, String>((ref, schoolId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return <UserModel>[];
  }

  final repository = ref.read(adminUserRepositoryProvider);
  try {
    return await repository.getUsersBySchool(schoolId).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <UserModel>[],
    );
  } catch (e) {
    return <UserModel>[];
  }
});
