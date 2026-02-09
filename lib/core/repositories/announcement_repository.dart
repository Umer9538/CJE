import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for announcement-related Firestore operations
class AnnouncementRepository {
  final FirebaseFirestore _firestore;

  AnnouncementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('announcements');

  /// Get all announcements (published only)
  Future<List<AnnouncementModel>> getAnnouncements({
    AnnouncementType? type,
    String? schoolId,
    String? countyId,
    int limit = 20,
  }) async {
    try {
      // Simple query without orderBy to avoid index requirement
      final snapshot = await _collection.get();

      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((a) => a.isPublished)
          .where((a) {
            // County filtering:
            // - Content with NULL countyId is visible to everyone (legacy/global content)
            // - Content with countyId is only visible to users from that county
            // - Uses flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
            if (countyId != null && countyId.isNotEmpty && a.countyId != null && a.countyId!.isNotEmpty) {
              final userCounty = countyId.toLowerCase();
              final announcementCounty = a.countyId!.toLowerCase();
              // Flexible match: one contains the other (handles "Cluj" vs "Cluj-Napoca")
              final isMatch = userCounty.contains(announcementCounty) ||
                              announcementCounty.contains(userCounty);
              if (!isMatch) return false;
            }
            // Type filtering
            if (type != null && a.type != type) return false;
            // School filtering - for school announcements, only show user's school
            // This applies both when type==school AND when type==null (All tab)
            if (a.type == AnnouncementType.school && schoolId != null && a.schoolId != schoolId) {
              return false;
            }
            return true;
          })
          .toList();

      // Sort: pinned first, then by publishedAt
      results.sort((a, b) {
        // Pinned announcements come first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // Then sort by publishedAt (newest first)
        return (b.publishedAt ?? b.createdAt)
            .compareTo(a.publishedAt ?? a.createdAt);
      });
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting announcements: $e');
      return [];
    }
  }

  /// Get announcements stream
  Stream<List<AnnouncementModel>> getAnnouncementsStream({
    AnnouncementType? type,
    String? schoolId,
    String? countyId,
    int limit = 20,
  }) {
    // Simple stream without composite queries
    return _collection.snapshots().map((snapshot) {
      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((a) => a.isPublished)
          .where((a) {
            // County filtering:
            // - Content with NULL countyId is visible to everyone (legacy/global content)
            // - Content with countyId is only visible to users from that county
            // - Uses flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
            if (countyId != null && countyId.isNotEmpty && a.countyId != null && a.countyId!.isNotEmpty) {
              final userCounty = countyId.toLowerCase();
              final announcementCounty = a.countyId!.toLowerCase();
              final isMatch = userCounty.contains(announcementCounty) ||
                              announcementCounty.contains(userCounty);
              if (!isMatch) return false;
            }
            // Type filtering
            if (type != null && a.type != type) return false;
            // School filtering - for school announcements, only show user's school
            // This applies both when type==school AND when type==null (All tab)
            if (a.type == AnnouncementType.school && schoolId != null && a.schoolId != schoolId) {
              return false;
            }
            return true;
          })
          .toList();

      // Sort: pinned first, then by publishedAt
      results.sort((a, b) {
        // Pinned announcements come first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // Then sort by publishedAt (newest first)
        return (b.publishedAt ?? b.createdAt)
            .compareTo(a.publishedAt ?? a.createdAt);
      });
      return results.take(limit).toList();
    });
  }

