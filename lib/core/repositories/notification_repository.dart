import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for notification-related Firestore operations
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Get notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Get notifications stream for real-time updates
  Stream<List<NotificationModel>> getNotificationsStream(String userId, {int limit = 50}) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get unread notification count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a new notification
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _notificationsCollection.add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications for a user
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  /// Send notification to multiple users
  Future<void> sendToUsers({
    required List<String> userIds,
    required NotificationModel notification,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final docRef = _notificationsCollection.doc();
        batch.set(docRef, notification.copyWith(userId: userId).toFirestore());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error sending notifications to users: $e');
    }
  }

  /// Send county-wide notification to all users in the county
  Future<bool> sendCountyWideNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? countyId,
    List<UserRole>? targetRoles,
    required String senderId,
    required String senderName,
  }) async {
    try {
      // Get all users in the county (or all users if countyId is null)
      Query<Map<String, dynamic>> usersQuery = _firestore.collection('users');

      if (countyId != null && countyId.isNotEmpty) {
        usersQuery = usersQuery.where('countyId', isEqualTo: countyId);
      }

      // Filter by status (only active users)
      usersQuery = usersQuery.where('status', isEqualTo: 'active');

      final usersSnapshot = await usersQuery.get();

      if (usersSnapshot.docs.isEmpty) {
        debugPrint('No users found for county-wide notification');
        return false;
      }

      // Filter by roles if specified
      List<String> targetUserIds = [];
      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        if (targetRoles != null && targetRoles.isNotEmpty) {
          final userRole = userData['role'] as String?;
          if (userRole != null && targetRoles.any((r) => r.name == userRole)) {
            targetUserIds.add(doc.id);
          }
        } else {
          targetUserIds.add(doc.id);
        }
      }

      if (targetUserIds.isEmpty) {
        debugPrint('No users match the target roles');
        return false;
      }

      // Create notifications for all target users in batches
      const batchSize = 500; // Firestore batch limit
      for (var i = 0; i < targetUserIds.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < targetUserIds.length) ? i + batchSize : targetUserIds.length;

        for (var j = i; j < end; j++) {
          final docRef = _notificationsCollection.doc();
          batch.set(docRef, {
            'userId': targetUserIds[j],
            'type': type.name,
            'title': title,
            'body': body,
            'isRead': false,
            'data': {
              'senderId': senderId,
              'senderName': senderName,
              'isCountyWide': true,
            },
            'createdAt': Timestamp.now(),
          });
        }

        await batch.commit();
      }

      debugPrint('Sent county-wide notification to ${targetUserIds.length} users');
      return true;
    } catch (e) {
      debugPrint('Error sending county-wide notification: $e');
      return false;
    }
  }
}
