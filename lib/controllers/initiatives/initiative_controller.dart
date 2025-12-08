import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/repositories.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Initiative repository provider
final initiativeRepositoryProvider = Provider<InitiativeRepository>((ref) {
  return InitiativeRepository();
});

/// Initiatives list provider
final initiativesProvider = FutureProvider.family<List<InitiativeModel>, InitiativeFilter>((ref, filter) async {
  final repository = ref.watch(initiativeRepositoryProvider);

  return repository.getInitiatives(
    status: filter.status,
    schoolId: filter.schoolId,
    authorId: filter.authorId,
    limit: filter.limit,
  );
});

/// Initiatives stream provider
final initiativesStreamProvider = StreamProvider.family<List<InitiativeModel>, InitiativeFilter>((ref, filter) {
  final repository = ref.watch(initiativeRepositoryProvider);

  return repository.getInitiativesStream(
    status: filter.status,
    schoolId: filter.schoolId,
    limit: filter.limit,
  );
});

/// Single initiative provider
final initiativeProvider = FutureProvider.family<InitiativeModel?, String>((ref, id) async {
  final repository = ref.watch(initiativeRepositoryProvider);
  return repository.getInitiativeById(id);
});

/// Recent initiatives for home screen
final recentInitiativesProvider = FutureProvider<List<InitiativeModel>>((ref) async {
  final repository = ref.read(initiativeRepositoryProvider);
  final user = ref.read(currentUserProvider); // Use read to avoid rebuilds
  try {
    return await repository.getRecentInitiatives(
      schoolId: user?.schoolId,
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <InitiativeModel>[],
    );
  } catch (e) {
    return <InitiativeModel>[];
  }
});

/// Comments for an initiative
final initiativeCommentsProvider = FutureProvider.family<List<InitiativeComment>, String>((ref, initiativeId) async {
  final repository = ref.watch(initiativeRepositoryProvider);
  return repository.getComments(initiativeId);
});

/// Comments stream
final initiativeCommentsStreamProvider = StreamProvider.family<List<InitiativeComment>, String>((ref, initiativeId) {
  final repository = ref.watch(initiativeRepositoryProvider);
  return repository.getCommentsStream(initiativeId);
});

