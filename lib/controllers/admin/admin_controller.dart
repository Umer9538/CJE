import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/repositories/activity_repository.dart';
import '../../core/services/csv_import_service.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

const _uuid = Uuid();

/// List of all Romanian counties (judete)
const List<String> romanianCounties = [
  'Alba',
  'Arad',
  'Argeș',
  'Bacău',
  'Bihor',
  'Bistrița-Năsăud',
  'Botoșani',
  'Brașov',
  'Brăila',
  'București',
  'Buzău',
  'Caraș-Severin',
  'Călărași',
  'Cluj',
  'Constanța',
  'Covasna',
  'Dâmbovița',
  'Dolj',
  'Galați',
  'Giurgiu',
  'Gorj',
  'Harghita',
  'Hunedoara',
  'Ialomița',
  'Iași',
  'Ilfov',
  'Maramureș',
  'Mehedinți',
  'Mureș',
  'Neamț',
  'Olt',
  'Prahova',
  'Satu Mare',
  'Sălaj',
  'Sibiu',
  'Suceava',
  'Teleorman',
  'Timiș',
  'Tulcea',
  'Vaslui',
  'Vâlcea',
  'Vrancea',
];

/// Selected county for Superadmin to filter content
/// null means "All Counties" (no filtering)
final selectedCountyProvider = StateProvider<String?>((ref) => null);

/// Effective county to use for content filtering
/// - For Superadmin: uses selectedCountyProvider (null = all counties)
/// - For BEX: uses their assigned county (user.city)
/// - For other users: uses their assigned county (user.city)
final effectiveCountyProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  // Superadmin can switch counties
  if (user.role == UserRole.superadmin) {
    final selectedCounty = ref.watch(selectedCountyProvider);
    // If null, Superadmin sees all content (no county filter)
    return selectedCounty;
  }

  // All other users see content from their county
  return user.city;
});

/// User repository provider
final adminUserRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// All users provider - use sparingly, fetches ALL users
/// Uses ref.watch to automatically refresh when user state changes
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  // Watch currentUserProvider to auto-refresh when user changes (login/logout)
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

/// User count provider - lightweight, only fetches count
final userCountProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return 0;

  final repository = ref.read(adminUserRepositoryProvider);
  try {
    return await repository.getUserCount().timeout(
      const Duration(seconds: 5),
      onTimeout: () => 0,
    );
  } catch (e) {
    debugPrint('userCountProvider: error $e');
    return 0;
  }
});

