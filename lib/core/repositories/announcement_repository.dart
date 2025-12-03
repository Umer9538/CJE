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
    int limit = 20,
  }) async {
    try {
      // Simple query to avoid composite index requirement
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Fetch more to account for filtering
          .get();

      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((a) => a.isPublished)
          .where((a) {
            if (type != null && a.type != type) return false;
            if (type == AnnouncementType.school && schoolId != null) {
              return a.schoolId == schoolId;
            }
            return true;
          })
          .toList();

      // Sort by publishedAt and limit
      results.sort((a, b) => (b.publishedAt ?? b.createdAt)
          .compareTo(a.publishedAt ?? a.createdAt));
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
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.toFirestore());
    }

    return query.limit(limit).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList());
  }

  /// Get announcement by ID
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
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
  Future<bool> updateAnnouncement(AnnouncementModel announcement) async {
    try {
      await _collection.doc(announcement.id).update(
        announcement.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
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
    int limit = 5,
  }) async {
    try {
      // Simple query to avoid composite index requirement
      // Filter in memory instead of using multiple where clauses
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Fetch more to account for filtering
          .get();

      List<AnnouncementModel> results = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isPublished)
          .where((announcement) {
            // Include county announcements or school announcements matching user's school
            if (announcement.type == AnnouncementType.county) return true;
            if (announcement.type == AnnouncementType.school && schoolId != null) {
              return announcement.schoolId == schoolId;
            }
            return false;
          })
          .toList();

      // Sort by publishedAt and limit
      results.sort((a, b) => (b.publishedAt ?? b.createdAt)
          .compareTo(a.publishedAt ?? a.createdAt));
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent announcements: $e');
      return [];
    }
  }
}