  /// Get announcement by ID
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    try {
      final doc = await _collection.doc(id).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Timeout getting announcement by ID: $id');
          throw Exception('Request timed out');
        },
      );
      if (doc.exists) {
        return AnnouncementModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting announcement: $e');
      return null;
    }
  }

  /// Create announcement
  Future<String?> createAnnouncement(AnnouncementModel announcement) async {
    try {
      final docRef = await _collection.add(announcement.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      return null;
    }
  }

  /// Update announcement
  /// Note: Uses partial update to preserve viewCount and other engagement data
  Future<bool> updateAnnouncement(AnnouncementModel announcement) async {
    try {
      // Use partial update to avoid overwriting viewCount and other counters
      await _collection.doc(announcement.id).update({
        'title': announcement.title,
        'content': announcement.content,
        'summary': announcement.summary,
        'titleTranslations': announcement.titleTranslations,
        'contentTranslations': announcement.contentTranslations,
        'summaryTranslations': announcement.summaryTranslations,
        'type': announcement.type.toFirestore(),
        'countyId': announcement.countyId,
        'schoolId': announcement.schoolId,
        'schoolName': announcement.schoolName,
        'imageUrl': announcement.imageUrl,
        'attachmentUrls': announcement.attachmentUrls,
        'tags': announcement.tags,
        'isPinned': announcement.isPinned,
        'isPublished': announcement.isPublished,
        'minVisibilityRole': announcement.minVisibilityRole?.toFirestore(),
        'updatedAt': Timestamp.now(),
        // Note: viewCount is intentionally NOT updated here to preserve engagement data
      });
      return true;
    } catch (e) {
      debugPrint('Error updating announcement: $e');
      return false;
    }
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      return false;
    }
  }

  /// Publish announcement
  Future<bool> publishAnnouncement(String id) async {
    try {
      await _collection.doc(id).update({
        'isPublished': true,
        'publishedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error publishing announcement: $e');
      return false;
    }
  }

  /// Unpublish announcement
  Future<bool> unpublishAnnouncement(String id) async {
    try {
      await _collection.doc(id).update({
        'isPublished': false,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error unpublishing announcement: $e');
      return false;
    }
  }

  /// Toggle pin status
  Future<bool> togglePinAnnouncement(String id, bool isPinned) async {
    try {
      await _collection.doc(id).update({
        'isPinned': isPinned,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      return false;
    }
  }

  /// Get user's draft announcements (unpublished)
  Future<List<AnnouncementModel>> getUserDrafts(String authorId) async {
    try {
      final snapshot = await _collection.get();

      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((a) => !a.isPublished && a.authorId == authorId)
          .toList();

      // Sort by createdAt descending (most recent first)
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      debugPrint('Error getting user drafts: $e');
      return [];
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String id) async {
    try {
      await _collection.doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  /// Get recent announcements for home screen
  Future<List<AnnouncementModel>> getRecentAnnouncements({
    String? schoolId,
    String? countyId,
    int limit = 5,
  }) async {
    try {
      // Get all announcements and filter in memory to avoid composite index requirement
      final snapshot = await _collection.get();

      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isPublished)
          .where((announcement) {
            // County filtering:
            // - Content with NULL countyId is visible to everyone (legacy/global content)
            // - Content with countyId is only visible to users from that county
            // - Uses flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
            if (countyId != null && countyId.isNotEmpty && announcement.countyId != null && announcement.countyId!.isNotEmpty) {
              final userCounty = countyId.toLowerCase();
              final announcementCounty = announcement.countyId!.toLowerCase();
              final isMatch = userCounty.contains(announcementCounty) ||
                              announcementCounty.contains(userCounty);
              if (!isMatch) return false;
            }
            // Include county announcements or school announcements matching user's school
            if (announcement.type == AnnouncementType.county) return true;
            if (announcement.type == AnnouncementType.school && schoolId != null) {
              return announcement.schoolId == schoolId;
            }
            return false;
          })
          .toList();

      // Sort: pinned first, then by publishedAt
      results.sort((a, b) {
        // Pinned announcements come first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // Then sort by publishedAt (newest first)
        return (b.publishedAt ?? b.createdAt)
            .compareTo(a.publishedAt ?? a.createdAt);
      });
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent announcements: $e');
      return [];
    }
  }

  /// Get recent announcements stream for home screen (real-time updates)
  Stream<List<AnnouncementModel>> getRecentAnnouncementsStream({
    String? schoolId,
    String? countyId,
    int limit = 5,
  }) {
    return _collection.snapshots().map((snapshot) {
      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isPublished)
          .where((announcement) {
            // County filtering
            if (countyId != null && countyId.isNotEmpty && announcement.countyId != null && announcement.countyId!.isNotEmpty) {
              final userCounty = countyId.toLowerCase();
              final announcementCounty = announcement.countyId!.toLowerCase();
              final isMatch = userCounty.contains(announcementCounty) ||
                              announcementCounty.contains(userCounty);
              if (!isMatch) return false;
            }
            // Include county announcements or school announcements matching user's school
            if (announcement.type == AnnouncementType.county) return true;
            if (announcement.type == AnnouncementType.school && schoolId != null) {
              return announcement.schoolId == schoolId;
            }
            return false;
          })
          .toList();

      // Sort: pinned first, then by publishedAt
      results.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return (b.publishedAt ?? b.createdAt)
            .compareTo(a.publishedAt ?? a.createdAt);
      });
      return results.take(limit).toList();
    });
  }
}
