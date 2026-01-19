import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'database_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _analytics = AnalyticsService();
  final _databaseService = DatabaseService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  String? _currentUserId;

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _tokenController.stream;

  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission (iOS and Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupMessaging();
    }
  }

  Future<void> _setupMessaging() async {
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Listen for token refresh and persist to Firestore
    _messaging.onTokenRefresh.listen((token) async {
      final oldToken = _fcmToken;
      _fcmToken = token;
      _tokenController.add(token);
      debugPrint('FCM Token refreshed: $token');

      // Update token in Firestore if user is logged in
      if (_currentUserId != null) {
        // Remove old token if exists
        if (oldToken != null && oldToken != token) {
          await _databaseService.removeFcmToken(_currentUserId!, oldToken);
        }
        // Store new token
        await _persistToken(_currentUserId!, token);
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Set the current user ID and persist FCM token to Firestore
  /// Call this after user login
  Future<void> setUserId(String userId) async {
    _currentUserId = userId;
    if (_fcmToken != null) {
      await _persistToken(userId, _fcmToken!);
    }
  }

  /// Clear the current user ID and optionally remove token
  /// Call this on user logout
  Future<void> clearUserId({bool removeToken = true}) async {
    if (removeToken && _currentUserId != null && _fcmToken != null) {
      await _databaseService.removeFcmToken(_currentUserId!, _fcmToken!);
    }
    _currentUserId = null;
  }

  /// Persist FCM token to Firestore for push notification targeting
  Future<void> _persistToken(String userId, String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _databaseService.storeFcmToken(
        userId: userId,
        token: token,
        platform: platform,
      );
      debugPrint('FCM token persisted to Firestore for user: $userId');
    } catch (e) {
      debugPrint('Failed to persist FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _messageController.add(message);

    // Track notification received
    _analytics.logEvent('notification_received', {
      'message_id': message.messageId ?? '',
      'title': message.notification?.title ?? '',
      'from_background': 'false',
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.notification?.title}');

    // Track notification tap
    _analytics.logEvent('notification_tapped', {
      'message_id': message.messageId ?? '',
      'title': message.notification?.title ?? '',
    });

    // Handle navigation based on message data
    final data = message.data;
    if (data.containsKey('type')) {
      _handleNotificationNavigation(data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_order':
        // Navigate to orders screen
        debugPrint('Navigate to orders: ${data['order_id']}');
        break;
      case 'vendor_nearby':
        // Navigate to vendor on map
        debugPrint('Navigate to vendor: ${data['vendor_id']}');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Subscribe vendor to their order notifications
  Future<void> subscribeVendorToOrders(String vendorId) async {
    await subscribeToTopic('vendor_$vendorId');
  }

  /// Unsubscribe vendor from order notifications
  Future<void> unsubscribeVendorFromOrders(String vendorId) async {
    await unsubscribeFromTopic('vendor_$vendorId');
  }

  /// Subscribe customer to vendor updates (when vendor goes online)
  Future<void> subscribeToVendorUpdates(String vendorId) async {
    await subscribeToTopic('vendor_updates_$vendorId');
  }

  /// Unsubscribe from vendor updates
  Future<void> unsubscribeFromVendorUpdates(String vendorId) async {
    await unsubscribeFromTopic('vendor_updates_$vendorId');
  }

  // ============ CUISINE-BASED SEGMENTATION ============

  /// Subscribe to cuisine-based notifications
  Future<void> subscribeToCuisine(String cuisine) async {
    final topic = 'cuisine_${cuisine.toLowerCase().replaceAll(' ', '_')}';
    await subscribeToTopic(topic);
  }

  /// Unsubscribe from cuisine-based notifications
  Future<void> unsubscribeFromCuisine(String cuisine) async {
    final topic = 'cuisine_${cuisine.toLowerCase().replaceAll(' ', '_')}';
    await unsubscribeFromTopic(topic);
  }

  /// Update cuisine subscriptions based on user preferences
  /// Unsubscribes from old cuisines and subscribes to new ones
  Future<void> updateCuisineSubscriptions({
    required List<String> oldCuisines,
    required List<String> newCuisines,
  }) async {
    // Unsubscribe from cuisines no longer in preferences
    for (final cuisine in oldCuisines) {
      if (!newCuisines.contains(cuisine)) {
        await unsubscribeFromCuisine(cuisine);
      }
    }

    // Subscribe to new cuisines
    for (final cuisine in newCuisines) {
      if (!oldCuisines.contains(cuisine)) {
        await subscribeToCuisine(cuisine);
      }
    }
  }

  // ============ SEGMENT TOPICS ============

  /// Subscribe to promotional notifications
  Future<void> subscribeToPromotions() async {
    await subscribeToTopic('promotions');
  }

  /// Unsubscribe from promotional notifications
  Future<void> unsubscribeFromPromotions() async {
    await unsubscribeFromTopic('promotions');
  }

  /// Subscribe to new vendor announcements
  Future<void> subscribeToNewVendors() async {
    await subscribeToTopic('new_vendors');
  }

  /// Unsubscribe from new vendor announcements
  Future<void> unsubscribeFromNewVendors() async {
    await unsubscribeFromTopic('new_vendors');
  }

  /// Update all notification subscriptions based on user preferences
  Future<void> syncSubscriptionsWithPreferences({
    required bool orderUpdates,
    required bool promotions,
    required bool newVendors,
    required List<String> favoriteCuisines,
    List<String>? previousCuisines,
  }) async {
    // Promotions
    if (promotions) {
      await subscribeToPromotions();
    } else {
      await unsubscribeFromPromotions();
    }

    // New vendors
    if (newVendors) {
      await subscribeToNewVendors();
    } else {
      await unsubscribeFromNewVendors();
    }

    // Cuisine topics
    await updateCuisineSubscriptions(
      oldCuisines: previousCuisines ?? [],
      newCuisines: favoriteCuisines,
    );

    debugPrint('Notification subscriptions synced with preferences');
  }

  void dispose() {
    _tokenController.close();
    _messageController.close();
  }
}
