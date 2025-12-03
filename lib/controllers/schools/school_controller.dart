import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/school_repository.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// School repository provider
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository();
});

/// All schools provider
final allSchoolsProvider = FutureProvider<List<SchoolModel>>((ref) async {
  final repository = ref.watch(schoolRepositoryProvider);
  return repository.getAllSchools();
});

/// Active schools provider
final activeSchoolsProvider = FutureProvider<List<SchoolModel>>((ref) async {
  final repository = ref.watch(schoolRepositoryProvider);
  return repository.getActiveSchools();
});

/// Single school provider
final schoolProvider = FutureProvider.family<SchoolModel?, String>((ref, schoolId) async {
  final repository = ref.watch(schoolRepositoryProvider);
  return repository.getSchoolById(schoolId);
});

/// Schools stream provider
final schoolsStreamProvider = StreamProvider.family<SchoolModel?, String>((ref, schoolId) {
  final repository = ref.watch(schoolRepositoryProvider);
  return repository.getSchoolStream(schoolId);
});

/// Search schools provider
final searchSchoolsProvider = FutureProvider.family<List<SchoolModel>, String>((ref, query) async {
  final repository = ref.watch(schoolRepositoryProvider);
  if (query.isEmpty) {
    return repository.getActiveSchools();
  }
  return repository.searchSchools(query);
});

/// Check if current user can manage schools (superadmin and bex only)
final canManageSchoolsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.superadmin || user.role == UserRole.bex;
});

/// School controller for CRUD operations
class SchoolController extends StateNotifier<AsyncValue<void>> {
  final SchoolRepository _repository;
  final Ref _ref;

  SchoolController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Check if current user can manage schools
  bool get canManageSchools {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.role == UserRole.superadmin || user.role == UserRole.bex;
  }

  /// Create new school
  Future<String?> createSchool({
    required String name,
    required String shortName,
    String? address,
    String? city,
    String? logoUrl,
  }) async {
    if (!canManageSchools) return null;

    state = const AsyncValue.loading();

    final school = SchoolModel(
      id: '',
      name: name,
      shortName: shortName,
      address: address,
      city: city,
      logoUrl: logoUrl,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createSchool(school);

    if (id != null) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to create school', StackTrace.current);
    }

    return id;
  }

  /// Update school
  Future<bool> updateSchool(SchoolModel school) async {
    if (!canManageSchools) return false;

    state = const AsyncValue.loading();

    final success = await _repository.updateSchool(school);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
      _ref.invalidate(schoolProvider(school.id));
    } else {
      state = AsyncValue.error('Failed to update school', StackTrace.current);
    }

    return success;
  }

  /// Assign school representative
  Future<bool> assignSchoolRep(String schoolId, String? repId, String? repName) async {
    if (!canManageSchools) return false;

    state = const AsyncValue.loading();

    final success = await _repository.updateSchoolRep(schoolId, repId, repName);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
      _ref.invalidate(schoolProvider(schoolId));
    } else {
      state = AsyncValue.error('Failed to assign school rep', StackTrace.current);
    }

    return success;
  }

  /// Toggle school active status
  Future<bool> toggleSchoolActive(String schoolId, bool isActive) async {
    if (!canManageSchools) return false;

    state = const AsyncValue.loading();

    final success = await _repository.toggleSchoolActive(schoolId, isActive);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
      _ref.invalidate(schoolProvider(schoolId));
    } else {
      state = AsyncValue.error('Failed to update school status', StackTrace.current);
    }

    return success;
  }

  /// Delete school
  Future<bool> deleteSchool(String schoolId) async {
    if (!canManageSchools) return false;

    state = const AsyncValue.loading();

    final success = await _repository.deleteSchool(schoolId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to delete school', StackTrace.current);
    }

    return success;
  }

  void _invalidateProviders() {
    _ref.invalidate(allSchoolsProvider);
    _ref.invalidate(activeSchoolsProvider);
  }
}

/// School controller provider
final schoolControllerProvider =
    StateNotifierProvider<SchoolController, AsyncValue<void>>((ref) {
  return SchoolController(
    ref.watch(schoolRepositoryProvider),
    ref,
  );
});