/// Check if current user supports initiative
final isSupportingProvider = FutureProvider.family<bool, String>((ref, initiativeId) async {
  final repository = ref.read(initiativeRepositoryProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return false;
  return repository.isSupporting(initiativeId, user.id);
});

/// Filter model for initiatives
class InitiativeFilter {
  final InitiativeStatus? status;
  final String? schoolId;
  final String? authorId;
  final int limit;

  const InitiativeFilter({
    this.status,
    this.schoolId,
    this.authorId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitiativeFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          schoolId == other.schoolId &&
          authorId == other.authorId &&
          limit == other.limit;

  @override
  int get hashCode => status.hashCode ^ schoolId.hashCode ^ authorId.hashCode ^ limit.hashCode;
}

/// Initiative controller for CRUD operations
class InitiativeController extends StateNotifier<AsyncValue<void>> {
  final InitiativeRepository _repository;
  final Ref _ref;

  InitiativeController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Create new initiative
  Future<String?> createInitiative({
    required String title,
    required String description,
    String? problem,
    String? solution,
    String? impact,
    List<String>? tags,
    List<String>? attachmentUrls,
    bool submitImmediately = false,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    final initiative = InitiativeModel(
      id: '',
      title: title,
      description: description,
      problem: problem,
      solution: solution,
      impact: impact,
      status: submitImmediately ? InitiativeStatus.submitted : InitiativeStatus.draft,
      authorId: user.id,
      authorName: user.fullName,
      schoolId: user.schoolId,
      schoolName: user.schoolName,
      tags: tags ?? [],
      attachmentUrls: attachmentUrls ?? [],
      submittedAt: submitImmediately ? DateTime.now() : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createInitiative(initiative);

    if (id != null) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(recentInitiativesProvider);
    } else {
      state = AsyncValue.error('Failed to create initiative', StackTrace.current);
    }

    return id;
  }

  /// Update initiative
  Future<bool> updateInitiative(InitiativeModel initiative) async {
    state = const AsyncValue.loading();

    final success = await _repository.updateInitiative(initiative);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(initiative.id));
    } else {
      state = AsyncValue.error('Failed to update initiative', StackTrace.current);
    }

    return success;
  }

  /// Delete initiative
  Future<bool> deleteInitiative(String id) async {
    state = const AsyncValue.loading();

    final success = await _repository.deleteInitiative(id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(recentInitiativesProvider);
    } else {
      state = AsyncValue.error('Failed to delete initiative', StackTrace.current);
    }

    return success;
  }

  /// Submit initiative for review
  Future<bool> submitInitiative(String id) async {
    final success = await _repository.updateStatus(id, InitiativeStatus.submitted);
    if (success) {
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
    }
    return success;
  }

  /// Update initiative status
  Future<bool> updateStatus(String id, InitiativeStatus status) async {
    final success = await _repository.updateStatus(id, status);
    if (success) {
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
      _ref.invalidate(recentInitiativesProvider);
    }
    return success;
  }

  /// Toggle support for initiative
  Future<bool> toggleSupport(String initiativeId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    final success = await _repository.toggleSupport(initiativeId, user.id);
    if (success) {
      _ref.invalidate(initiativeProvider(initiativeId));
      _ref.invalidate(isSupportingProvider(initiativeId));
    }
    return success;
  }

  /// Vote on initiative
  Future<bool> vote(String initiativeId, String vote) async {
    final success = await _repository.vote(initiativeId, vote);
    if (success) {
      _ref.invalidate(initiativeProvider(initiativeId));
    }
    return success;
  }

  /// Add comment
  Future<String?> addComment(String initiativeId, String content, {bool isOfficial = false}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;

    final comment = InitiativeComment(
      id: '',
      initiativeId: initiativeId,
      authorId: user.id,
      authorName: user.fullName,
      authorPhotoUrl: user.photoUrl,
      content: content,
      isOfficial: isOfficial,
      createdAt: DateTime.now(),
    );

    final id = await _repository.addComment(comment);
    if (id != null) {
      _ref.invalidate(initiativeCommentsProvider(initiativeId));
    }
    return id;
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId, String initiativeId) async {
    final success = await _repository.deleteComment(commentId);
    if (success) {
      _ref.invalidate(initiativeCommentsProvider(initiativeId));
    }
    return success;
  }

  /// Check if current user can approve/reject a specific initiative
  bool _canApproveInitiative(InitiativeModel? initiative) {
    final user = _ref.read(currentUserProvider);
    if (user == null || initiative == null) return false;

    // BEX and Superadmin can approve any initiative
    if (user.role == UserRole.bex || user.role == UserRole.superadmin) {
      return true;
    }

    // SchoolRep can only approve initiatives from their school
    if (user.role == UserRole.schoolRep) {
      return initiative.schoolId == user.schoolId;
    }

    return false;
  }

  /// Approve initiative - moves to review status
  /// SchoolRep can approve initiatives from their school
  /// BEX and Superadmin can approve all initiatives
  Future<bool> approveInitiative(String id) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    // Get initiative to check permissions
    final initiative = await _repository.getInitiativeById(id);
    if (!_canApproveInitiative(initiative)) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return false;
    }

    final success = await _repository.updateStatus(id, InitiativeStatus.review);
    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
      _ref.invalidate(recentInitiativesProvider);
    } else {
      state = AsyncValue.error('Failed to approve initiative', StackTrace.current);
    }
    return success;
  }

  /// Move initiative to debate stage
  Future<bool> moveToDebate(String id) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    final initiative = await _repository.getInitiativeById(id);
    if (!_canApproveInitiative(initiative)) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return false;
    }

    final success = await _repository.updateStatus(id, InitiativeStatus.debate);
    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
    } else {
      state = AsyncValue.error('Failed to move to debate', StackTrace.current);
    }
    return success;
  }

  /// Move initiative to voting stage
  Future<bool> moveToVoting(String id) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    final initiative = await _repository.getInitiativeById(id);
    if (!_canApproveInitiative(initiative)) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return false;
    }

    final success = await _repository.updateStatus(id, InitiativeStatus.voting);
    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
    } else {
      state = AsyncValue.error('Failed to move to voting', StackTrace.current);
    }
    return success;
  }

  /// Adopt initiative (final approval)
  Future<bool> adoptInitiative(String id) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    final initiative = await _repository.getInitiativeById(id);
    if (!_canApproveInitiative(initiative)) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return false;
    }

    final success = await _repository.updateStatus(id, InitiativeStatus.adopted);
    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
      _ref.invalidate(recentInitiativesProvider);
    } else {
      state = AsyncValue.error('Failed to adopt initiative', StackTrace.current);
    }
    return success;
  }

  /// Reject initiative with reason
  /// SchoolRep can reject initiatives from their school
  /// BEX and Superadmin can reject all initiatives
  Future<bool> rejectInitiative(String id, String reason) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    // Get initiative to check permissions
    final initiative = await _repository.getInitiativeById(id);
    if (!_canApproveInitiative(initiative)) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return false;
    }

    final success = await _repository.rejectInitiative(id, reason);
    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(initiativesProvider);
      _ref.invalidate(initiativeProvider(id));
      _ref.invalidate(recentInitiativesProvider);
    } else {
      state = AsyncValue.error('Failed to reject initiative', StackTrace.current);
    }
    return success;
  }
}

/// Initiative controller provider
final initiativeControllerProvider =
    StateNotifierProvider<InitiativeController, AsyncValue<void>>((ref) {
  return InitiativeController(
    ref.watch(initiativeRepositoryProvider),
    ref,
  );
});

/// Check if current user can approve/reject initiatives
/// SchoolRep can approve initiatives from their school
/// BEX and Superadmin can approve all initiatives
final canApproveInitiativesProvider = Provider.family<bool, InitiativeModel?>((ref, initiative) {
  final user = ref.watch(currentUserProvider);
  if (user == null || initiative == null) return false;

  // BEX and Superadmin can approve any initiative
  if (user.role == UserRole.bex || user.role == UserRole.superadmin) {
    return true;
  }

  // SchoolRep can only approve initiatives from their school
  if (user.role == UserRole.schoolRep) {
    return initiative.schoolId == user.schoolId;
  }

  return false;
});

/// Provider to check if user can manage initiatives (approve/reject/change status)
final canManageInitiativeProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can draft initiatives
/// Class Reps and above can draft initiatives
final canDraftInitiativesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.classRep ||
         user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can vote on initiatives
/// Class Reps and above can vote on initiatives
final canVoteOnInitiativesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.classRep ||
         user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can comment on initiatives
/// Class Reps and above can comment on initiatives
final canCommentOnInitiativesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.classRep ||
         user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can support initiatives (everyone can support)
final canSupportInitiativesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
