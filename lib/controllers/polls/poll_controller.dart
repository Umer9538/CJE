import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/poll_repository.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Poll repository provider
final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepository();
});

/// Polls list provider
final pollsProvider = FutureProvider.family<List<PollModel>, PollFilter>((ref, filter) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return <PollModel>[];
  }

  final repository = ref.read(pollRepositoryProvider);

  try {
    return await repository.getPolls(
      type: filter.type,
      schoolId: user.schoolId,
      activeOnly: filter.activeOnly,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <PollModel>[],
    );
  } catch (e) {
    return <PollModel>[];
  }
});

/// Polls stream provider
final pollsStreamProvider = StreamProvider.family<List<PollModel>, PollFilter>((ref, filter) {
  final repository = ref.watch(pollRepositoryProvider);

  return repository.getPollsStream(
    type: filter.type,
    limit: filter.limit,
  );
});

/// Single poll provider
final pollProvider = FutureProvider.family<PollModel?, String>((ref, id) async {
  final repository = ref.watch(pollRepositoryProvider);
  return repository.getPollById(id);
});

/// Active polls for home screen
final activePollsProvider = FutureProvider<List<PollModel>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return <PollModel>[];
  }

  final repository = ref.read(pollRepositoryProvider);

  try {
    return await repository.getActivePolls(
      schoolId: user.schoolId,
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <PollModel>[],
    );
  } catch (e) {
    return <PollModel>[];
  }
});

/// Check if user has voted on a poll
final hasVotedProvider = FutureProvider.family<bool, String>((ref, pollId) async {
  final repository = ref.read(pollRepositoryProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return false;
  return repository.hasUserVoted(pollId, user.id);
});

/// Filter model for polls
class PollFilter {
  final PollType? type;
  final bool activeOnly;
  final int limit;

  const PollFilter({
    this.type,
    this.activeOnly = false,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          activeOnly == other.activeOnly &&
          limit == other.limit;

  @override
  int get hashCode => type.hashCode ^ activeOnly.hashCode ^ limit.hashCode;
}

/// Poll controller for CRUD operations
class PollController extends StateNotifier<AsyncValue<void>> {
  final PollRepository _repository;
  final Ref _ref;

  PollController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Create new poll (only schoolRep, bex, superadmin can create)
  Future<String?> createPoll({
    required String question,
    String? description,
    required PollType type,
    required List<PollOption> options,
    bool isAnonymous = true,
    bool allowMultipleVotes = false,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    // Permission check - only schoolRep, bex, superadmin can create polls
    if (user.role != UserRole.schoolRep &&
        user.role != UserRole.bex &&
        user.role != UserRole.superadmin) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return null;
    }

    // County polls can only be created by bex and superadmin
    if (type == PollType.county &&
        user.role != UserRole.bex &&
        user.role != UserRole.superadmin) {
      state = AsyncValue.error('Permission denied for county polls', StackTrace.current);
      return null;
    }

    final poll = PollModel(
      id: '',
      question: question,
      description: description,
      type: type,
      options: options,
      createdById: user.id,
      createdByName: user.fullName,
      schoolId: type == PollType.school ? user.schoolId : null,
      schoolName: type == PollType.school ? user.schoolName : null,
      isAnonymous: isAnonymous,
      allowMultipleVotes: allowMultipleVotes,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createPoll(poll);

    if (id != null) {
      state = const AsyncValue.data(null);
      _ref.invalidate(pollsProvider);
      _ref.invalidate(activePollsProvider);
    } else {
      state = AsyncValue.error('Failed to create poll', StackTrace.current);
    }

    return id;
  }

  /// Vote on poll - ALL users (including students) can vote if poll allows
  Future<bool> vote(String pollId, String optionId) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    final success = await _repository.vote(pollId, optionId, user.id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(pollProvider(pollId));
      _ref.invalidate(hasVotedProvider(pollId));
      _ref.invalidate(activePollsProvider);
    } else {
      state = AsyncValue.error('Failed to vote', StackTrace.current);
    }

    return success;
  }

  /// Delete poll
  Future<bool> deletePoll(String id) async {
    state = const AsyncValue.loading();

    final success = await _repository.deletePoll(id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(pollsProvider);
      _ref.invalidate(activePollsProvider);
    } else {
      state = AsyncValue.error('Failed to delete poll', StackTrace.current);
    }

    return success;
  }
}

/// Poll controller provider
final pollControllerProvider =
    StateNotifierProvider<PollController, AsyncValue<void>>((ref) {
  return PollController(
    ref.watch(pollRepositoryProvider),
    ref,
  );
});
