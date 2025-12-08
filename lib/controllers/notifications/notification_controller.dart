import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/repositories/notification_repository.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';
import '../theme/theme_controller.dart';

/// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Notifications list provider
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return [];

  final repository = ref.read(notificationRepositoryProvider);
  try {
    return await repository.getNotifications(user.id).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <NotificationModel>[],
    );
  } catch (e) {
    return <NotificationModel>[];
  }
});

/// Notifications stream provider for real-time updates
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.read(currentUserProvider); // Use read to avoid rebuilds
  if (user == null) return Stream.value([]);

  final repository = ref.read(notificationRepositoryProvider);
  return repository.getNotificationsStream(user.id).transform(
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) {
        debugPrint('Notifications stream error: $error');
        sink.add(<NotificationModel>[]); // Emit empty list instead of error
      },
    ),
  );
});

/// Unread notification count provider - using Future instead of Stream to avoid retry loops
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(currentUserProvider); // Use read to avoid rebuilds
  if (user == null) return 0;

  final repository = ref.read(notificationRepositoryProvider);
  try {
    return await repository.getUnreadCount(user.id).timeout(
      const Duration(seconds: 5),
      onTimeout: () => 0,
    );
  } catch (e) {
    debugPrint('Error getting unread count: $e');
    return 0;
  }
});

/// Notification controller for managing notifications
class NotificationController extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    final success = await _repository.markAsRead(notificationId);
    if (success) {
      _ref.invalidate(notificationsProvider);
    }
    return success;
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    state = const AsyncValue.loading();
    final success = await _repository.markAllAsRead(user.id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(notificationsProvider);
    } else {
      state = AsyncValue.error('Failed to mark all as read', StackTrace.current);
    }

    return success;
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    final success = await _repository.deleteNotification(notificationId);
    if (success) {
      _ref.invalidate(notificationsProvider);
    }
    return success;
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    state = const AsyncValue.loading();
    final success = await _repository.deleteAllNotifications(user.id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(notificationsProvider);
    } else {
      state = AsyncValue.error('Failed to delete notifications', StackTrace.current);
    }

    return success;
  }

  /// Create a notification (for internal use)
  Future<String?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
    );

    final id = await _repository.createNotification(notification);
    if (id != null) {
      _ref.invalidate(notificationsProvider);
    }
    return id;
  }

  /// Send notification to multiple users
  Future<void> sendToUsers({
    required List<String> userIds,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: '', // Will be set per user
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
    );

    await _repository.sendToUsers(userIds: userIds, notification: notification);
  }

  /// Send county-wide notification to all users in the county
  Future<bool> sendCountyWideNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.systemAlert,
    String? countyId,
    List<UserRole>? targetRoles,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return false;
    }

    // Only BEX and Superadmin can send county-wide notifications
    if (user.role != UserRole.bex && user.role != UserRole.superadmin) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return false;
    }

    try {
      final success = await _repository.sendCountyWideNotification(
        title: title,
        body: body,
        type: type,
        countyId: countyId, // Let repository handle if null
        targetRoles: targetRoles,
        senderId: user.id,
        senderName: user.fullName,
      );

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Failed to send notification', StackTrace.current);
        return false;
      }
    } catch (e) {
      state = AsyncValue.error('Error: $e', StackTrace.current);
      return false;
    }
  }
}

/// Check if current user can send county-wide notifications
final canSendCountyNotificationsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Notification controller provider
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(
    ref.watch(notificationRepositoryProvider),
    ref,
  );
});

/// Notifications enabled storage key
const String _notificationsEnabledKey = 'notifications_enabled';

/// Notifications enabled state notifier
class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  NotificationsEnabledNotifier(this._prefs) : super(_loadEnabled(_prefs));

  static bool _loadEnabled(SharedPreferences prefs) {
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

/// Notifications enabled provider
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationsEnabledNotifier(prefs);
});
