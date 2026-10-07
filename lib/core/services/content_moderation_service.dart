import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

/// Reports contain identifiers and a bounded reason, not copied pupil names.
class ContentModerationService {
  final FirebaseFirestore _db;
  ContentModerationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> reportAnnouncement(
    UserModel user,
    AnnouncementModel content,
    String reason, {
    bool blockAuthor = false,
  }) => reportContent(
    user,
    type: blockAuthor ? 'block' : 'announcement',
    contentId: content.id,
    countyId: content.countyId,
    authorId: content.authorId,
    reason: reason,
    blockAuthor: blockAuthor,
  );

  Future<void> reportContent(
    UserModel user, {
    required String type,
    required String contentId,
    required String? countyId,
    required String authorId,
    required String reason,
    bool blockAuthor = false,
  }) async {
    if (![
      'announcement',
      'block',
      'initiative',
      'initiative_comment',
    ].contains(type)) {
      throw ArgumentError('Unsupported content type');
    }
    if (!user.isActive || user.id.isEmpty || countyId == null) {
      throw StateError('Contul activ și județul sunt necesare.');
    }
    if (reason.trim().isEmpty || reason.length > 500) {
      throw ArgumentError('Motivul raportării nu este valid.');
    }
    if (blockAuthor &&
        (authorId == user.id ||
            authorId.isEmpty ||
            user.blockedUsers.length >= 500)) {
      throw StateError('Autorul nu poate fi blocat.');
    }
    final batch = _db.batch();
    batch.set(_db.collection('reports').doc(), {
      'type': type,
      'contentId': contentId,
      'countyId': countyId,
      'reportedBy': user.id,
      'reason': reason.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    if (blockAuthor) {
      batch.update(_db.collection('users').doc(user.id), {
        'blockedUsers': FieldValue.arrayUnion([authorId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> unblockAuthor(UserModel user, String authorId) =>
      _db.collection('users').doc(user.id).update({
        'blockedUsers': FieldValue.arrayRemove([authorId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> resolveReport(
    String id,
    String moderatorId, {
    bool dismissed = false,
  }) => _db.collection('reports').doc(id).update({
    'status': dismissed ? 'dismissed' : 'reviewed',
    'resolvedBy': moderatorId,
    'resolvedAt': FieldValue.serverTimestamp(),
  });
}
