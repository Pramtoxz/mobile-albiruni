# FCM Testing Guide
## Laravel Backend + Flutter WebView

---

## ✅ Backend Implementation Complete

Backend Laravel sudah siap dengan komponen berikut:

### 1. Database
- ✅ Table `device_tokens` untuk simpan FCM token
- ✅ Migration sudah dijalankan

### 2. API Endpoints
- ✅ `POST /api/device-tokens` - Register FCM token
- ✅ `DELETE /api/device-tokens` - Deactivate token (logout)

### 3. Services
- ✅ `FcmService` - Kirim notifikasi via Firebase
- ✅ `DeviceTokenController` - Handle token registration

### 4. Integration
- ✅ Daily Report created → FCM notification
- ✅ SPP generated → FCM notification
- ✅ JavaScript bridge di `resources/js/app.tsx`

### 5. Configuration
- ✅ Firebase credentials di `app/Providers/albiruni-pre-school-firebase-adminsdk-fbsvc-9724349ba8.json`
- ✅ Config file `config/firebase.php`

---

## 🧪 Testing Steps

### Step 1: Flutter Setup (Tim Flutter)

**A. Pastikan google-services.json sudah ada**
```
android/
  app/
    google-services.json  ← File ini harus ada
```

**B. Implement FCM di Flutter**

Lihat dokumentasi lengkap di `FIREBASE_PUSH_NOTIFICATION.md` section "Flutter Implementation Guide"

Key points:
1. Initialize Firebase
2. Get FCM token
3. Setup JavaScript Channel dengan nama `FlutterBridge`
4. Handle notification tap

**C. JavaScript Channel Contract**

Flutter harus expose channel dengan nama: `FlutterBridge`

```dart
JavascriptChannel(
  name: 'FlutterBridge',  // HARUS nama ini!
  onMessageReceived: (JavascriptMessage message) {
    if (message.message == 'get_fcm_token') {
      // Get FCM token dan kirim balik ke WebView
      String? token = await FirebaseMessaging.instance.getToken();
      webViewController.runJavascript(
        "window.receiveFCMToken('$token')"
      );
    }
  },
)
```

---

### Step 2: Test Token Registration

**A. Login ke aplikasi via Flutter WebView**

**B. Check browser console (jika bisa debug WebView)**

Harus muncul log:
```
[FCM] Running in Flutter WebView
[FCM] User authenticated, requesting FCM token from Flutter
[FCM] Received token from Flutter: xxxxxx...
[FCM] Token registered successfully
```

**C. Check database**

```sql
SELECT * FROM device_tokens WHERE user_id = [your_user_id];
```

Harus ada record dengan:
- `fcm_token` = token dari Flutter
- `is_active` = 1
- `device_type` = 'android'

**D. Check Laravel logs**

```
storage/logs/laravel.log
```

Harus ada log:
```
[INFO] FCM token registered {"user_id":1,"device_type":"android"}
```

---

### Step 3: Test Notification Sending

**A. Test Daily Report Notification**

1. Login sebagai Guru
2. Buat daily report baru
3. Check Laravel logs:
   ```
   [INFO] FCM notification sent {"token":"xxx...","user_id":1,"title":"Daily Report Baru"}
   ```

4. Notification harus muncul di device Android
5. Tap notification → WebView navigate ke `/orangtua/daily-report/{id}`

**B. Test SPP Notification**

1. Login sebagai Admin
2. Generate tagihan SPP
3. Check Laravel logs untuk setiap siswa
4. Notification harus muncul di device orang tua
5. Tap notification → WebView navigate ke `/orangtua/pembayaran`

---

### Step 4: Test Notification States

**A. Foreground (App terbuka)**
- Notification harus muncul sebagai local notification
- Tap → navigate ke URL yang sesuai

**B. Background (App di background)**
- Notification muncul di notification tray
- Tap → app terbuka dan navigate ke URL

**C. Terminated (App ditutup)**
- Notification muncul di notification tray
- Tap → app terbuka dan navigate ke URL

---

## 🔍 Debugging

### Problem: Token tidak terkirim ke Laravel

**Check:**
1. Apakah JavaScript Channel sudah di-setup dengan nama `FlutterBridge`?
2. Apakah user sudah login? (meta tag `user-authenticated` = true)
3. Apakah CSRF token ada di meta tag?
4. Check browser console untuk error

