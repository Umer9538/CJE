import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/repositories.dart';
import '../../core/constants/enums.dart';
import '../../core/services/translation_service.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';
import '../admin/admin_controller.dart';
import '../notifications/notification_controller.dart';

/// Announcement repository provider
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

/// Announcements list provider
final announcementsProvider = FutureProvider.family<List<AnnouncementModel>, AnnouncementFilter>((ref, filter) async {
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return <AnnouncementModel>[];
  }

  final repository = ref.read(announcementRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For superadmin and bex, show all school announcements without schoolId filter
  // For regular users, filter by their schoolId
  final shouldFilterBySchool = filter.type == AnnouncementType.school &&
      user.role != UserRole.superadmin &&
      user.role != UserRole.bex;

  try {
    return await repository.getAnnouncements(
      type: filter.type,
      schoolId: shouldFilterBySchool ? user.schoolId : null,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
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
  final repository = ref.read(announcementRepositoryProvider);
  final user = ref.read(currentUserProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For superadmin and bex, show all school announcements without schoolId filter
  // For regular users, filter by their schoolId
  final shouldFilterBySchool = filter.type == AnnouncementType.school &&
      user?.role != UserRole.superadmin &&
      user?.role != UserRole.bex;

  return repository.getAnnouncementsStream(
    type: filter.type,
    schoolId: shouldFilterBySchool ? user?.schoolId : null,
    countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
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
  final user = ref.read(currentUserProvider); // Use read to avoid rebuilds
  if (user == null) {
    return <AnnouncementModel>[];
  }

  final repository = ref.read(announcementRepositoryProvider);
  final effectiveCounty = ref.watch(effectiveCountyProvider);

  // For BEX/Superadmin, don't filter by school - they see ALL recent announcements
  final shouldFilterBySchool = user.role != UserRole.superadmin && user.role != UserRole.bex;
  final effectiveSchoolId = shouldFilterBySchool ? user.schoolId : null;

  try {
    return await repository.getRecentAnnouncements(
      schoolId: effectiveSchoolId,
      countyId: effectiveCounty, // Uses selected county for Superadmin, user's county for others
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
  /// - BEX and Superadmin can create county and school announcements
  /// - SchoolRep can only create school announcements
  /// - Other roles cannot create announcements
  /// - schoolId/schoolName: Optional overrides for BEX/Superadmin to create announcements for specific schools
  Future<String?> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementType type,
    String? summary,
    String? imageUrl,
    List<String>? attachmentUrls,
    List<String>? tags,
    bool publishImmediately = false,
    String? schoolId,
    String? schoolName,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    // Permission check
    // - BEX and Superadmin can create any announcement
    // - SchoolRep can only create school announcements
    if (type == AnnouncementType.county) {
      if (user.role != UserRole.bex && user.role != UserRole.superadmin) {
        state = AsyncValue.error('Permission denied: Only BEX can create county announcements', StackTrace.current);
        return null;
      }
    } else {
      // School announcement
      if (user.role != UserRole.schoolRep &&
          user.role != UserRole.bex &&
          user.role != UserRole.superadmin) {
        state = AsyncValue.error('Permission denied', StackTrace.current);
        return null;
      }
    }

    // Determine school ID and name
    // - If schoolId is provided (BEX/Superadmin selected specific school), use it
    // - Otherwise, use the current user's school (for SchoolRep)
    final effectiveSchoolId = type == AnnouncementType.school
        ? (schoolId ?? user.schoolId)
        : null;
    final effectiveSchoolName = type == AnnouncementType.school
        ? (schoolName ?? user.schoolName)
        : null;

    // Translate content to both languages
    Map<String, String>? titleTranslations;
    Map<String, String>? contentTranslations;
    Map<String, String>? summaryTranslations;

    try {
      final translatedTitle = await TranslatableContent.fromText(title);
      titleTranslations = {'en': translatedTitle.en, 'ro': translatedTitle.ro};

      final translatedContent = await TranslatableContent.fromText(content);
      contentTranslations = {'en': translatedContent.en, 'ro': translatedContent.ro};

      if (summary != null && summary.isNotEmpty) {
        final translatedSummary = await TranslatableContent.fromText(summary);
        summaryTranslations = {'en': translatedSummary.en, 'ro': translatedSummary.ro};
      }
      debugPrint('AnnouncementController: Content translated successfully');
    } catch (e) {
      debugPrint('AnnouncementController: Translation failed - $e');
      // Continue without translations if translation fails
    }

    final announcement = AnnouncementModel(
      id: '',
      title: title,
      content: content,
      summary: summary,
      titleTranslations: titleTranslations,
      contentTranslations: contentTranslations,
      summaryTranslations: summaryTranslations,
      type: type,
      authorId: user.id,
      authorName: user.fullName,
      authorPhotoUrl: user.photoUrl,
      countyId: user.city, // Save the county for data partitioning (city is the county name)
      schoolId: effectiveSchoolId,
      schoolName: effectiveSchoolName,
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

      // Log activity if published immediately
      if (publishImmediately) {
        final activityRepo = _ref.read(activityRepositoryProvider);
        await activityRepo.logAnnouncementPublished(
          announcementId: id,
          announcementTitle: title,
          publishedBy: user.fullName,
        );
        _ref.invalidate(recentActivitiesProvider);

        // Send automatic notification for published announcement
        await _sendAnnouncementNotification(
          title: title,
          summary: summary ?? content,
          type: type,
          schoolId: type == AnnouncementType.school ? user.schoolId : null,
          announcementId: id,
        );
      }
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
    // Get announcement title before publishing for logging
    final announcement = await _repository.getAnnouncementById(id);

    final success = await _repository.publishAnnouncement(id);
    if (success) {
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(announcementProvider(id));

      // Log activity
      if (announcement != null) {
        final activityRepo = _ref.read(activityRepositoryProvider);
        final user = _ref.read(currentUserProvider);
        await activityRepo.logAnnouncementPublished(
          announcementId: id,
          announcementTitle: announcement.title,
          publishedBy: user?.fullName,
        );
        _ref.invalidate(recentActivitiesProvider);

        // Send automatic notification for published announcement
        await _sendAnnouncementNotification(
          title: announcement.title,
          summary: announcement.summary ?? announcement.content,
          type: announcement.type,
          schoolId: announcement.schoolId,
          announcementId: id,
        );
      }
    }
    return success;
  }

  /// Send notification for a new announcement
  Future<void> _sendAnnouncementNotification({
    required String title,
    required String summary,
    required AnnouncementType type,
    String? schoolId,
    required String announcementId,
  }) async {
    try {
      final notificationRepo = _ref.read(notificationRepositoryProvider);
      final user = _ref.read(currentUserProvider);

      // Truncate summary for notification body
      final notificationBody = summary.length > 100
          ? '${summary.substring(0, 100)}...'
          : summary;

      await notificationRepo.sendCountyWideNotification(
        title: 'New Announcement: $title',
        body: notificationBody,
        type: NotificationType.newAnnouncement,
        schoolId: type == AnnouncementType.school ? schoolId : null,
        senderId: user?.id ?? '',
        senderName: user?.fullName ?? 'System',
        additionalData: {'announcementId': announcementId},
      );

      debugPrint('Sent notification for announcement: $title');
    } catch (e) {
      debugPrint('Error sending announcement notification: $e');
    }
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

/// Check if current user can create/publish announcements
/// - BEX and Superadmin can create county and school announcements
/// - SchoolRep can only create school announcements
final canCreateAnnouncementsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can create county-level announcements
final canCreateCountyAnnouncementsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Check if current user can create school-level announcements
final canCreateSchoolAnnouncementsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});
