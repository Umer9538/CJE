import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/models.dart';
import '../constants/enums.dart';
import 'content_access.dart';

/// Repository for initiative-related Firestore operations
class InitiativeRepository {
  final FirebaseFirestore _firestore;

  InitiativeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('initiatives');

  Future<Query<Map<String, dynamic>>> _queryForCounty(String? countyId) =>
      ContentAccess(_firestore).query(_collection, countyId: countyId);

  CollectionReference<Map<String, dynamic>> get _commentsCollection =>
      _firestore.collection('initiative_comments');

  CollectionReference<Map<String, dynamic>> get _votesCollection =>
      _firestore.collection('initiative_votes');

  /// Get all initiatives
  Future<List<InitiativeModel>> getInitiatives({
    InitiativeStatus? status,
    String? schoolId,
    String? countyId,
    String? authorId,
    int limit = 20,
  }) async {
    try {
      // Get all initiatives and filter in memory to avoid composite index requirement
      final snapshot = await (await _queryForCounty(countyId)).get();

      List<InitiativeModel>
      initiatives = snapshot.docs.map((doc) => InitiativeModel.fromFirestore(doc)).where((
        i,
      ) {
        // County filtering:
        // - Content with NULL countyId is visible to everyone (legacy/global content)
        // - Content with countyId is only visible to users from that county
        // - Uses flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
        if (countyId != null &&
            countyId.isNotEmpty &&
            i.countyId != null &&
            i.countyId!.isNotEmpty) {
          final userCounty = countyId.toLowerCase();
          final initiativeCounty = i.countyId!.toLowerCase();
          final isMatch =
              userCounty.contains(initiativeCounty) ||
              initiativeCounty.contains(userCounty);
          if (!isMatch) return false;
        }
        if (status != null && i.status != status) return false;
        // School filtering:
        // - County-level initiatives (i.schoolId == null) are visible to all in this county
        // - School-specific initiatives are only visible to users from that school
        if (schoolId != null && i.schoolId != null && i.schoolId != schoolId) {
          return false;
        }
        if (authorId != null && i.authorId != authorId) return false;
        return true;
      }).toList();

      // Sort by createdAt descending
      initiatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return initiatives.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting initiatives: $e');
      return [];
    }
  }

  /// Get initiatives stream
  Stream<List<InitiativeModel>> getInitiativesStream({
    InitiativeStatus? status,
    String? schoolId,
    String? countyId,
    int limit = 20,
  }) {
    // Simple stream without composite queries
    return ContentAccess(
      _firestore,
    ).snapshots(_collection, countyId: countyId).map((snapshot) {
      List<InitiativeModel>
      initiatives = snapshot.docs.map((doc) => InitiativeModel.fromFirestore(doc)).where((
        i,
      ) {
        // County filtering:
        // - Content with NULL countyId is visible to everyone (legacy/global content)
        // - Content with countyId is only visible to users from that county
        // - Uses flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
        if (countyId != null &&
            countyId.isNotEmpty &&
            i.countyId != null &&
            i.countyId!.isNotEmpty) {
          final userCounty = countyId.toLowerCase();
          final initiativeCounty = i.countyId!.toLowerCase();
          final isMatch =
              userCounty.contains(initiativeCounty) ||
              initiativeCounty.contains(userCounty);
          if (!isMatch) return false;
        }
        if (status != null && i.status != status) return false;
        // School filtering:
        // - County-level initiatives (i.schoolId == null) are visible to all in this county
        // - School-specific initiatives are only visible to users from that school
        if (schoolId != null && i.schoolId != null && i.schoolId != schoolId) {
          return false;
        }
        return true;
      }).toList();

      // Sort by createdAt descending
      initiatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return initiatives.take(limit).toList();
    });
  }

