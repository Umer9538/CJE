import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/repositories.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Announcement repository provider
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

/// Announcements list provider
final announcementsProvider = FutureProvider.family<List<AnnouncementModel>, AnnouncementFilter>((ref, filter) async {
  final repository = ref.watch(announcementRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  try {
    return await repository.getAnnouncements(
      type: filter.type,
      schoolId: filter.type == AnnouncementType.school ? user?.schoolId : null,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => <AnnouncementModel>[],
    );
  } catch (e) {
    return <AnnouncementModel>[];
  }
});

/// Announcements stream provider
final announcementsStreamProvider = StreamProvider.family<List<AnnouncementModel>, AnnouncementFilter>((ref, filter) {
  final repository = ref.watch(announcementRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  return repository.getAnnouncementsStream(
    type: filter.type,
    schoolId: filter.type == AnnouncementType.school ? user?.schoolId : null,
    limit: filter.limit,
  );
});

/// Single announcement provider
final announcementProvider = FutureProvider.family<AnnouncementModel?, String>((ref, id) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return repository.getAnnouncementById(id);
});

/// Recent announcements for home screen
final recentAnnouncementsProvider = FutureProvider<List<AnnouncementModel>>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  try {
    return await repository.getRecentAnnouncements(
      schoolId: user?.schoolId,
      limit: 5,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <AnnouncementModel>[],
    );
  } catch (e) {
    return <AnnouncementModel>[];
  }
});

/// Filter model for announcements
class AnnouncementFilter {
  final AnnouncementType? type;
  final int limit;

  const AnnouncementFilter({
    this.type,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          limit == other.limit;

  @override
  int get hashCode => type.hashCode ^ limit.hashCode;
}

/// Announcement controller for CRUD operations
class AnnouncementController extends StateNotifier<AsyncValue<void>> {
  final AnnouncementRepository _repository;
  final Ref _ref;

  AnnouncementController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Create new announcement
  Future<String?> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementType type,
    String? summary,
    String? imageUrl,
    List<String>? attachmentUrls,
    List<String>? tags,
    bool publishImmediately = false,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    final announcement = AnnouncementModel(
      id: '',
      title: title,
      content: content,
      summary: summary,
      type: type,
      authorId: user.id,
      authorName: user.fullName,
      authorPhotoUrl: user.photoUrl,
      schoolId: type == AnnouncementType.school ? user.schoolId : null,
      schoolName: type == AnnouncementType.school ? user.schoolName : null,
      imageUrl: imageUrl,
      attachmentUrls: attachmentUrls ?? [],
      tags: tags ?? [],
      isPublished: publishImmediately,
      publishedAt: publishImmediately ? DateTime.now() : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createAnnouncement(announcement);

    if (id != null) {
      state = const AsyncValue.data(null);
      // Invalidate cache
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(recentAnnouncementsProvider);
    } else {
      state = AsyncValue.error('Failed to create announcement', StackTrace.current);
    }

    return id;
  }

  /// Update announcement
  Future<bool> updateAnnouncement(AnnouncementModel announcement) async {
    state = const AsyncValue.loading();

    final success = await _repository.updateAnnouncement(announcement);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(announcementProvider(announcement.id));
    } else {
      state = AsyncValue.error('Failed to update announcement', StackTrace.current);
    }

    return success;
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(String id) async {
    state = const AsyncValue.loading();

    final success = await _repository.deleteAnnouncement(id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(recentAnnouncementsProvider);
    } else {
      state = AsyncValue.error('Failed to delete announcement', StackTrace.current);
    }

    return success;
  }

  /// Publish announcement
  Future<bool> publishAnnouncement(String id) async {
    final success = await _repository.publishAnnouncement(id);
    if (success) {
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(announcementProvider(id));
    }
    return success;
  }

  /// Toggle pin status
  Future<bool> togglePin(String id, bool isPinned) async {
    final success = await _repository.togglePinAnnouncement(id, isPinned);
    if (success) {
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(announcementProvider(id));
    }
    return success;
  }

  /// Track view
  Future<void> trackView(String id) async {
    await _repository.incrementViewCount(id);
  }
}

/// Announcement controller provider
final announcementControllerProvider =
    StateNotifierProvider<AnnouncementController, AsyncValue<void>>((ref) {
  return AnnouncementController(
    ref.watch(announcementRepositoryProvider),
    ref,
  );
});