/// Users by role provider
final usersByRoleProvider = FutureProvider.family<List<UserModel>, UserRole>((ref, role) async {
  final currentUser = ref.read(currentUserProvider);
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
/// Uses ref.watch to automatically refresh when user state changes
/// - SchoolRep: sees only pending users from their school
/// - BEX: sees only pending users from their county
/// - Superadmin: sees all pending users (or filtered by selected county)
final pendingUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  // Watch currentUserProvider to auto-refresh when user changes (login/logout)
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return <UserModel>[];
  }

  final repository = ref.read(adminUserRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  try {
    // Determine filtering based on user role:
    // - SchoolRep: filter by their school
    // - BEX: filter by their county (city field)
    // - Superadmin: uses selected county (null = all pending users)
    String? schoolId;
    String? countyId;

    if (currentUser.role == UserRole.schoolRep) {
      schoolId = currentUser.schoolId;
    } else if (currentUser.role == UserRole.bex) {
      countyId = currentUser.city; // BEX sees only their county's pending users
    } else if (currentUser.role == UserRole.superadmin) {
      countyId = effectiveCounty; // Superadmin uses selected county
    }

    return await repository.getPendingUsers(
      schoolId: schoolId,
      countyId: countyId,
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
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) {
    return null;
  }

  final repository = ref.read(adminUserRepositoryProvider);
  return repository.getUserById(userId);
});

/// Filtered users provider
/// Uses ref.watch to automatically refresh when user state changes
final filteredUsersProvider = FutureProvider.family<List<UserModel>, UserFilter>((ref, filter) async {
  // Watch currentUserProvider to auto-refresh when user changes (login/logout)
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
      // Apply same filtering as pendingUsersProvider
      String? schoolId;
      String? countyId;
      if (currentUser.role == UserRole.schoolRep) {
        schoolId = currentUser.schoolId;
      } else if (currentUser.role == UserRole.bex) {
        countyId = currentUser.city;
      }
      users = await repository.getPendingUsers(
        schoolId: schoolId,
        countyId: countyId,
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
  /// Only BEX and Superadmin can manage accounts
  bool get canManageUsers {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.role == UserRole.bex ||
           user.role == UserRole.superadmin;
  }

  /// Check if current user can change roles (only bex and superadmin)
  bool get canChangeRoles {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.role == UserRole.bex || user.role == UserRole.superadmin;
  }

  /// Change user role
  /// Note: Cannot promote users to superadmin - only one superadmin allowed
  /// SECURITY: Cannot change Superadmin's role - only Superadmin can modify Superadmin
  /// SECURITY: BEX cannot modify other BEX users - only Superadmin can
  /// For department role, also pass the department type
  Future<bool> changeUserRole(String userId, UserRole newRole, {DepartmentType? department}) async {
    debugPrint('AdminController.changeUserRole: canChangeRoles=$canChangeRoles');
    if (!canChangeRoles) {
      debugPrint('AdminController.changeUserRole: Permission denied');
      return false;
    }

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('AdminController.changeUserRole: No current user');
      return false;
    }

    // SECURITY: Get target user to check their role
    final targetUser = await _repository.getUserById(userId);
    if (targetUser == null) {
      debugPrint('AdminController.changeUserRole: Target user not found');
      return false;
    }

    // SECURITY: Superadmin accounts can ONLY be modified by themselves (not by BEX)
    if (targetUser.role == UserRole.superadmin && currentUser.role != UserRole.superadmin) {
      debugPrint('AdminController.changeUserRole: SECURITY BLOCK - Cannot modify Superadmin account');
      return false;
    }

    // SECURITY: BEX accounts can only be modified by Superadmin
    if (targetUser.role == UserRole.bex && currentUser.role != UserRole.superadmin) {
      debugPrint('AdminController.changeUserRole: SECURITY BLOCK - Only Superadmin can modify BEX accounts');
      return false;
    }

    // Prevent creating additional superadmins - only one allowed
    if (newRole == UserRole.superadmin) {
      debugPrint('AdminController.changeUserRole: Cannot promote to superadmin');
      return false;
    }

    // Department role requires a department type
    if (newRole == UserRole.department && department == null) {
      debugPrint('AdminController.changeUserRole: Department role requires department type');
      return false;
    }

    state = const AsyncValue.loading();

    debugPrint('AdminController.changeUserRole: Calling repository...');
    final success = await _repository.changeUserRole(userId, newRole, department: department);
    debugPrint('AdminController.changeUserRole: Repository returned $success');

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
      debugPrint('AdminController.changeUserRole: Providers invalidated');
    } else {
      state = AsyncValue.error('Failed to change role', StackTrace.current);
      debugPrint('AdminController.changeUserRole: Failed to change role');
    }

    return success;
  }

  /// Approve pending user
  Future<bool> approveUser(String userId) async {
    if (!canManageUsers) return false;

    state = const AsyncValue.loading();

    // Get user details before approving for logging
    final userToApprove = await _repository.getUserById(userId);

    final success = await _repository.approveUser(userId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);

      // Log the activity
      if (userToApprove != null) {
        final activityRepo = _ref.read(activityRepositoryProvider);
        final currentUser = _ref.read(currentUserProvider);
        await activityRepo.logUserApproved(
          userId: userId,
          userName: userToApprove.fullName,
          approvedBy: currentUser?.fullName,
        );
        _ref.invalidate(recentActivitiesProvider);
      }
    } else {
      state = AsyncValue.error('Failed to approve user', StackTrace.current);
    }

    return success;
  }

  /// Suspend user
  /// SECURITY: Cannot suspend Superadmin or BEX (only Superadmin can)
  Future<bool> suspendUser(String userId) async {
    if (!canManageUsers) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // SECURITY: Get target user to check their role
    final targetUser = await _repository.getUserById(userId);
    if (targetUser == null) return false;

    // SECURITY: Superadmin cannot be suspended by anyone except themselves
    if (targetUser.role == UserRole.superadmin && currentUser.role != UserRole.superadmin) {
      debugPrint('suspendUser: SECURITY BLOCK - Cannot suspend Superadmin');
      return false;
    }

    // SECURITY: BEX can only be suspended by Superadmin
    if (targetUser.role == UserRole.bex && currentUser.role != UserRole.superadmin) {
      debugPrint('suspendUser: SECURITY BLOCK - Only Superadmin can suspend BEX');
      return false;
    }

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
  /// SECURITY: Cannot reactivate Superadmin or BEX (only Superadmin can)
  Future<bool> reactivateUser(String userId) async {
    if (!canManageUsers) return false;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // SECURITY: Get target user to check their role
    final targetUser = await _repository.getUserById(userId);
    if (targetUser == null) return false;

    // SECURITY: Superadmin can only be reactivated by Superadmin
    if (targetUser.role == UserRole.superadmin && currentUser.role != UserRole.superadmin) {
      debugPrint('reactivateUser: SECURITY BLOCK - Cannot reactivate Superadmin');
      return false;
    }

    // SECURITY: BEX can only be reactivated by Superadmin
    if (targetUser.role == UserRole.bex && currentUser.role != UserRole.superadmin) {
      debugPrint('reactivateUser: SECURITY BLOCK - Only Superadmin can reactivate BEX');
      return false;
    }

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

  /// Delete user permanently (Superadmin only)
  /// This permanently removes the user account from the database
  Future<bool> deleteUserPermanently(String userId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // SECURITY: Only Superadmin can permanently delete users
    if (currentUser.role != UserRole.superadmin) {
      debugPrint('deleteUserPermanently: SECURITY BLOCK - Only Superadmin can delete users');
      return false;
    }

    // SECURITY: Cannot delete yourself
    if (currentUser.id == userId) {
      debugPrint('deleteUserPermanently: SECURITY BLOCK - Cannot delete your own account');
      return false;
    }

    // SECURITY: Get target user to check their role
    final targetUser = await _repository.getUserById(userId);
    if (targetUser == null) return false;

    // SECURITY: Cannot delete other Superadmins
    if (targetUser.role == UserRole.superadmin) {
      debugPrint('deleteUserPermanently: SECURITY BLOCK - Cannot delete Superadmin accounts');
      return false;
    }

    state = const AsyncValue.loading();

    final success = await _repository.deleteUser(userId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders(userId);
    } else {
      state = AsyncValue.error('Failed to delete user', StackTrace.current);
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

  // ==================== DIRECT USER CREATION ====================

  /// Create user directly in Firestore (without Firebase Auth)
  /// This is used by admins to add users without getting logged out
  /// The user will need to use "Forgot Password" to set their password
  Future<String?> createUserDirectly({
    required String email,
    required String fullName,
    required String schoolId,
    required String? schoolName,
    required String phoneNumber,
    required String city,
    required UserRole role,
    String? className,
  }) async {
    if (!canManageUsers) return null;

    state = const AsyncValue.loading();

    try {
      // Check if email already exists
      final existingUser = await _repository.getUserByEmail(email);
      if (existingUser != null) {
        state = AsyncValue.error('Email already exists', StackTrace.current);
        return null;
      }

      // Create user model
      final userModel = UserModel(
        id: '', // Will be set by Firestore auto-ID
        email: email.toLowerCase(),
        fullName: fullName,
        phoneNumber: phoneNumber,
        city: city,
        role: role,
        status: UserStatus.pending,
        schoolId: schoolId,
        schoolName: schoolName,
        className: className,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create in Firestore with auto-generated ID
      final userId = await _repository.createUserWithAutoId(userModel);

      if (userId != null) {
        state = const AsyncValue.data(null);
        _ref.invalidate(allUsersProvider);
        _ref.invalidate(pendingUsersProvider);
        _ref.invalidate(filteredUsersProvider);
        return userId;
      } else {
        state = AsyncValue.error('Failed to create user', StackTrace.current);
        return null;
      }
    } catch (e) {
      debugPrint('Error creating user directly: $e');
      state = AsyncValue.error('Error: $e', StackTrace.current);
      return null;
    }
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
/// Only BEX and Superadmin can access admin panel
final hasAdminAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can change roles
final canChangeRolesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Users by school provider (one-time fetch)
final usersBySchoolProvider = FutureProvider.family<List<UserModel>, String>((ref, schoolId) async {
  final currentUser = ref.read(currentUserProvider);
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

/// Users by school stream provider (real-time updates)
final usersBySchoolStreamProvider = StreamProvider.family<List<UserModel>, String>((ref, schoolId) {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(<UserModel>[]);
  }

  final repository = ref.read(adminUserRepositoryProvider);
  return repository.getUsersBySchoolStream(schoolId);
});

// ==================== ACTIVITY PROVIDERS ====================

/// Activity repository provider
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Recent activities provider
final recentActivitiesProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) {
    return <ActivityModel>[];
  }

  final repository = ref.read(activityRepositoryProvider);
  try {
    return await repository.getRecentActivities(limit: 10).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <ActivityModel>[],
    );
  } catch (e) {
    debugPrint('recentActivitiesProvider: error $e');
    return <ActivityModel>[];
  }
});

/// Recent activities stream provider
final recentActivitiesStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivitiesStream(limit: 10);
});
