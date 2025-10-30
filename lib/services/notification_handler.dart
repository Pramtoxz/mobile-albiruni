import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer' as developer;
import 'fcm_service.dart';

class NotificationHandler {
  final WebViewController webViewController;
  final String baseUrl;
  final FcmService _fcmService = FcmService();

  NotificationHandler({required this.webViewController, required this.baseUrl});

  // Initialize notification handlers
  void initialize() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '[FCM] Foreground notification: ${message.notification?.title}',
        name: 'FCM',
      );

      // Show local notification when app is in foreground
      _fcmService.showLocalNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '[FCM] Background notification tapped: ${message.data}',
        name: 'FCM',
      );
      _handleNotificationTap(message);
    });

    // Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        developer.log(
          '[FCM] Terminated notification tapped: ${message.data}',
          name: 'FCM',
        );
        _handleNotificationTap(message);
      }
    });
  }

  // Handle notification tap - navigate to URL
  void _handleNotificationTap(RemoteMessage message) {
    String? url = message.data['url'];
    if (url != null && url.isNotEmpty) {
      // Navigate WebView to the URL
      String fullUrl;
      if (url.startsWith('http')) {
        // Full URL provided
        fullUrl = url;
      } else {
        // Relative URL - extract base domain from baseUrl
        Uri baseUri = Uri.parse(baseUrl);
        String baseDomain = '${baseUri.scheme}://${baseUri.host}';
        if (baseUri.hasPort) {
          baseDomain += ':${baseUri.port}';
        }
        fullUrl = '$baseDomain$url';
      }
      developer.log('[FCM] Navigating to: $fullUrl', name: 'FCM');
      webViewController.loadRequest(Uri.parse(fullUrl));
    }
  }
}
