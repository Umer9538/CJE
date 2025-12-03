import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';

/// Repository for GDS (Support Groups) Firestore operations
class GDSRepository {
  final FirebaseFirestore _firestore;

  GDSRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _gdsCollection =>
      _firestore.collection('gds');

  /// Get all GDS groups
  Future<List<GDSModel>> getAllGDS() async {
    try {
      final snapshot = await _gdsCollection.orderBy('name').get();
      return snapshot.docs.map((doc) => GDSModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all GDS: $e');
      return [];
    }
  }

  /// Get active GDS groups
  Future<List<GDSModel>> getActiveGDS() async {
    try {
      // Get all GDS and filter in memory to avoid composite index requirement
      final snapshot = await _gdsCollection.get();
      final gdsList = snapshot.docs
          .map((doc) => GDSModel.fromFirestore(doc))
          .where((gds) => gds.isActive)
          .toList();
      // Sort by name in memory
      gdsList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return gdsList;
    } catch (e) {
      debugPrint('Error getting active GDS: $e');
      return [];
    }
  }

  /// Get GDS stream for real-time updates
  Stream<List<GDSModel>> getGDSStream() {
    return _gdsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GDSModel.fromFirestore(doc)).toList());
  }

  /// Get GDS by ID
  Future<GDSModel?> getGDSById(String gdsId) async {
    try {
      final doc = await _gdsCollection.doc(gdsId).get();
      if (doc.exists) {
        return GDSModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting GDS: $e');
      return null;
    }
  }

  /// Create new GDS
  Future<String?> createGDS(GDSModel gds) async {
    try {
      final docRef = await _gdsCollection.add(gds.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating GDS: $e');
      return null;
    }
  }

  /// Update GDS
  Future<bool> updateGDS(GDSModel gds) async {
    try {
      await _gdsCollection.doc(gds.id).update(
        gds.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating GDS: $e');
      return false;
    }
  }

  /// Delete GDS
  Future<bool> deleteGDS(String gdsId) async {
    try {
      await _gdsCollection.doc(gdsId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting GDS: $e');
      return false;
    }
  }

  /// Toggle GDS active status
  Future<bool> toggleGDSActive(String gdsId, bool isActive) async {
    try {
      await _gdsCollection.doc(gdsId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling GDS active: $e');
      return false;
    }
  }

  /// Add member to GDS
  Future<bool> addMember(String gdsId, GDSMember member) async {
    try {
      final gds = await getGDSById(gdsId);
      if (gds == null) return false;

      // Check if already a member
      if (gds.memberIds.contains(member.id)) return false;

      final updatedMemberIds = [...gds.memberIds, member.id];
      final updatedMembers = [...gds.members, member];

      await _gdsCollection.doc(gdsId).update({
        'memberIds': updatedMemberIds,
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding member to GDS: $e');
      return false;
    }
  }

  /// Remove member from GDS
  Future<bool> removeMember(String gdsId, String memberId) async {
    try {
      final gds = await getGDSById(gdsId);
      if (gds == null) return false;

      final updatedMemberIds = gds.memberIds.where((id) => id != memberId).toList();
      final updatedMembers = gds.members.where((m) => m.id != memberId).toList();

      await _gdsCollection.doc(gdsId).update({
        'memberIds': updatedMemberIds,
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing member from GDS: $e');
      return false;
    }
  }

  /// Update member role
  Future<bool> updateMemberRole(String gdsId, String memberId, String? role) async {
    try {
      final gds = await getGDSById(gdsId);
      if (gds == null) return false;

      final updatedMembers = gds.members.map((m) {
        if (m.id == memberId) {
          return m.copyWith(role: role);
        }
        return m;
      }).toList();

      await _gdsCollection.doc(gdsId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating member role: $e');
      return false;
    }
  }

  /// Change GDS leader
  Future<bool> changeLeader(String gdsId, String newLeaderId, String newLeaderName) async {
    try {
      await _gdsCollection.doc(gdsId).update({
        'leaderId': newLeaderId,
        'leaderName': newLeaderName,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error changing GDS leader: $e');
      return false;
    }
  }

  /// Get GDS groups for a specific user
  Future<List<GDSModel>> getGDSForUser(String userId) async {
    try {
      // Get all GDS and filter in memory to avoid composite index requirement
      final snapshot = await _gdsCollection.get();
      final gdsList = snapshot.docs
          .map((doc) => GDSModel.fromFirestore(doc))
          .where((gds) => gds.isActive && gds.memberIds.contains(userId))
          .toList();
      gdsList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return gdsList;
    } catch (e) {
      debugPrint('Error getting GDS for user: $e');
      return [];
    }
  }

  /// Get GDS groups led by a specific user
  Future<List<GDSModel>> getGDSLedByUser(String userId) async {
    try {
      // Get all GDS and filter in memory to avoid composite index requirement
      final snapshot = await _gdsCollection.get();
      final gdsList = snapshot.docs
          .map((doc) => GDSModel.fromFirestore(doc))
          .where((gds) => gds.isActive && gds.leaderId == userId)
          .toList();
      gdsList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return gdsList;
    } catch (e) {
      debugPrint('Error getting GDS led by user: $e');
      return [];
    }
  }
}
