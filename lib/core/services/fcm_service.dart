import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/user_repository.dart';
import '../../routes/route_names.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message: ${message.messageId}');
}

/// FCM Push Notification Service
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Navigation callback for handling notification taps
  Function(String route, Map<String, dynamic>? data)? onNotificationTap;

  /// Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cje_notifications',
    'CJE Notifications',
    description: 'Notifications for CJE Platform',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  /// Initialize FCM service
  Future<void> initialize({
    Function(String route, Map<String, dynamic>? data)? onTap,
  }) async {
    onNotificationTap = onTap;

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Set up message handlers
    _setupMessageHandlers();
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM Permission: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Handle foreground message - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'CJE',
        body: notification.body ?? '',
        payload: _encodePayload(message.data),
      );
    }
  }

  /// Handle notification open (app in background)
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('FCM Notification opened: ${message.messageId}');
    _navigateFromNotification(message.data);
  }

  /// Check if app was launched from notification
  Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      debugPrint('FCM Initial message: ${message.messageId}');
      _navigateFromNotification(message.data);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _navigateFromNotification(data);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cje_notifications',
      'CJE Notifications',
      channelDescription: 'Notifications for CJE Platform',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    if (onNotificationTap == null) return;

    final type = data['type'] as String?;
    final itemId = data['itemId'] as String?;

    String route = RouteNames.notifications;

    switch (type) {
      case 'announcement':
        if (itemId != null) {
          route = RouteNames.announcementDetailPath(itemId);
        } else {
          route = RouteNames.announcements;
        }
        break;
      case 'meeting':
        if (itemId != null) {
          route = RouteNames.meetingDetailPath(itemId);
        } else {
          route = RouteNames.meetings;
        }
        break;
      case 'initiative':
        if (itemId != null) {
          route = RouteNames.initiativeDetailPath(itemId);
        } else {
          route = RouteNames.initiatives;
        }
        break;
      case 'poll':
        if (itemId != null) {
          route = RouteNames.pollDetailPath(itemId);
        } else {
          route = RouteNames.polls;
        }
        break;
      case 'document':
        route = RouteNames.documents;
        break;
      default:
        route = RouteNames.notifications;
    }

    onNotificationTap!(route, data);
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM Token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Listen for token refresh
  void onTokenRefresh(Function(String) callback) {
    _messaging.onTokenRefresh.listen(callback);
  }

  /// Encode payload to string
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload from string
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }
}

/// FCM Service provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// FCM Token provider - updates user's token in Firestore
final fcmTokenProvider = FutureProvider.family<String?, String>((ref, userId) async {
  if (userId.isEmpty) return null;

  final fcmService = ref.read(fcmServiceProvider);
  final token = await fcmService.getToken();

  if (token != null) {
    // Update token in Firestore
    final userRepository = UserRepository();
    await userRepository.updateFcmToken(userId, token);

    // Listen for token refresh
    fcmService.onTokenRefresh((newToken) async {
      await userRepository.updateFcmToken(userId, newToken);
    });
  }

  return token;
});
