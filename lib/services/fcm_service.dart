import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission
      await requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      String? token = await getToken();
      if (token != null) {
        developer.log('[FCM] Token: $token', name: 'FCM');
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        developer.log('[FCM] Token refreshed: $newToken', name: 'FCM');
      });
    } catch (e) {
      developer.log('[FCM] Initialization error: $e', name: 'FCM');
    }
  }

  // Request notification permission
  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('[FCM] User granted permission', name: 'FCM');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('[FCM] User granted provisional permission', name: 'FCM');
      } else {
        developer.log(
          '[FCM] User declined or has not accepted permission',
          name: 'FCM',
        );
      }
    } catch (e) {
      developer.log('[FCM] Permission request error: $e', name: 'FCM');
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      return token;
    } catch (e) {
      developer.log('[FCM] Get token error: $e', name: 'FCM');
      return null;
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log(
          '[FCM] Notification tapped: ${response.payload}',
          name: 'FCM',
        );
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Show local notification (for foreground messages)
  Future<void> showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        payload: message.data['url'],
      );
    }
  }
}
