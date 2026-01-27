import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/poll_repository.dart';
import '../../core/constants/enums.dart';
import '../../core/services/translation_service.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';
import '../admin/admin_controller.dart';

/// Poll repository provider
final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepository();
});

/// Helper function to check if user can view content based on visibility role
bool _canViewPoll(UserRole? userRole, UserRole? minVisibilityRole) {
  // If no visibility restriction, everyone can view
  if (minVisibilityRole == null) return true;
  // If user is not logged in, they can't view restricted content
  if (userRole == null) return false;
  // BEX and Superadmin always bypass visibility restrictions
  if (userRole == UserRole.bex || userRole == UserRole.superadmin) return true;
  // Check if user's hierarchy level meets the minimum required
  return userRole.hierarchyLevel >= minVisibilityRole.hierarchyLevel;
}

/// Polls list provider
final pollsProvider = FutureProvider.family<List<PollModel>, PollFilter>((ref, filter) async {
  // Use ref.watch for reactive dependencies so provider rebuilds when user changes
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return <PollModel>[];
  }

  final repository = ref.read(pollRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For superadmin and bex, show all polls without schoolId filter
  // For regular users, filter by their schoolId (county polls are always visible)
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;

  try {
    final polls = await repository.getPolls(
      type: filter.type,
      schoolId: shouldFilterBySchool ? user.schoolId : null,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
      activeOnly: filter.activeOnly,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <PollModel>[],
    );
    // Filter by visibility role
    return polls.where((p) => _canViewPoll(user.role, p.minVisibilityRole)).toList();
  } catch (e) {
    return <PollModel>[];
  }
});

/// Polls stream provider
final pollsStreamProvider = StreamProvider.family<List<PollModel>, PollFilter>((ref, filter) {
  final repository = ref.watch(pollRepositoryProvider);
  // Use ref.watch for reactive dependencies
  final user = ref.watch(currentUserProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For superadmin and bex, show all polls without schoolId filter
  // For regular users, filter by their schoolId (county polls are always visible)
  final shouldFilterBySchool = user?.role != UserRole.superadmin && user?.role != UserRole.bex;

  return repository.getPollsStream(
    type: filter.type,
    schoolId: shouldFilterBySchool ? user?.schoolId : null,
    countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
    limit: filter.limit,
  ).map((polls) {
    // Filter by visibility role
    var filtered = polls.where((p) => _canViewPoll(user?.role, p.minVisibilityRole)).toList();
    // Apply activeOnly filter if enabled
    if (filter.activeOnly) {
      filtered = filtered.where((poll) => poll.isActive).toList();
    }
    return filtered;
  });
});

/// Single poll provider
final pollProvider = FutureProvider.family<PollModel?, String>((ref, id) async {
  final repository = ref.watch(pollRepositoryProvider);
  return repository.getPollById(id);
});

/// Active polls for home screen
final activePollsProvider = FutureProvider<List<PollModel>>((ref) async {
  // Use ref.watch for reactive dependencies so provider rebuilds when user changes
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('activePollsProvider: user is null, returning empty list');
    return <PollModel>[];
  }

  final repository = ref.read(pollRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For superadmin and bex, show all active polls without schoolId filter
  // For regular users, filter by their schoolId (county polls are always visible)
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  debugPrint('activePollsProvider: user=${user.fullName}, role=${user.role}, county=$effectiveCounty, schoolId=$effectiveSchoolId');

  try {
    final polls = await repository.getActivePolls(
      schoolId: effectiveSchoolId,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('activePollsProvider: timeout, returning empty list');
        return <PollModel>[];
      },
    );
    // Filter by visibility role
    final filtered = polls.where((p) => _canViewPoll(user.role, p.minVisibilityRole)).toList();
    debugPrint('activePollsProvider: returned ${filtered.length} polls (after visibility filter)');
    return filtered;
  } catch (e) {
    debugPrint('activePollsProvider: error $e');
    return <PollModel>[];
  }
});

/// Active polls stream for home screen (real-time updates)
final activePollsStreamProvider = StreamProvider<List<PollModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(<PollModel>[]);
  }

  final repository = ref.read(pollRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For superadmin and bex, show all active polls without schoolId filter
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  return repository.getActivePollsStream(
    schoolId: effectiveSchoolId,
    countyId: effectiveCounty,
    limit: 5,
  ).map((polls) {
    // Filter by visibility role
    return polls.where((p) => _canViewPoll(user.role, p.minVisibilityRole)).toList();
  });
});

