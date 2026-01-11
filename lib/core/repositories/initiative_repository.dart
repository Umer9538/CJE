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
      final snapshot = await _collection.get();

      List<InitiativeModel> initiatives = snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .where((i) {
            // County filtering:
            // - Content with NULL countyId is visible to everyone (legacy/global content)
            // - Content with countyId is only visible to users from that county
            if (countyId != null && countyId.isNotEmpty && i.countyId != null && i.countyId!.isNotEmpty) {
              if (i.countyId != countyId) return false;
            }
            if (status != null && i.status != status) return false;
            // School filtering:
            // - County-level initiatives (i.schoolId == null) are visible to all in this county
            // - School-specific initiatives are only visible to users from that school
            if (schoolId != null && i.schoolId != null && i.schoolId != schoolId) return false;
            if (authorId != null && i.authorId != authorId) return false;
            return true;
          })
          .toList();

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
    return _collection.snapshots().map((snapshot) {
      List<InitiativeModel> initiatives = snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .where((i) {
            // County filtering:
            // - Content with NULL countyId is visible to everyone (legacy/global content)
            // - Content with countyId is only visible to users from that county
            if (countyId != null && countyId.isNotEmpty && i.countyId != null && i.countyId!.isNotEmpty) {
              if (i.countyId != countyId) return false;
            }
            if (status != null && i.status != status) return false;
            // School filtering:
            // - County-level initiatives (i.schoolId == null) are visible to all in this county
            // - School-specific initiatives are only visible to users from that school
            if (schoolId != null && i.schoolId != null && i.schoolId != schoolId) return false;
            return true;
          })
          .toList();

      // Sort by createdAt descending
      initiatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return initiatives.take(limit).toList();
    });
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
      // Check if user already voted
      final existingVote = await _votesCollection
          .where('initiativeId', isEqualTo: initiativeId)
          .where('voterId', isEqualTo: voterId)
          .get();

      String field;
      switch (voteType) {
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

      if (existingVote.docs.isNotEmpty) {
        // User already voted - update their vote
        final oldVote = existingVote.docs.first;
        final oldVoteType = oldVote.data()['voteType'] as String;

        if (oldVoteType == voteType) {
          // Same vote, no change needed
          return true;
        }

        // Decrement old vote count
        String oldField;
        switch (oldVoteType) {
          case 'for':
            oldField = 'votesFor';
            break;
          case 'against':
            oldField = 'votesAgainst';
            break;
          case 'abstain':
            oldField = 'votesAbstain';
            break;
          default:
            oldField = '';
        }

        // Update vote record
        await oldVote.reference.update({
          'voteType': voteType,
          'createdAt': Timestamp.now(),
        });

        // Update initiative counts (decrement old, increment new)
        if (oldField.isNotEmpty) {
          await _collection.doc(initiativeId).update({
            oldField: FieldValue.increment(-1),
            field: FieldValue.increment(1),
            'updatedAt': Timestamp.now(),
          });
        }
      } else {
        // New vote - create vote record
        final vote = InitiativeVote(
          id: '',
          initiativeId: initiativeId,
          voterId: voterId,
          voterName: voterName,
          voterSchoolId: voterSchoolId,
          voterSchoolName: voterSchoolName,
          voteType: voteType,
          createdAt: DateTime.now(),
        );

        await _votesCollection.add(vote.toFirestore());

        // Increment vote count
        await _collection.doc(initiativeId).update({
          field: FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      }

      return true;
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
      final snapshot = await _collection.get();

      final validStatuses = {
        InitiativeStatus.submitted,
        InitiativeStatus.review,
        InitiativeStatus.debate,
        InitiativeStatus.voting,
      };

      List<InitiativeModel> initiatives = snapshot.docs
          .map((doc) => InitiativeModel.fromFirestore(doc))
          .where((initiative) {
            // County filtering:
            // - Content with NULL countyId is visible to everyone (legacy/global content)
            // - Content with countyId is only visible to users from that county
            if (countyId != null && countyId.isNotEmpty && initiative.countyId != null && initiative.countyId!.isNotEmpty) {
              if (initiative.countyId != countyId) return false;
            }
            if (!validStatuses.contains(initiative.status)) return false;
            // School filtering:
            // - County-level initiatives (schoolId == null) are visible to all in this county
            // - School-specific initiatives are only visible to users from that school
            if (schoolId != null && initiative.schoolId != null && initiative.schoolId != schoolId) return false;
            return true;
          })
          .toList();

      // Sort by createdAt descending
      initiatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return initiatives.take(limit).toList();
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
      // Get all comments and filter in memory to avoid composite index requirement
      final snapshot = await _commentsCollection.get();
      final comments = snapshot.docs
          .map((doc) => InitiativeComment.fromFirestore(doc))
          .where((c) => c.initiativeId == initiativeId)
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
  Stream<List<InitiativeComment>> getCommentsStream(String initiativeId) async* {
    try {
      // Simple stream without composite queries
      await for (final snapshot in _commentsCollection.snapshots()) {
        final comments = snapshot.docs
            .map((doc) => InitiativeComment.fromFirestore(doc))
            .where((c) => c.initiativeId == initiativeId)
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
