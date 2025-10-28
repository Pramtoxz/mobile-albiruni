# Firebase Push Notification Integration
## Laravel WebView + Flutter Mobile App

---

## 📋 Overview

Dokumen ini menjelaskan integrasi Firebase Cloud Messaging (FCM) untuk push notification antara Laravel backend dan Flutter WebView app. 

**Platform:** Android Only

**Arsitektur:**
- **Laravel**: Mengelola auth (session-based), business logic, dan mengirim notifikasi
- **Flutter**: Wrapper WebView + FCM handler, minimal logic
- **Firebase**: Cloud messaging service untuk deliver notifikasi

---

## 🎯 Tujuan

1. User menerima notifikasi real-time untuk:
   - Daily report baru
   - Tagihan SPP baru
   - Pembayaran diverifikasi
   - Pengumuman dari admin

2. User tap notifikasi → langsung buka halaman terkait di app
3. Session auth Laravel tetap berjalan normal di WebView
4. Tidak perlu duplicate auth atau API token management

---

## 🏗️ Arsitektur Flow

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Flutter   │◄────────┤   Firebase   │◄────────┤   Laravel   │
│   WebView   │         │     FCM      │         │   Backend   │
└─────────────┘         └──────────────┘         └─────────────┘
      │                                                  │
      │ 1. Get FCM Token                                │
      │─────────────────────────────────────────────────┤
      │                                                  │
      │ 2. Load WebView (session auth)                  │
      │─────────────────────────────────────────────────►
      │                                                  │
      │ 3. Send FCM Token via JavaScript Bridge         │
      │─────────────────────────────────────────────────►
      │                                                  │
      │                    4. Save token + user_id      │
      │                                                  │
      │                    5. Event triggered           │
      │                    6. Send FCM notification     │
      │                         │                        │
      │◄────────────────────────┘                        │
      │                                                  │
      │ 7. User tap notification                        │
      │ 8. Navigate WebView to URL                      │
      │─────────────────────────────────────────────────►
```

---

## 🔧 Tanggung Jawab Tim

### **Tim Flutter (Mobile App)**

#### Deliverables:
1. ✅ Setup Firebase project (Android + iOS)
2. ✅ Implement FCM token management
3. ✅ Expose JavaScript Channel untuk komunikasi dengan WebView
4. ✅ Handle notification (foreground/background/terminated)
5. ✅ Navigate WebView saat notification di-tap
6. ✅ Request notification permission dari user

#### Dependencies:
```yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest
  webview_flutter: ^latest
  webview_flutter_android: ^latest  # Android implementation
```

---

### **Tim Laravel (Backend)**

#### Deliverables:
1. ✅ Database migration untuk `device_tokens` table
2. ✅ API endpoint untuk register/update FCM token
3. ✅ FCM Service untuk kirim notifikasi
4. ✅ JavaScript bridge di frontend untuk komunikasi dengan Flutter
5. ✅ Integration dengan existing events (daily report, SPP, dll)

#### Dependencies:
```bash
composer require kreait/firebase-php
```

---

## 📱 Flutter Implementation Guide

### 1. Android Configuration

#### A. Add google-services.json
```
android/
  app/
    google-services.json  ← Place file here
```

#### B. Update android/build.gradle (Project level)
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### C. Update android/app/build.gradle (App level)
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21  // FCM requires min SDK 21
    }
}
```

#### D. Update AndroidManifest.xml
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- Add notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        
        <!-- Add notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

### 2. Firebase Setup

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### 3. FCM Token Management

```dart
class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // Get FCM token
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
  
  // Listen token refresh
  void listenTokenRefresh(Function(String) onTokenRefresh) {
    _fcm.onTokenRefresh.listen(onTokenRefresh);
  }
  
  // Request permission
  Future<void> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }
  }
}
```

### 4. JavaScript Channel (PENTING!)

```dart
class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  final FcmService _fcmService = FcmService();
  
  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'https://yourapp.com',
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        JavascriptChannel(
          name: 'FlutterBridge',
          onMessageReceived: (JavascriptMessage message) {
            _handleJavascriptMessage(message.message);
          },
        ),
      },
      onWebViewCreated: (controller) {
        _controller = controller;
      },
    );
  }
  
  void _handleJavascriptMessage(String message) async {
    if (message == 'get_fcm_token') {
      String? token = await _fcmService.getToken();
      if (token != null) {
        // Send token back to WebView
        _controller.runJavascript(
          "window.receiveFCMToken('$token')"
        );
      }
    }
  }
}
```

