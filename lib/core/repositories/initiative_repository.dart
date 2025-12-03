import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for initiative-related Firestore operations
class InitiativeRepository {
  final FirebaseFirestore _firestore;

  InitiativeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('initiatives');

  CollectionReference<Map<String, dynamic>> get _commentsCollection =>
      _firestore.collection('initiative_comments');

  /// Get all initiatives
  Future<List<InitiativeModel>> getInitiatives({
    InitiativeStatus? status,
    String? schoolId,
    String? authorId,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toFirestore());
      }

      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }

      if (authorId != null) {
        query = query.where('authorId', isEqualTo: authorId);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting initiatives: $e');
      return [];
    }
  }

  /// Get initiatives stream
  Stream<List<InitiativeModel>> getInitiativesStream({
    InitiativeStatus? status,
    String? schoolId,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toFirestore());
    }

    return query.limit(limit).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => InitiativeModel.fromFirestore(doc)).toList());
  }

  /// Get initiative by ID
  Future<InitiativeModel?> getInitiativeById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return InitiativeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting initiative: $e');
      return null;
    }
  }

  /// Create initiative
  Future<String?> createInitiative(InitiativeModel initiative) async {
    try {
      final docRef = await _collection.add(initiative.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating initiative: $e');
      return null;
    }
  }

  /// Update initiative
  Future<bool> updateInitiative(InitiativeModel initiative) async {
    try {
      await _collection.doc(initiative.id).update(
        initiative.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating initiative: $e');
      return false;
    }
  }

  /// Delete initiative
  Future<bool> deleteInitiative(String id) async {
    try {
      await _collection.doc(id).delete();
      // Also delete comments
      final commentsQuery = await _commentsCollection
          .where('initiativeId', isEqualTo: id)
          .get();
      for (var doc in commentsQuery.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting initiative: $e');
      return false;
    }
  }

  /// Update initiative status
  Future<bool> updateStatus(String id, InitiativeStatus status) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.toFirestore(),
        'updatedAt': Timestamp.now(),
      };

      // Set timestamp for status change
      switch (status) {
        case InitiativeStatus.submitted:
          updates['submittedAt'] = Timestamp.now();
          break;
        case InitiativeStatus.review:
          updates['reviewStartedAt'] = Timestamp.now();
          break;
        case InitiativeStatus.debate:
          updates['debateStartedAt'] = Timestamp.now();
          break;
        case InitiativeStatus.voting:
          updates['votingStartedAt'] = Timestamp.now();
          break;
        case InitiativeStatus.adopted:
        case InitiativeStatus.rejected:
          updates['votingEndedAt'] = Timestamp.now();
          break;
        default:
          break;
      }

      await _collection.doc(id).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating status: $e');
      return false;
    }
  }

  /// Support/unsupport initiative
  Future<bool> toggleSupport(String initiativeId, String userId) async {
    try {
      final doc = await _collection.doc(initiativeId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final supporterIds = List<String>.from(data['supporterIds'] ?? []);

      if (supporterIds.contains(userId)) {
        supporterIds.remove(userId);
      } else {
        supporterIds.add(userId);
      }

      await _collection.doc(initiativeId).update({
        'supporterIds': supporterIds,
        'supportCount': supporterIds.length,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling support: $e');
      return false;
    }
  }

  /// Check if user supports initiative
  Future<bool> isSupporting(String initiativeId, String userId) async {
    try {
      final doc = await _collection.doc(initiativeId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final supporterIds = List<String>.from(data['supporterIds'] ?? []);
      return supporterIds.contains(userId);
    } catch (e) {
      debugPrint('Error checking support: $e');
      return false;
    }
  }

  /// Vote on initiative
  Future<bool> vote(String initiativeId, String vote) async {
    try {
      String field;
      switch (vote) {
        case 'for':
          field = 'votesFor';
          break;
        case 'against':
          field = 'votesAgainst';
          break;
        case 'abstain':
          field = 'votesAbstain';
          break;
        default:
          return false;
      }

      await _collection.doc(initiativeId).update({
        field: FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error voting: $e');
      return false;
    }
  }

  /// Get recent initiatives for home screen
  Future<List<InitiativeModel>> getRecentInitiatives({
    String? schoolId,
    int limit = 5,
  }) async {
    try {
      // Simple query without whereIn to avoid composite index requirement
      // Filter statuses in memory instead
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Fetch more to account for filtering
          .get();

      final validStatuses = {
        InitiativeStatus.submitted.toFirestore(),
        InitiativeStatus.review.toFirestore(),
        InitiativeStatus.debate.toFirestore(),
        InitiativeStatus.voting.toFirestore(),
      };

      return snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .where((initiative) => validStatuses.contains(initiative.status.toFirestore()))
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('Error getting recent initiatives: $e');
      return [];
    }
  }

  /// Add comment to initiative
  Future<String?> addComment(InitiativeComment comment) async {
    try {
      final docRef = await _commentsCollection.add(comment.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  /// Get comments for initiative
  Future<List<InitiativeComment>> getComments(String initiativeId) async {
    try {
      final snapshot = await _commentsCollection
          .where('initiativeId', isEqualTo: initiativeId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => InitiativeComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  /// Get comments stream
  Stream<List<InitiativeComment>> getCommentsStream(String initiativeId) {
    return _commentsCollection
        .where('initiativeId', isEqualTo: initiativeId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InitiativeComment.fromFirestore(doc))
            .toList());
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  /// Reject initiative with reason
  Future<bool> rejectInitiative(String id, String reason) async {
    try {
      await _collection.doc(id).update({
        'status': InitiativeStatus.rejected.toFirestore(),
        'rejectionReason': reason,
        'votingEndedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error rejecting initiative: $e');
      return false;
    }
  }
}
