# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase Core - CRITICAL for FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepclassmembers class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging - CRITICAL for FCM Token
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.installations.** { *; }
-keepclassmembers class com.google.firebase.messaging.** { *; }

# Keep FirebaseMessagingService
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }

# Flutter Firebase Messaging Plugin
-keep class io.flutter.plugins.firebase.** { *; }
-keep class io.flutter.plugins.firebasemessaging.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# WebView - CRITICAL for JavaScript Bridge and Cookies
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-keep class android.webkit.** { *; }
-keepclassmembers class android.webkit.WebView { *; }
-keep class android.webkit.WebViewClient { *; }
-keep class android.webkit.WebChromeClient { *; }
-keep class android.webkit.CookieManager { *; }
-keep class android.webkit.WebStorage { *; }
-keep class android.webkit.WebSettings { *; }

# Keep JavaScript interface methods
-keepclassmembers class * {
    public void *(android.webkit.WebView, java.lang.String);
}

# WebView Flutter Plugin - CRITICAL
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keepclassmembers class io.flutter.plugins.webviewflutter.** { *; }

# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Hide warnings
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Play Core (Flutter deferred components - not used but referenced)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