### 5. Notification Handler

```dart
class NotificationHandler {
  final WebViewController webViewController;
  
  NotificationHandler(this.webViewController);
  
  void initialize() {
    // Foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });
    
    // Background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
    
    // Terminated state notification tap
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    String? url = message.data['url'];
    if (url != null) {
      // Navigate WebView to URL
      webViewController.loadUrl('https://yourapp.com$url');
    }
  }
  
  void _showLocalNotification(RemoteMessage message) {
    // Show local notification for foreground messages
    // Implementation depends on flutter_local_notifications
  }
}
```

### 6. Notification Payload Structure (dari Laravel)

```json
{
  "notification": {
    "title": "Daily Report Baru",
    "body": "Laporan harian Aisyah tersedia"
  },
  "data": {
    "type": "daily_report",
    "url": "/orangtua/daily-report/123",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

**Key Points untuk Flutter Team:**
- `notification` object → untuk display notification
- `data.url` → relative URL untuk navigate WebView
- `data.type` → untuk custom handling jika diperlukan

---

## 💻 Laravel Implementation Guide

### 1. Database Migration

```php
// database/migrations/xxxx_create_device_tokens_table.php
Schema::create('device_tokens', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('fcm_token')->unique();
    $table->string('device_type')->default('android');  // Android only
    $table->string('device_name')->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamp('last_used_at')->nullable();
    $table->timestamps();
    
    $table->index(['user_id', 'is_active']);
});
```

### 2. Model

```php
// app/Models/DeviceToken.php
class DeviceToken extends Model
{
    protected $fillable = [
        'user_id',
        'fcm_token',
        'device_type',
        'device_name',
        'is_active',
        'last_used_at',
    ];
    
