import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';

/// Repository for activity-related Firestore operations
class ActivityRepository {
  final FirebaseFirestore _firestore;

  ActivityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('activities');

  /// Get recent activities
  Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    try {
      final snapshot = await _collection.get();

      List<ActivityModel> results = snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc))
          .toList();

      // Sort by createdAt in memory (descending - newest first)
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent activities: $e');
      return [];
    }
  }

  /// Get activities stream
  Stream<List<ActivityModel>> getActivitiesStream({int limit = 10}) {
    return _collection.snapshots().map((snapshot) {
      List<ActivityModel> results = snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc))
          .toList();

      // Sort by createdAt in memory (descending - newest first)
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results.take(limit).toList();
    });
  }

  /// Log activity (create new activity record)
  Future<String?> logActivity(ActivityModel activity) async {
    try {
      final docRef = await _collection.add(activity.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error logging activity: $e');
      return null;
    }
  }

  /// Log user registration activity
  Future<void> logUserRegistered({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.userRegistered,
      title: 'New user registered',
      subtitle: '$userName joined as $userRole',
      targetId: userId,
      targetType: 'user',
      createdAt: DateTime.now(),
    ));
  }

  /// Log user approved activity
  Future<void> logUserApproved({
    required String userId,
    required String userName,
    String? approvedBy,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.userApproved,
      title: 'User approved',
      subtitle: '$userName account activated',
      targetId: userId,
      targetType: 'user',
      actorName: approvedBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Log announcement published activity
  Future<void> logAnnouncementPublished({
    required String announcementId,
    required String announcementTitle,
    String? publishedBy,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.announcementPublished,
      title: 'Announcement published',
      subtitle: announcementTitle,
      targetId: announcementId,
      targetType: 'announcement',
      actorName: publishedBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Log poll created activity
  Future<void> logPollCreated({
    required String pollId,
    required String pollQuestion,
    String? createdBy,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.pollCreated,
      title: 'Poll created',
      subtitle: pollQuestion,
      targetId: pollId,
      targetType: 'poll',
      actorName: createdBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Log poll ended activity
  Future<void> logPollEnded({
    required String pollId,
    required String pollQuestion,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.pollEnded,
      title: 'Poll ended',
      subtitle: pollQuestion,
      targetId: pollId,
      targetType: 'poll',
      createdAt: DateTime.now(),
    ));
  }

  /// Log meeting created activity
  Future<void> logMeetingCreated({
    required String meetingId,
    required String meetingTitle,
    String? createdBy,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.meetingCreated,
      title: 'Meeting scheduled',
      subtitle: meetingTitle,
      targetId: meetingId,
      targetType: 'meeting',
      actorName: createdBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Log initiative submitted activity
  Future<void> logInitiativeSubmitted({
    required String initiativeId,
    required String initiativeTitle,
    String? submittedBy,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.initiativeSubmitted,
      title: 'Initiative submitted',
      subtitle: initiativeTitle,
      targetId: initiativeId,
      targetType: 'initiative',
      actorName: submittedBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Log document uploaded activity
  Future<void> logDocumentUploaded({
    required String documentId,
    required String documentTitle,
    String? uploadedBy,
  }) async {
    await logActivity(ActivityModel(
      id: '',
      type: ActivityType.documentUploaded,
      title: 'Document uploaded',
      subtitle: documentTitle,
      targetId: documentId,
      targetType: 'document',
      actorName: uploadedBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Delete old activities (cleanup - keep last 100)
  Future<void> cleanupOldActivities() async {
    try {
      final snapshot = await _collection.get();

      if (snapshot.docs.length > 100) {
        List<QueryDocumentSnapshot> docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          return (bTime?.toDate() ?? DateTime.now())
              .compareTo(aTime?.toDate() ?? DateTime.now());
        });

        // Delete all except the most recent 100
        final toDelete = docs.skip(100);
        final batch = _firestore.batch();
        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error cleaning up activities: $e');
    }
  }
}
