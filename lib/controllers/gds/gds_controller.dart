import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/gds_repository.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// GDS Repository provider
final gdsRepositoryProvider = Provider<GDSRepository>((ref) {
  return GDSRepository();
});

/// All GDS groups provider
final allGDSProvider = FutureProvider<List<GDSModel>>((ref) async {
  final repository = ref.watch(gdsRepositoryProvider);
  try {
    return await repository.getAllGDS().timeout(
      const Duration(seconds: 15),
      onTimeout: () => <GDSModel>[],
    );
  } catch (e) {
    return <GDSModel>[];
  }
});

/// Active GDS groups provider
final activeGDSProvider = FutureProvider<List<GDSModel>>((ref) async {
  final repository = ref.watch(gdsRepositoryProvider);
  try {
    return await repository.getActiveGDS().timeout(
      const Duration(seconds: 15),
      onTimeout: () => <GDSModel>[],
    );
  } catch (e) {
    return <GDSModel>[];
  }
});

/// GDS stream provider for real-time updates
final gdsStreamProvider = StreamProvider<List<GDSModel>>((ref) {
  final repository = ref.watch(gdsRepositoryProvider);
  return repository.getGDSStream();
});

/// Single GDS provider
final gdsProvider = FutureProvider.family<GDSModel?, String>((ref, gdsId) async {
  final repository = ref.watch(gdsRepositoryProvider);
  try {
    return await repository.getGDSById(gdsId).timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
  } catch (e) {
    return null;
  }
});

/// User's GDS groups provider
final userGDSProvider = FutureProvider.family<List<GDSModel>, String>((ref, userId) async {
  final repository = ref.watch(gdsRepositoryProvider);
  try {
    return await repository.getGDSForUser(userId).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <GDSModel>[],
    );
  } catch (e) {
    return <GDSModel>[];
  }
});

/// GDS Controller for managing support groups
class GDSController extends StateNotifier<AsyncValue<void>> {
  final GDSRepository _repository;
  final Ref _ref;

  GDSController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Check if current user can manage GDS (only BEX and superadmin)
  bool get canManageGDS {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.isBEXOrHigher;
  }

  /// Create new GDS
  Future<String?> createGDS({
    required String name,
    String? description,
    String? focus,
    required String leaderId,
    required String leaderName,
  }) async {
    if (!canManageGDS) return null;

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return null;

    state = const AsyncValue.loading();

    final gds = GDSModel(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      focus: focus,
      leaderId: leaderId,
      leaderName: leaderName,
      memberIds: [leaderId], // Leader is automatically a member
      members: [
        GDSMember(
          id: leaderId,
          name: leaderName,
          role: 'Leader',
          joinedAt: DateTime.now(),
        ),
      ],
      createdById: currentUser.id,
      createdByName: currentUser.fullName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final gdsId = await _repository.createGDS(gds);

    if (gdsId != null) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to create GDS', StackTrace.current);
    }

    return gdsId;
  }

  /// Update GDS
  Future<bool> updateGDS(GDSModel gds) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final success = await _repository.updateGDS(gds);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to update GDS', StackTrace.current);
    }

    return success;
  }

  /// Delete GDS
  Future<bool> deleteGDS(String gdsId) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final success = await _repository.deleteGDS(gdsId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to delete GDS', StackTrace.current);
    }

    return success;
  }

  /// Toggle GDS active status
  Future<bool> toggleGDSActive(String gdsId, bool isActive) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final success = await _repository.toggleGDSActive(gdsId, isActive);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to toggle GDS status', StackTrace.current);
    }

    return success;
  }

  /// Add member to GDS
  Future<bool> addMember(String gdsId, String memberId, String memberName, {String? role}) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final member = GDSMember(
      id: memberId,
      name: memberName,
      role: role,
      joinedAt: DateTime.now(),
    );

    final success = await _repository.addMember(gdsId, member);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to add member', StackTrace.current);
    }

    return success;
  }

  /// Remove member from GDS
  Future<bool> removeMember(String gdsId, String memberId) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final success = await _repository.removeMember(gdsId, memberId);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to remove member', StackTrace.current);
    }

    return success;
  }

  /// Update member role
  Future<bool> updateMemberRole(String gdsId, String memberId, String? role) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final success = await _repository.updateMemberRole(gdsId, memberId, role);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to update member role', StackTrace.current);
    }

    return success;
  }

  /// Change GDS leader
  Future<bool> changeLeader(String gdsId, String newLeaderId, String newLeaderName) async {
    if (!canManageGDS) return false;

    state = const AsyncValue.loading();

    final success = await _repository.changeLeader(gdsId, newLeaderId, newLeaderName);

    if (success) {
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } else {
      state = AsyncValue.error('Failed to change leader', StackTrace.current);
    }

    return success;
  }

  void _invalidateProviders() {
    _ref.invalidate(allGDSProvider);
    _ref.invalidate(activeGDSProvider);
  }
}

/// GDS Controller provider
final gdsControllerProvider =
    StateNotifierProvider<GDSController, AsyncValue<void>>((ref) {
  return GDSController(
    ref.watch(gdsRepositoryProvider),
    ref,
  );
});

/// Check if current user can manage GDS
final canManageGDSProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.isBEXOrHigher;
});
