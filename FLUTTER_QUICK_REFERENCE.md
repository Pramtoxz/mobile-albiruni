# Flutter Quick Reference Card
## FCM Integration dengan Laravel Backend

---

## 🎯 Minimal Implementation (Copy-Paste Ready)

### 1. pubspec.yaml
```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
  webview_flutter: ^4.10.0
  webview_flutter_android: ^3.17.1
```

### 2. AndroidManifest.xml
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

### 3. main.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Request permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  runApp(MyApp());
}
```

### 4. WebView dengan JavaScript Channel
```dart
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  final String baseUrl = 'https://yourapp.com';
  
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }
  
  void _setupNotifications() {
    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground notification: ${message.notification?.title}');
      // Show local notification
    });
    
    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });
    
    // Terminated tap
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    String? url = message.data['url'];
    if (url != null) {
      _controller.loadUrl('$baseUrl$url');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: baseUrl,
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        JavascriptChannel(
          name: 'FlutterBridge',
          onMessageReceived: (JavascriptMessage message) async {
            if (message.message == 'get_fcm_token') {
              String? token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                _controller.runJavascript(
                  "window.receiveFCMToken('$token')"
                );
              }
            }
          },
        ),
      },
      onWebViewCreated: (controller) {
        _controller = controller;
      },
    );
  }
}
```

---

## 🔑 Critical Points

### JavaScript Channel Name
```dart
name: 'FlutterBridge'  // MUST BE EXACTLY THIS!
```

### Message to Handle
```dart
if (message.message == 'get_fcm_token') {
  // Get and send token
}
```

### Response Function
```dart
_controller.runJavascript(
  "window.receiveFCMToken('$token')"
);
```

### Notification Data Structure
```dart
String? url = message.data['url'];  // Relative path
String? type = message.data['type']; // Event type
```

### Navigation
```dart
_controller.loadUrl('$baseUrl$url');
// Example: https://yourapp.com/orangtua/daily-report/123
```

---

## 🧪 Testing Commands

### Get FCM Token
```dart
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### Check Permission
```dart
NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Permission: ${settings.authorizationStatus}');
```

### Listen Token Refresh
```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  print('Token refreshed: $newToken');
  // Send to Laravel
});
```

---

## 📝 Checklist

### Setup
- [ ] Add google-services.json to android/app/
- [ ] Update build.gradle files
- [ ] Update AndroidManifest.xml
- [ ] Add dependencies to pubspec.yaml
- [ ] Run `flutter pub get`

### Implementation
- [ ] Initialize Firebase in main()
- [ ] Request notification permission
- [ ] Create WebView with JavaScript Channel
- [ ] Handle foreground notifications
- [ ] Handle background notifications
- [ ] Handle terminated notifications
- [ ] Implement notification tap handler

### Testing
- [ ] Token printed in console
- [ ] Token sent to Laravel (check database)
- [ ] Notification received (foreground)
- [ ] Notification received (background)
- [ ] Notification received (terminated)
- [ ] Tap navigates correctly
- [ ] Session persists

---

## 🐛 Common Issues

### Issue: Token null
```dart
// Solution: Check permission
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  String? token = await FirebaseMessaging.instance.getToken();
}
```

### Issue: JavaScript Channel not working
```dart
// Solution: Check name exactly
JavascriptChannel(
  name: 'FlutterBridge',  // Must be exact!
  ...
)
```

### Issue: Notification not showing
```dart
// Solution: Use flutter_local_notifications for foreground
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

FirebaseMessaging.onMessage.listen((message) {
  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(...),
  );
});
```

---

## 📞 Laravel Backend Info

### API Endpoint
```
POST https://yourapp.com/api/device-tokens
```

### Request Body
```json
{
  "fcm_token": "string",
  "device_type": "android",
  "device_name": "optional"
}
```

### Headers
```
Content-Type: application/json
X-CSRF-TOKEN: [from meta tag]
```

### Response
```json
{
  "success": true,
  "message": "FCM token registered successfully"
}
```

---

## 🎯 Success Criteria

When everything works:
1. ✅ Token appears in Laravel database
2. ✅ Console shows: `[FCM] Token registered successfully`
3. ✅ Notification muncul saat daily report created
4. ✅ Tap notification → navigate ke halaman yang benar
5. ✅ Session tetap aktif setelah navigation

---

**Quick Start Time**: ~2 hours
**Full Implementation**: ~4-6 hours
**Documentation**: FIREBASE_PUSH_NOTIFICATION.md