  /// Get initiative by ID
  Future<InitiativeModel?> getInitiativeById(String id) async {
    try {
      final doc = await _collection
          .doc(id)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout getting initiative by ID: $id');
              throw Exception('Request timed out');
            },
          );
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
      debugPrint(
        'createInitiative: Starting - title="${initiative.title}", authorId=${initiative.authorId}',
      );
      final data = initiative.toFirestore();
      debugPrint('createInitiative: Data prepared, adding to Firestore...');
      final docRef = await _collection
          .add(data)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint(
                'createInitiative: TIMEOUT - Firestore write took too long',
              );
              throw Exception('Firestore write timeout');
            },
          );
      debugPrint('createInitiative: SUCCESS - docId=${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('createInitiative: ERROR - $e');
      debugPrint('createInitiative: Stack trace - $stackTrace');
      return null;
    }
  }

  /// Update initiative
  Future<bool> updateInitiative(InitiativeModel initiative) async {
    try {
      await _collection
          .doc(initiative.id)
          .update(initiative.copyWith(updatedAt: DateTime.now()).toFirestore());
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
      // Also delete votes
      final votesQuery = await _votesCollection
          .where('initiativeId', isEqualTo: id)
          .get();
      for (var doc in votesQuery.docs) {
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

  /// Update initiative voting settings (status and minimum voting role)
  Future<bool> updateInitiativeVotingSettings(
    String id,
    InitiativeStatus status,
    UserRole minimumVotingRole,
  ) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.toFirestore(),
        'minimumVotingRole': minimumVotingRole.toFirestore(),
        'votingStartedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _collection.doc(id).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating voting settings: $e');
      return false;
    }
  }

  /// Support/unsupport initiative
  Future<bool> toggleSupport(String initiativeId, String userId) async {
    try {
      if (initiativeId.isEmpty || userId.isEmpty) return false;

      final doc = await _collection.doc(initiativeId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

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
      if (initiativeId.isEmpty || userId.isEmpty) return false;

      final doc = await _collection.doc(initiativeId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final supporterIds = List<String>.from(data['supporterIds'] ?? []);
      return supporterIds.contains(userId);
    } catch (e) {
      debugPrint('Error checking support: $e');
      return false;
    }
  }

  /// Vote on initiative (with duplicate prevention and voter tracking)
  Future<bool> vote({
    required String initiativeId,
    required String voteType,
    required String voterId,
    required String voterName,
    String? voterSchoolId,
    String? voterSchoolName,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('castCouncilVote')
          .call({
            'kind': 'initiative',
            'id': initiativeId,
            'voteType': voteType,
          });
      return result.data['success'] == true;
    } catch (e) {
      debugPrint('Error voting: $e');
      return false;
    }
  }

  /// Get all votes for an initiative (for admin visibility)
  Future<List<InitiativeVote>> getVotes(String initiativeId) async {
    try {
      final snapshot = await _votesCollection
          .where('initiativeId', isEqualTo: initiativeId)
          .get();

      final votes = snapshot.docs
          .map((doc) => InitiativeVote.fromFirestore(doc))
          .toList();

      // Sort by createdAt descending
      votes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return votes;
    } catch (e) {
      debugPrint('Error getting votes: $e');
      return [];
    }
  }

  /// Get votes stream for an initiative
  Stream<List<InitiativeVote>> getVotesStream(String initiativeId) {
    return _votesCollection
        .where('initiativeId', isEqualTo: initiativeId)
        .snapshots()
        .map((snapshot) {
          final votes = snapshot.docs
              .map((doc) => InitiativeVote.fromFirestore(doc))
              .toList();
          votes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return votes;
        });
  }

  /// Check if user has voted on initiative
  Future<String?> getUserVote(String initiativeId, String userId) async {
    try {
      final snapshot = await _votesCollection
          .where('initiativeId', isEqualTo: initiativeId)
          .where('voterId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data()['voteType'] as String?;
    } catch (e) {
      debugPrint('Error getting user vote: $e');
      return null;
    }
  }

  /// Get recent initiatives for home screen
  Future<List<InitiativeModel>> getRecentInitiatives({
    String? schoolId,
    String? countyId,
    int limit = 5,
  }) async {
    try {
      // Get all initiatives and filter in memory to avoid composite index requirement
      final snapshot = await (await _queryForCounty(countyId)).get();
      debugPrint(
        'getRecentInitiatives: Total initiatives in DB: ${snapshot.docs.length}',
      );

      final validStatuses = {
        InitiativeStatus.submitted,
        InitiativeStatus.review,
        InitiativeStatus.debate,
        InitiativeStatus.voting,
      };

      List<InitiativeModel> initiatives = snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .toList();

      // Debug: show all initiatives before filtering
      for (var i in initiatives) {
        debugPrint(
          'getRecentInitiatives: Initiative "${i.title}" - status=${i.status}, countyId=${i.countyId}, schoolId=${i.schoolId}',
        );
      }

      initiatives = initiatives.where((initiative) {
        // County filtering:
        // - Content with NULL countyId is visible to everyone (legacy/global content)
        // - Content with countyId is only visible to users from that county
        // - Uses flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
        if (countyId != null &&
            countyId.isNotEmpty &&
            initiative.countyId != null &&
            initiative.countyId!.isNotEmpty) {
          final userCounty = countyId.toLowerCase();
          final initiativeCounty = initiative.countyId!.toLowerCase();
          final isMatch =
              userCounty.contains(initiativeCounty) ||
              initiativeCounty.contains(userCounty);
          if (!isMatch) return false;
        }
        if (!validStatuses.contains(initiative.status)) return false;
        // School filtering:
        // - County-level initiatives (schoolId == null) are visible to all in this county
        // - School-specific initiatives are only visible to users from that school
        if (schoolId != null &&
            initiative.schoolId != null &&
            initiative.schoolId != schoolId) {
          return false;
        }
        return true;
      }).toList();

      debugPrint(
        'getRecentInitiatives: After all filters (county: $countyId, schoolId: $schoolId): ${initiatives.length}',
      );

      // Sort by createdAt descending
      initiatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
        'getRecentInitiatives: Returning ${initiatives.take(limit).length} initiatives',
      );
      return initiatives.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent initiatives: $e');
      return [];
    }
  }

  /// Get recent initiatives stream for home screen (real-time updates)
  Stream<List<InitiativeModel>> getRecentInitiativesStream({
    String? schoolId,
    String? countyId,
    int limit = 5,
  }) {
    final validStatuses = {
      InitiativeStatus.submitted,
      InitiativeStatus.review,
      InitiativeStatus.debate,
      InitiativeStatus.voting,
    };

    return ContentAccess(
      _firestore,
    ).snapshots(_collection, countyId: countyId).map((snapshot) {
      List<InitiativeModel> initiatives = snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .where((initiative) {
            // County filtering
            if (countyId != null &&
                countyId.isNotEmpty &&
                initiative.countyId != null &&
                initiative.countyId!.isNotEmpty) {
              final userCounty = countyId.toLowerCase();
              final initiativeCounty = initiative.countyId!.toLowerCase();
              final isMatch =
                  userCounty.contains(initiativeCounty) ||
                  initiativeCounty.contains(userCounty);
              if (!isMatch) return false;
            }
            if (!validStatuses.contains(initiative.status)) return false;
            // School filtering
            if (schoolId != null &&
                initiative.schoolId != null &&
                initiative.schoolId != schoolId) {
              return false;
            }
            return true;
          })
          .toList();

      // Sort by createdAt descending
      initiatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return initiatives.take(limit).toList();
    });
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
      // Scope the Firestore query to the parent initiative. Loading every
      // county's comments and filtering on-device is rejected by the
      // county-isolation rules and exposes more data than this screen needs.
      final snapshot = await _commentsCollection
          .where('initiativeId', isEqualTo: initiativeId)
          .get();
      final comments = snapshot.docs
          .map((doc) => InitiativeComment.fromFirestore(doc))
          .toList();

      // Sort by createdAt ascending
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  /// Get comments stream
  Stream<List<InitiativeComment>> getCommentsStream(
    String initiativeId,
  ) async* {
    // Guard: return empty stream if no initiative ID
    if (initiativeId.isEmpty) {
      yield <InitiativeComment>[];
      return;
    }

    try {
      // Keep the live query scoped to the selected initiative for the same
      // security-rule and data-minimisation reasons as getComments().
      await for (final snapshot
          in _commentsCollection
              .where('initiativeId', isEqualTo: initiativeId)
              .snapshots()) {
        final comments = snapshot.docs
            .map((doc) => InitiativeComment.fromFirestore(doc))
            .toList();

        // Sort by createdAt ascending
        comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        yield comments;
      }
    } catch (e) {
      debugPrint('Error in comments stream: $e');
      yield <InitiativeComment>[];
    }
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