**Solution:**
```dart
// Pastikan channel name exact match
JavascriptChannel(
  name: 'FlutterBridge',  // Harus persis ini
  ...
)
```

### Problem: Notification tidak muncul

**Check:**
1. Apakah FCM token sudah registered di database?
2. Check Laravel logs untuk error saat kirim notifikasi
3. Apakah Firebase credentials valid?
4. Apakah notification permission sudah granted di Android?

**Solution:**
```dart
// Request permission
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

### Problem: Notification muncul tapi tap tidak navigate

**Check:**
1. Apakah `data.url` ada di payload?
2. Apakah Flutter handle `onMessageOpenedApp`?
3. Check format URL (harus relative path)

**Solution:**
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  String? url = message.data['url'];
  if (url != null) {
    webViewController.loadUrl('https://yourapp.com$url');
  }
});
```

### Problem: Token marked as inactive

**Reason:**
FCM return error "not-found" atau "invalid-registration-token"

**Solution:**
1. Token expired → Flutter harus refresh dan kirim ulang
2. App di-uninstall → Token invalid, normal behavior

```dart
// Listen token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // Kirim token baru ke Laravel
  window.FlutterBridge.postMessage('get_fcm_token');
});
```

---

## 📊 Monitoring

### Check Active Tokens

```sql
SELECT 
    u.name,
    u.email,
    dt.device_type,
    dt.is_active,
    dt.last_used_at,
    dt.created_at
FROM device_tokens dt
JOIN users u ON dt.user_id = u.id
WHERE dt.is_active = 1
ORDER BY dt.last_used_at DESC;
```

### Check Notification Logs

```bash
# Laravel logs
tail -f storage/logs/laravel.log | grep FCM

# Filter by user
tail -f storage/logs/laravel.log | grep "user_id\":1"
```

### Test Send Notification Manually

```php
// Tinker
php artisan tinker

// Send test notification
$fcmService = app(\App\Services\FcmService::class);
$fcmService->sendToUser(
    userId: 1,
    title: 'Test Notification',
    body: 'This is a test',
    url: '/dashboard',
    extraData: ['type' => 'test']
);
```

---

## 🎯 Success Criteria

### ✅ Token Registration
- [ ] Token tersimpan di database setelah login
- [ ] Token ter-update jika refresh
- [ ] Token ter-deactivate setelah logout

### ✅ Notification Delivery
- [ ] Notification muncul saat daily report created
- [ ] Notification muncul saat SPP generated
- [ ] Notification muncul di foreground
- [ ] Notification muncul di background
- [ ] Notification muncul saat app terminated

### ✅ Navigation
- [ ] Tap notification navigate ke URL yang benar
- [ ] Session tetap aktif setelah navigation
- [ ] Deep linking berfungsi untuk semua routes

### ✅ Error Handling
- [ ] Invalid token di-mark inactive
- [ ] Error logged dengan detail
- [ ] App tidak crash jika notification gagal

---

## 📝 Notes untuk Tim Flutter

### JavaScript Bridge Contract

**Laravel akan call:**
```javascript
window.FlutterBridge.postMessage('get_fcm_token');
```

**Flutter harus response dengan:**
```javascript
window.receiveFCMToken('fcm_token_here');
```

### Notification Payload Structure

```json
{
  "notification": {
    "title": "Judul Notifikasi",
    "body": "Isi notifikasi"
  },
  "data": {
    "url": "/path/to/page",
    "type": "event_type",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

**Important:**
- `data.url` = relative path untuk navigation
- `data.type` = untuk custom handling (optional)
- Base URL harus ditambahkan di Flutter: `https://yourapp.com` + `data.url`

### Authentication

- Session auth Laravel otomatis terbawa via cookies
- Tidak perlu API token atau OAuth
- Meta tag `user-authenticated` untuk detect login status

---

## 🚀 Next Steps

1. **Tim Flutter**: Implement FCM sesuai guide di `FIREBASE_PUSH_NOTIFICATION.md`
2. **Testing**: Follow testing steps di dokumen ini
3. **Integration**: Test end-to-end flow
4. **Production**: Deploy dan monitor logs

---

**Last Updated**: 2025-10-28
**Status**: Backend Ready, Waiting Flutter Implementation
