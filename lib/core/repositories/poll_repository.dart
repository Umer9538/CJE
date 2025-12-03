import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for poll-related Firestore operations
class PollRepository {
  final FirebaseFirestore _firestore;

  PollRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('polls');

  /// Get all polls
  Future<List<PollModel>> getPolls({
    PollType? type,
    String? schoolId,
    bool activeOnly = false,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toFirestore());
      }

      final snapshot = await query.limit(limit).get();

      List<PollModel> polls = snapshot.docs
          .map((doc) => PollModel.fromFirestore(doc))
          .toList();

      // Filter active polls if needed
      if (activeOnly) {
        polls = polls.where((p) => p.isActive).toList();
      }

      // Filter by school if needed
      if (schoolId != null) {
        polls = polls.where((p) =>
            p.type == PollType.county || p.schoolId == schoolId).toList();
      }

      return polls;
    } catch (e) {
      debugPrint('Error getting polls: $e');
      return [];
    }
  }

  /// Get polls stream
  Stream<List<PollModel>> getPollsStream({
    PollType? type,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .orderBy('createdAt', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.toFirestore());
    }

    return query.limit(limit).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PollModel.fromFirestore(doc)).toList());
  }

  /// Get poll by ID
  Future<PollModel?> getPollById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return PollModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting poll: $e');
      return null;
    }
  }

  /// Create poll
  Future<String?> createPoll(PollModel poll) async {
    try {
      final docRef = await _collection.add(poll.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating poll: $e');
      return null;
    }
  }

  /// Update poll
  Future<bool> updatePoll(PollModel poll) async {
    try {
      await _collection.doc(poll.id).update(
        poll.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating poll: $e');
      return false;
    }
  }

  /// Delete poll
  Future<bool> deletePoll(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting poll: $e');
      return false;
    }
  }

  /// Vote on poll
  Future<bool> vote(String pollId, String optionId, String oderId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final docRef = _collection.doc(pollId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) return false;

        final poll = PollModel.fromFirestore(snapshot);

        // Check if user already voted
        if (poll.voterIds.contains(oderId)) {
          debugPrint('User already voted');
          return false;
        }

        // Check if poll is active
        if (!poll.isActive) {
          debugPrint('Poll is not active');
          return false;
        }

        // Update option vote count
        final updatedOptions = poll.options.map((option) {
          if (option.id == optionId) {
            return option.copyWith(voteCount: option.voteCount + 1);
          }
          return option;
        }).toList();

        // Update poll
        transaction.update(docRef, {
          'options': updatedOptions.map((o) => o.toMap()).toList(),
          'totalVotes': poll.totalVotes + 1,
          'voterIds': [...poll.voterIds, oderId],
          'updatedAt': Timestamp.now(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error voting: $e');
      return false;
    }
  }

  /// Check if user has voted
  Future<bool> hasUserVoted(String pollId, String oderId) async {
    try {
      final doc = await _collection.doc(pollId).get();
      if (!doc.exists) return false;

      final poll = PollModel.fromFirestore(doc);
      return poll.voterIds.contains(oderId);
    } catch (e) {
      debugPrint('Error checking vote: $e');
      return false;
    }
  }

  /// Get active polls for home screen
  Future<List<PollModel>> getActivePolls({
    String? schoolId,
    int limit = 5,
  }) async {
    try {
      final snapshot = await _collection
          .orderBy('endDate', descending: false)
          .limit(limit * 2)
          .get();

      List<PollModel> polls = snapshot.docs
          .map((doc) => PollModel.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();

      // Filter by school if needed
      if (schoolId != null) {
        polls = polls.where((p) =>
            p.type == PollType.county || p.schoolId == schoolId).toList();
      }

      return polls.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting active polls: $e');
      return [];
    }
  }
}