/// Check if user has voted on a poll
final hasVotedProvider = FutureProvider.family<bool, String>((ref, pollId) async {
  final repository = ref.read(pollRepositoryProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return false;
  return repository.hasUserVoted(pollId, user.id);
});

/// Get all votes for a poll (for admin visibility on non-anonymous polls)
final pollVotesProvider = FutureProvider.family<List<PollVote>, String>((ref, pollId) async {
  final repository = ref.watch(pollRepositoryProvider);
  return repository.getVotes(pollId);
});

/// Poll votes stream for real-time updates
final pollVotesStreamProvider = StreamProvider.family<List<PollVote>, String>((ref, pollId) {
  final repository = ref.watch(pollRepositoryProvider);
  return repository.getVotesStream(pollId);
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
  /// - schoolId/schoolName: Optional overrides for BEX/Superadmin to create polls for specific schools
  /// - minVisibilityRole: Optional minimum role required to view this poll (null = visible to all)
  Future<String?> createPoll({
    required String question,
    String? description,
    required PollType type,
    required List<PollOption> options,
    bool isAnonymous = true,
    bool allowMultipleVotes = false,
    required DateTime startDate,
    required DateTime endDate,
    String? schoolId,
    String? schoolName,
    UserRole? minVisibilityRole,
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

    // Determine school ID and name for school polls
    // - If schoolId is provided (BEX/Superadmin selected specific school), use it
    // - Otherwise, use the current user's school
    final effectiveSchoolId = type == PollType.school
        ? (schoolId ?? user.schoolId)
        : null;
    final effectiveSchoolName = type == PollType.school
        ? (schoolName ?? user.schoolName)
        : null;

    // Translate content to both languages (with timeout to prevent hanging)
    Map<String, String>? questionTranslations;
    Map<String, String>? descriptionTranslations;
    List<PollOption> translatedOptions = options;

    debugPrint('PollController: Starting translation...');
    try {
      // Add 10 second timeout to entire translation process
      await Future<void>(() async {
        final translatedQuestion = await TranslatableContent.fromText(question);
        questionTranslations = {'en': translatedQuestion.en, 'ro': translatedQuestion.ro};

        if (description != null && description.isNotEmpty) {
          final translatedDescription = await TranslatableContent.fromText(description);
          descriptionTranslations = {'en': translatedDescription.en, 'ro': translatedDescription.ro};
        }

        // Translate each option
        translatedOptions = await Future.wait(options.map((option) async {
          final translatedText = await TranslatableContent.fromText(option.text);
          return option.copyWith(
            textTranslations: {'en': translatedText.en, 'ro': translatedText.ro},
          );
        }));
      }).timeout(const Duration(seconds: 10));

      debugPrint('PollController: Content translated successfully');
    } catch (e) {
      debugPrint('PollController: Translation failed/timeout - $e, continuing without translations');
      // Continue without translations if translation fails or times out
    }

    final poll = PollModel(
      id: '',
      question: question,
      description: description,
      questionTranslations: questionTranslations,
      descriptionTranslations: descriptionTranslations,
      type: type,
      options: translatedOptions,
      createdById: user.id,
      createdByName: user.fullName,
      countyId: user.city, // Save the county for data partitioning (city is the county name)
      schoolId: effectiveSchoolId,
      schoolName: effectiveSchoolName,
      isAnonymous: isAnonymous,
      allowMultipleVotes: allowMultipleVotes,
      startDate: startDate,
      endDate: endDate,
      minVisibilityRole: minVisibilityRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createPoll(poll);

    if (id != null) {
      state = const AsyncValue.data(null);
      _ref.invalidate(pollsProvider);
      _ref.invalidate(activePollsProvider);

      // Log activity
      final activityRepo = _ref.read(activityRepositoryProvider);
      await activityRepo.logPollCreated(
        pollId: id,
        pollQuestion: question,
        createdBy: user.fullName,
      );
      _ref.invalidate(recentActivitiesProvider);
    } else {
      state = AsyncValue.error('Failed to create poll', StackTrace.current);
    }

    return id;
  }

  /// Vote on poll - ALL users (including students) can vote if poll allows
  Future<bool> vote(String pollId, String optionId) async {
    return voteMultiple(pollId, [optionId]);
  }

  /// Vote on poll with multiple options (for polls with allowMultipleVotes)
  Future<bool> voteMultiple(String pollId, List<String> optionIds) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    final success = await _repository.voteMultiple(
      pollId: pollId,
      optionIds: optionIds,
      oderId: user.id,
      voterName: user.fullName,
      voterSchoolId: user.schoolId,
      voterSchoolName: user.schoolName,
    );

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(pollProvider(pollId));
      _ref.invalidate(hasVotedProvider(pollId));
      _ref.invalidate(pollVotesProvider(pollId));
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

/// Check if current user can create polls
/// SchoolRep can create school polls, Department can create department polls, BEX/Superadmin can create any
final canCreatePollsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can create county-level polls (BEX only)
final canCreateCountyPollsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Check if current user can create department-level polls
final canCreateDepartmentPollsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can vote on polls (all authenticated users can vote)
final canVoteOnPollsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
