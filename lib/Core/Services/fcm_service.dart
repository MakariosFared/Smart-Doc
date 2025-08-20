import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    if (_isInitialized) return;

    try {
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

      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Failed to request notification permission: $e');
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
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        // Here you would typically send the new token to your server
      });
    } catch (e) {
      print('Failed to get FCM token: $e');
    }
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    try {
      // Handle messages when app is in foreground
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // Handle messages when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      print('✅ Message handlers set up successfully');
    } catch (e) {
      print('❌ Failed to set up message handlers: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');

    // Show local notification
    _showLocalNotification(message);

    // Handle queue-related notifications
    _handleQueueNotification(message);
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');

    // Show local notification for background messages
    await _showBackgroundNotification(message);
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
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Queue Update',
        message.notification?.body ?? 'You have a queue update',
        details,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Failed to show local notification: $e');
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
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'Queue Update',
        message.notification?.body ?? 'You have a queue update',
        details,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Failed to show background notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    // Handle navigation based on notification type
    if (response.payload != null) {
      // Parse the payload and navigate accordingly
      // This would typically involve using a navigation service
    }
  }

  /// Handle notification when app is opened
  void _handleNotificationOpened(RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');

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
        default:
          print('Unknown notification type: $type');
      }
    }
  }

  /// Handle queue-related notifications
  void _handleQueueNotification(RemoteMessage message) {
    if (message.data.containsKey('queue_position')) {
      final position = int.tryParse(message.data['queue_position'] ?? '0') ?? 0;

      if (position == 1) {
        print('🎉 Patient\'s turn is now!');
        // You could trigger additional actions here
      } else if (position <= 3) {
        print('⚠️ Patient\'s turn is coming soon (position: $position)');
        // You could trigger additional actions here
      }
    }
  }

  /// Handle appointment reminders
  void _handleAppointmentReminder(RemoteMessage message) {
    print('Appointment reminder received');
    // Handle appointment reminder logic
  }

  /// Subscribe to a specific topic (e.g., doctor's queue)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Subscribe to patient-specific notifications
  Future<void> subscribeToPatientNotifications(String patientId) async {
    try {
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

  /// Dispose resources
  void dispose() {
    _messageSubscription?.cancel();
    _backgroundMessageSubscription?.cancel();
    _isInitialized = false;
  }
}

/// Global instance of FCM service
final fcmService = FCMService();
