import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart'; // Added for Color
import 'dart:convert'; // Added for jsonDecode

/// Service for handling Firebase Cloud Messaging (FCM) notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _backgroundMessageSubscription;

  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ FCM Service already initialized');
      return;
    }

    try {
      print('🔄 Initializing FCM Service...');

      // Request permission for notifications
      await _requestNotificationPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      await _setupMessageHandlers();

      _isInitialized = true;
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize FCM Service: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Request notification permission
  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ Provisional notification permission granted');
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Failed to request notification permission: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
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

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Failed to initialize local notifications: $e');
      rethrow;
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        print('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
      } else {
        print('⚠️ FCM Token is null');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        // Here you would typically send the new token to your server
        _updateTokenOnServer(newToken);
      });
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
      rethrow;
    }
  }

  /// Update token on server (implement as needed)
  Future<void> _updateTokenOnServer(String token) async {
    try {
      // TODO: Implement token update on your server
      print('🔄 Updating FCM token on server...');
      // await _apiService.updateFCMToken(token);
      print('✅ FCM token updated on server');
    } catch (e) {
      print('❌ Failed to update FCM token on server: $e');
    }
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    try {
      // Handle messages when app is in foreground
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
        onError: (error) {
          print('❌ Error in foreground message handler: $error');
        },
      );

      // Handle messages when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleNotificationOpened,
        onError: (error) {
          print('❌ Error in message opened handler: $error');
        },
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      print('✅ Message handlers set up successfully');
    } catch (e) {
      print('❌ Failed to set up message handlers: $e');
      rethrow;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      print('📱 Received foreground message: ${message.messageId}');
      print('📱 Message data: ${message.data}');

      // Show local notification
      _showLocalNotification(message);

      // Handle queue-related notifications
      _handleQueueNotification(message);
    } catch (e) {
      print('❌ Error handling foreground message: $e');
    }
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      print('📱 Handling background message: ${message.messageId}');
      print('📱 Message data: ${message.data}');

      // Show local notification for background messages
      await _showBackgroundNotification(message);
    } catch (e) {
      print('❌ Error handling background message: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'queue_notifications',
        'Queue Notifications',
        channelDescription: 'Notifications for queue updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: 'ic_notification',
        color: const Color(0xFF4CAF50),
        channelShowBadge: true,
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'QUEUE_UPDATE',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = message.notification?.title ?? 'Queue Update';
      final body = message.notification?.body ?? 'You have a queue update';

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        details,
        payload: message.data.toString(),
      );

      print('✅ Local notification shown: $title - $body');
    } catch (e) {
      print('❌ Failed to show local notification: $e');
    }
  }

  /// Show background notification
  static Future<void> _showBackgroundNotification(RemoteMessage message) async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidDetails = AndroidNotificationDetails(
        'queue_notifications',
        'Queue Notifications',
        channelDescription: 'Notifications for queue updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        color: Color(0xFF4CAF50),
      );

      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'QUEUE_UPDATE',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = message.notification?.title ?? 'Queue Update';
      final body = message.notification?.body ?? 'You have a queue update';

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        details,
        payload: message.data.toString(),
      );

      print('✅ Background notification shown: $title - $body');
    } catch (e) {
      print('❌ Failed to show background notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      print('👆 Notification tapped: ${response.payload}');

      // Handle navigation based on notification type
      if (response.payload != null) {
        // Parse the payload and navigate accordingly
        // This would typically involve using a navigation service
        _handleNotificationNavigation(response.payload!);
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Handle notification navigation (implement as needed)
  void _handleNotificationNavigation(String payload) {
    try {
      // TODO: Implement navigation logic based on notification payload
      print('🔄 Handling notification navigation for payload: $payload');

      // Example: Parse payload and navigate to appropriate screen
      // final data = jsonDecode(payload);
      // if (data['type'] == 'queue_update') {
      //   // Navigate to queue screen
      // }
    } catch (e) {
      print('❌ Error handling notification navigation: $e');
    }
  }

  /// Handle notification when app is opened
  void _handleNotificationOpened(RemoteMessage message) {
    try {
      print('📱 App opened from notification: ${message.messageId}');
      print('📱 Message data: ${message.data}');

      // Handle navigation based on notification data
      if (message.data.containsKey('type')) {
        final type = message.data['type'];
        switch (type) {
          case 'queue_update':
            _handleQueueNotification(message);
            break;
          case 'appointment_reminder':
            _handleAppointmentReminder(message);
            break;
          case 'custom_notification':
            _handleCustomNotification(message);
            break;
          default:
            print('⚠️ Unknown notification type: $type');
        }
      }
    } catch (e) {
      print('❌ Error handling notification opened: $e');
    }
  }

  /// Handle queue-related notifications
  void _handleQueueNotification(RemoteMessage message) {
    try {
      if (message.data.containsKey('queue_position')) {
        final position =
            int.tryParse(message.data['queue_position'] ?? '0') ?? 0;

        if (position == 1) {
          print('🎉 Patient\'s turn is now!');
          // You could trigger additional actions here
        } else if (position <= 3) {
          print('⚠️ Patient\'s turn is coming soon (position: $position)');
          // You could trigger additional actions here
        }
      }

      // Handle different queue statuses
      if (message.data.containsKey('status')) {
        final status = message.data['status'];
        print('📊 Queue status update: $status');

        switch (status) {
          case 'waiting':
            print('⏳ Patient added to queue');
            break;
          case 'inProgress':
            print('▶️ Patient\'s turn started');
            break;
          case 'done':
            print('✅ Patient\'s appointment completed');
            break;
          case 'cancelled':
            print('❌ Patient\'s appointment cancelled');
            break;
        }
      }
    } catch (e) {
      print('❌ Error handling queue notification: $e');
    }
  }

  /// Handle appointment reminders
  void _handleAppointmentReminder(RemoteMessage message) {
    try {
      print('📅 Appointment reminder received');
      // Handle appointment reminder logic
    } catch (e) {
      print('❌ Error handling appointment reminder: $e');
    }
  }

  /// Handle custom notifications
  void _handleCustomNotification(RemoteMessage message) {
    try {
      print('📢 Custom notification received');
      // Handle custom notification logic
    } catch (e) {
      print('❌ Error handling custom notification: $e');
    }
  }

  /// Subscribe to a specific topic (e.g., doctor's queue)
  Future<void> subscribeToTopic(String topic) async {
    try {
      if (topic.isEmpty) {
        print('❌ Error: Topic cannot be empty');
        return;
      }

      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (topic.isEmpty) {
        print('❌ Error: Topic cannot be empty');
        return;
      }

      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Subscribe to patient-specific notifications
  Future<void> subscribeToPatientNotifications(String patientId) async {
    try {
      if (patientId.isEmpty) {
        print('❌ Error: Patient ID cannot be empty');
        return;
      }

      await subscribeToTopic('patient_$patientId');
      await subscribeToTopic('queue_updates');
      print('✅ Patient $patientId subscribed to notifications');
    } catch (e) {
      print('❌ Failed to subscribe patient $patientId to notifications: $e');
    }
  }

  /// Unsubscribe from patient-specific notifications
  Future<void> unsubscribeFromPatientNotifications(String patientId) async {
    try {
      if (patientId.isEmpty) {
        print('❌ Error: Patient ID cannot be empty');
        return;
      }

      await unsubscribeFromTopic('patient_$patientId');
      await unsubscribeFromTopic('queue_updates');
      print('✅ Patient $patientId unsubscribed from notifications');
    } catch (e) {
      print(
        '❌ Failed to unsubscribe patient $patientId from notifications: $e',
      );
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if notifications are enabled
  Future<bool> get areNotificationsEnabled async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error checking notification settings: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      _messageSubscription?.cancel();
      _backgroundMessageSubscription?.cancel();
      _isInitialized = false;
      print('🛑 FCM Service disposed');
    } catch (e) {
      print('❌ Error disposing FCM Service: $e');
    }
  }
}

/// Global instance of FCM service
final fcmService = FCMService();