    protected $casts = [
        'is_active' => 'boolean',
        'last_used_at' => 'datetime',
    ];
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

### 3. API Endpoint

```php
// routes/web.php atau api.php
Route::middleware('auth')->group(function () {
    Route::post('/api/device-tokens', [DeviceTokenController::class, 'store']);
    Route::delete('/api/device-tokens', [DeviceTokenController::class, 'destroy']);
});
```

```php
// app/Http/Controllers/DeviceTokenController.php
class DeviceTokenController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string',
            'device_type' => 'nullable|string',  // Android only
            'device_name' => 'nullable|string',
        ]);
        
        DeviceToken::updateOrCreate(
            [
                'user_id' => auth()->id(),
                'fcm_token' => $validated['fcm_token'],
            ],
            [
                'device_type' => $validated['device_type'] ?? null,
                'device_name' => $validated['device_name'] ?? null,
                'is_active' => true,
                'last_used_at' => now(),
            ]
        );
        
        return response()->json(['success' => true]);
    }
    
    public function destroy(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string',
        ]);
        
        DeviceToken::where('user_id', auth()->id())
            ->where('fcm_token', $validated['fcm_token'])
            ->update(['is_active' => false]);
        
        return response()->json(['success' => true]);
    }
}
```

### 4. JavaScript Bridge (Frontend)

```javascript
// resources/js/app.tsx atau layout blade
// Detect if running in Flutter WebView
const isFlutterWebView = typeof window.FlutterBridge !== 'undefined';

if (isFlutterWebView) {
    console.log('Running in Flutter WebView');
    
    // Request FCM token from Flutter
    window.FlutterBridge.postMessage('get_fcm_token');
    
    // Callback function untuk terima token dari Flutter
    window.receiveFCMToken = function(token) {
        console.log('Received FCM token:', token);
        
        // Kirim token ke Laravel backend
        fetch('/api/device-tokens', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                fcm_token: token,
                device_type: detectDeviceType(),
                device_name: navigator.userAgent
            })
        })
        .then(response => response.json())
        .then(data => {
            console.log('FCM token registered:', data);
        })
        .catch(error => {
            console.error('Failed to register FCM token:', error);
        });
    };
}

function detectDeviceType() {
    // Android only
    return 'android';
}
```

### 5. FCM Service

```php
// app/Services/FcmService.php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FcmService
{
    protected $messaging;
    
    public function __construct()
    {
        $factory = (new Factory)->withServiceAccount(
            config('firebase.credentials')
        );
        $this->messaging = $factory->createMessaging();
    }
    
    /**
     * Send notification to specific user
     */
    public function sendToUser(int $userId, string $title, string $body, string $url, array $extraData = [])
    {
        $tokens = DeviceToken::where('user_id', $userId)
            ->where('is_active', true)
            ->pluck('fcm_token')
            ->toArray();
        
        if (empty($tokens)) {
            \Log::info("No active FCM tokens for user {$userId}");
            return;
        }
        
        $data = array_merge([
            'url' => $url,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ], $extraData);
        
        $notification = Notification::create($title, $body);
        
        foreach ($tokens as $token) {
            try {
                $message = CloudMessage::withTarget('token', $token)
                    ->withNotification($notification)
                    ->withData($data);
                
                $this->messaging->send($message);
                
                \Log::info("FCM sent to token: {$token}");
            } catch (\Exception $e) {
                \Log::error("Failed to send FCM: {$e->getMessage()}", [
                    'token' => $token,
                    'user_id' => $userId,
                ]);
                
                // Mark token as inactive if invalid
                if (str_contains($e->getMessage(), 'not-found') || 
                    str_contains($e->getMessage(), 'invalid-registration-token')) {
                    DeviceToken::where('fcm_token', $token)->update(['is_active' => false]);
                }
            }
        }
    }
    
    /**
     * Send notification to multiple users
     */
    public function sendToUsers(array $userIds, string $title, string $body, string $url, array $extraData = [])
    {
        foreach ($userIds as $userId) {
            $this->sendToUser($userId, $title, $body, $url, $extraData);
        }
    }
}
```

### 6. Firebase Configuration

```php
// config/firebase.php
return [
    'credentials' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase-credentials.json')),
];
```

```env
# .env
FIREBASE_CREDENTIALS=/path/to/firebase-credentials.json
```

### 7. Integration dengan Events

```php
// Example: Daily Report Created
public function store(Request $request)
{
    $report = DailyReport::create($validated);
    
    // Send FCM notification
    $siswa = $report->siswa;
    $parentUserId = $siswa->user_id;
    
    app(FcmService::class)->sendToUser(
        userId: $parentUserId,
        title: "Daily Report Baru",
        body: "Laporan harian {$siswa->nama_lengkap} tersedia",
        url: "/orangtua/daily-report/{$report->id}",
        extraData: [
            'type' => 'daily_report',
            'siswa_id' => $siswa->id,
            'report_id' => $report->id,
        ]
    );
    
    return redirect()->back()->with('success', 'Daily report berhasil dibuat');
}
```

```php
// Example: SPP Generated
public function generate()
{
    // ... generate SPP logic ...
    
    foreach ($siswaList as $siswa) {
        $pembayaran = PembayaranSpp::create([...]);
        
        // Send FCM notification
        app(FcmService::class)->sendToUser(
            userId: $siswa->user_id,
            title: "Tagihan SPP Baru",
            body: "Tagihan SPP bulan ini telah tersedia",
            url: "/orangtua/pembayaran",
            extraData: [
                'type' => 'spp_billing',
                'pembayaran_id' => $pembayaran->id,
            ]
        );
        
        sleep(2); // Rate limiting
    }
}
```

---

## 🔑 Key Points untuk Koordinasi

### **Untuk Tim Flutter:**

1. **JavaScript Channel Name**: `FlutterBridge` (harus sama!)
2. **Message untuk request token**: `'get_fcm_token'`
3. **Callback function name**: `window.receiveFCMToken(token)`
4. **Notification data structure**: Selalu ada `data.url` untuk navigation
5. **URL format**: Relative path (e.g., `/orangtua/daily-report/123`)
6. **Base URL**: Akan dikonfigurasi di Flutter (e.g., `https://yourapp.com`)

### **Untuk Tim Laravel:**

1. **API Endpoint**: `POST /api/device-tokens` (authenticated)
2. **Token storage**: Database table `device_tokens`
3. **User identification**: Via `auth()->id()` dari session
4. **Notification payload**: Harus include `data.url` untuk deep linking
5. **Error handling**: Mark token inactive jika FCM return error
6. **Rate limiting**: Tambahkan delay untuk bulk notifications

---

## 🧪 Testing Checklist

### Flutter Side (Android):
- [ ] FCM token berhasil didapat saat app start
- [ ] JavaScript Channel berfungsi (bisa kirim/terima message)
- [ ] Token terkirim ke Laravel setelah login
- [ ] Notification muncul saat app foreground
- [ ] Notification muncul saat app background
- [ ] Notification muncul saat app terminated
- [ ] Tap notification navigate ke URL yang benar
- [ ] Session tetap aktif setelah navigation
- [ ] Token refresh otomatis saat berubah
- [ ] Test di berbagai versi Android (min SDK 21+)

### Laravel Side:
- [ ] API endpoint menerima dan menyimpan token
- [ ] Token tersimpan dengan user_id yang benar
- [ ] FCM Service berhasil kirim notifikasi
- [ ] Notifikasi terkirim ke semua devices user
- [ ] Invalid token di-mark inactive
- [ ] JavaScript bridge terdeteksi di WebView
- [ ] Token terkirim otomatis setelah login
- [ ] Logout mendeactivate token

### Integration:
- [ ] Daily report created → notification terkirim
- [ ] SPP generated → notification terkirim
- [ ] Payment verified → notification terkirim
- [ ] Tap notification → buka halaman yang benar
- [ ] Multiple devices per user berfungsi
- [ ] Rate limiting berfungsi untuk bulk notifications

---

## 📞 Communication Protocol

### Flutter → Laravel:
```javascript
// Request FCM token
FlutterBridge.postMessage('get_fcm_token');

// Flutter akan response via:
window.receiveFCMToken('fcm_token_here');
```

### Laravel → Flutter:
```javascript
// Execute JavaScript di WebView
webViewController.runJavascript("alert('Hello from Laravel')");
```

### Firebase → Flutter:
```json
{
  "notification": { "title": "...", "body": "..." },
  "data": { "url": "/path", "type": "event_type" }
}
```

---

## 🚀 Deployment Steps

### 1. Firebase Setup (One-time)
- [ ] Create Firebase project
- [ ] Enable Cloud Messaging
- [ ] Add Android app to Firebase project
- [ ] Download `google-services.json` (Android)
- [ ] Download service account JSON for Laravel
- [ ] Add SHA-1/SHA-256 fingerprints (Android)

### 2. Flutter Deployment
- [ ] Add `google-services.json` to `android/app/`
- [ ] Update `android/build.gradle` (project level)
- [ ] Update `android/app/build.gradle` (app level)
- [ ] Update `AndroidManifest.xml` permissions
- [ ] Test on real Android devices

### 3. Laravel Deployment
- [ ] Run migration `device_tokens` table
- [ ] Upload Firebase credentials JSON
- [ ] Update `.env` with Firebase path
- [ ] Deploy JavaScript bridge code
- [ ] Test API endpoints

### 4. Integration Testing
- [ ] Test end-to-end flow
- [ ] Verify notifications on Android devices
- [ ] Test different Android versions
- [ ] Load testing untuk bulk notifications

---

## 📚 Resources

### Firebase Documentation:
- [FCM Overview](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Setup](https://firebase.flutter.dev/docs/messaging/overview)
- [Server Setup](https://firebase.google.com/docs/cloud-messaging/server)

### Package Documentation:
- [firebase_messaging (Flutter)](https://pub.dev/packages/firebase_messaging)
- [kreait/firebase-php (Laravel)](https://github.com/kreait/firebase-php)
- [webview_flutter](https://pub.dev/packages/webview_flutter)

---

## ❓ FAQ

**Q: Apakah perlu API token untuk auth?**
A: Tidak. Session Laravel otomatis terbawa di WebView via cookies.

**Q: Bagaimana handle multiple devices per user?**
A: Laravel simpan semua tokens per user_id, kirim ke semua devices.

**Q: Bagaimana handle token expired?**
A: Flutter auto refresh token, kirim ulang ke Laravel. Laravel mark inactive jika FCM return error.

**Q: Apakah bisa kirim notifikasi tanpa internet?**
A: Tidak. FCM butuh internet connection.

**Q: Bagaimana handle logout?**
A: Kirim request ke Laravel untuk deactivate token saat logout.

---

## 📝 Notes

- Dokumen ini adalah living document, akan diupdate sesuai progress development
- Untuk pertanyaan teknis, koordinasi via [channel komunikasi tim]
- Testing harus dilakukan di real device, emulator kadang tidak reliable untuk FCM

---

**Last Updated**: 2025-10-28
**Version**: 1.0
**Maintained by**: Backend Team (Laravel) & Mobile Team (Flutter)
