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

  CollectionReference<Map<String, dynamic>> get _votesCollection =>
      _firestore.collection('poll_votes');

  /// Get all polls
  Future<List<PollModel>> getPolls({
    PollType? type,
    String? schoolId,
    String? countyId,
    bool activeOnly = false,
    int limit = 20,
  }) async {
    try {
      // Get all polls and filter in memory to avoid composite index requirement
      final snapshot = await _collection.get();

      List<PollModel> polls = snapshot.docs
          .map((doc) => PollModel.fromFirestore(doc))
          .toList();

      // County filtering:
      // - Content with NULL countyId is visible to everyone (legacy/global content)
      // - Content with countyId is only visible to users from that county
      if (countyId != null && countyId.isNotEmpty) {
        polls = polls.where((p) => p.countyId == null || p.countyId!.isEmpty || p.countyId == countyId).toList();
      }

      // Filter by type if needed
      if (type != null) {
        polls = polls.where((p) => p.type == type).toList();
      }

      // Filter active polls if needed
      if (activeOnly) {
        polls = polls.where((p) => p.isActive).toList();
      }

      // Filter by school if needed
      // Show: county polls, school polls with matching schoolId, or school polls with null schoolId (all schools in this county)
      if (schoolId != null) {
        polls = polls.where((p) =>
            p.type == PollType.county ||
            p.schoolId == schoolId ||
            p.schoolId == null).toList();
      }

      // Sort by createdAt descending
      polls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return polls.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting polls: $e');
      return [];
    }
  }

  /// Get polls stream
  Stream<List<PollModel>> getPollsStream({
    PollType? type,
    String? countyId,
    int limit = 20,
  }) {
    // Simple stream without composite queries
    return _collection.snapshots().map((snapshot) {
      List<PollModel> polls = snapshot.docs
          .map((doc) => PollModel.fromFirestore(doc))
          .toList();

      // County filtering:
      // - Content with NULL countyId is visible to everyone (legacy/global content)
      // - Content with countyId is only visible to users from that county
      if (countyId != null && countyId.isNotEmpty) {
        polls = polls.where((p) => p.countyId == null || p.countyId!.isEmpty || p.countyId == countyId).toList();
      }

      // Filter by type if needed
      if (type != null) {
        polls = polls.where((p) => p.type == type).toList();
      }

      // Sort by createdAt descending
      polls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return polls.take(limit).toList();
    });
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
      final docRef = await _collection.add(poll.toFirestore()).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout creating poll - Firestore may be unavailable');
        },
      );
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

  /// Vote on poll (single option)
  Future<bool> vote({
    required String pollId,
    required String optionId,
    required String oderId,
    required String voterName,
    String? voterSchoolId,
    String? voterSchoolName,
  }) async {
    return voteMultiple(
      pollId: pollId,
      optionIds: [optionId],
      oderId: oderId,
      voterName: voterName,
      voterSchoolId: voterSchoolId,
      voterSchoolName: voterSchoolName,
    );
  }

  /// Vote on poll with multiple options (for polls with allowMultipleVotes)
  Future<bool> voteMultiple({
    required String pollId,
    required List<String> optionIds,
    required String oderId,
    required String voterName,
    String? voterSchoolId,
    String? voterSchoolName,
  }) async {
    if (optionIds.isEmpty) return false;

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

        // Validate: if multiple options but poll doesn't allow multiple votes
        if (optionIds.length > 1 && !poll.allowMultipleVotes) {
          debugPrint('Poll does not allow multiple votes');
          return false;
        }

        // Update option vote counts for all selected options
        final updatedOptions = poll.options.map((option) {
          if (optionIds.contains(option.id)) {
            return option.copyWith(voteCount: option.voteCount + 1);
          }
          return option;
        }).toList();

        // Calculate total votes added
        final votesAdded = optionIds.length;

        // Update poll
        transaction.update(docRef, {
          'options': updatedOptions.map((o) => o.toMap()).toList(),
          'totalVotes': poll.totalVotes + votesAdded,
          'voterIds': [...poll.voterIds, oderId],
          'updatedAt': Timestamp.now(),
        });

        return true;
      }).then((success) async {
        // If vote succeeded and poll is NOT anonymous, store voter details
        if (success) {
          final poll = await getPollById(pollId);
          if (poll != null && !poll.isAnonymous) {
            // Get option texts for the voted options
            final optionTexts = poll.options
                .where((o) => optionIds.contains(o.id))
                .map((o) => o.text)
                .toList();

            final pollVote = PollVote(
              id: '',
              pollId: pollId,
              voterId: oderId,
              voterName: voterName,
              voterSchoolId: voterSchoolId,
              voterSchoolName: voterSchoolName,
              optionIds: optionIds,
              optionTexts: optionTexts,
              createdAt: DateTime.now(),
            );

            await _votesCollection.add(pollVote.toFirestore());
          }
        }
        return success;
      });
    } catch (e) {
      debugPrint('Error voting: $e');
      return false;
    }
  }

  /// Get all votes for a poll (for admin visibility on non-anonymous polls)
  Future<List<PollVote>> getVotes(String pollId) async {
    try {
      final snapshot = await _votesCollection
          .where('pollId', isEqualTo: pollId)
          .get();

      final votes = snapshot.docs
          .map((doc) => PollVote.fromFirestore(doc))
          .toList();

      // Sort by createdAt descending
      votes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return votes;
    } catch (e) {
      debugPrint('Error getting poll votes: $e');
      return [];
    }
  }

  /// Get votes stream for a poll
  Stream<List<PollVote>> getVotesStream(String pollId) {
    return _votesCollection
        .where('pollId', isEqualTo: pollId)
        .snapshots()
        .map((snapshot) {
      final votes = snapshot.docs
          .map((doc) => PollVote.fromFirestore(doc))
          .toList();
      votes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return votes;
    });
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

  /// Get user's vote on a poll (returns option IDs they voted for)
  Future<List<String>?> getUserVote(String pollId, String oderId) async {
    try {
      final snapshot = await _votesCollection
          .where('pollId', isEqualTo: pollId)
          .where('voterId', isEqualTo: oderId)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return List<String>.from(snapshot.docs.first.data()['optionIds'] ?? []);
    } catch (e) {
      debugPrint('Error getting user vote: $e');
      return null;
    }
  }

  /// Get active polls for home screen
  Future<List<PollModel>> getActivePolls({
    String? schoolId,
    String? countyId,
    int limit = 5,
  }) async {
    try {
      // Get all polls and filter in memory to avoid composite index requirement
      final snapshot = await _collection.get();

      List<PollModel> polls = snapshot.docs
          .map((doc) => PollModel.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();

      // County filtering:
      // - Content with NULL countyId is visible to everyone (legacy/global content)
      // - Content with countyId is only visible to users from that county
      if (countyId != null && countyId.isNotEmpty) {
        polls = polls.where((p) => p.countyId == null || p.countyId!.isEmpty || p.countyId == countyId).toList();
      }

      // Filter by school if needed
      // Show: county polls, school polls with matching schoolId, or school polls with null schoolId (all schools in this county)
      if (schoolId != null) {
        polls = polls.where((p) =>
            p.type == PollType.county ||
            p.schoolId == schoolId ||
            p.schoolId == null).toList();
      }

      // Sort by endDate ascending (soonest ending first)
      polls.sort((a, b) => a.endDate.compareTo(b.endDate));

      return polls.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting active polls: $e');
      return [];
    }
  }
}
