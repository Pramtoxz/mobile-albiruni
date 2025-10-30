import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'services/fcm_service.dart';
import 'services/notification_handler.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log(
    '[FCM] Background message: ${message.notification?.title}',
    name: 'FCM',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM Service
  await FcmService().initialize();

  // Mengunci orientasi ke mode potret (tegak)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Biruni Preschool Day Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Warna utama diubah menjadi ##00AEE9
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00AEE9)),
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWebView();
  }

  void _navigateToWebView() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WebViewPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/logoalbiruni.png', width: 250),
            const SizedBox(height: 16),
            Lottie.asset(
              'assets/lottie/splash.json',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              // Teks judul diubah
              child: Text(
                'We Care for Your Child\'s Future',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // Warna teks judul diubah
                  color: Color(0xFF00AEE9),
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              // Teks subjudul diubah
              child: Text(
                'Tempat Terbaik untuk Tumbuh dan Belajar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;
  NotificationHandler? _notificationHandler;

  final String _homeUrl = 'https://dev-schalbiruni.myserverku.web.id/login';
  final FcmService _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkConnectivity();
    _initializeWebView();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request camera permission only if not granted
      if (!await Permission.camera.isGranted) {
        await Permission.camera.request();
      }

      // Request photo/storage permissions only if not granted
      if (!await Permission.photos.isGranted) {
        await Permission.photos.request();
      }

      if (await Permission.storage.isDenied &&
          !await Permission.storage.isPermanentlyDenied) {
        await Permission.storage.request();
      }

      // Request location permissions only if not granted
      if (!await Permission.location.isGranted) {
        await Permission.location.request();
      }
      if (!await Permission.locationWhenInUse.isGranted) {
        await Permission.locationWhenInUse.request();
      }
    } else if (Platform.isIOS) {
      // Request camera permission only if not granted
      if (!await Permission.camera.isGranted) {
        await Permission.camera.request();
      }

      // Request photo permissions only if not granted
      if (!await Permission.photos.isGranted) {
        await Permission.photos.request();
      }

      // Request location permissions only if not granted
      if (!await Permission.location.isGranted) {
        await Permission.location.request();
      }
      if (!await Permission.locationWhenInUse.isGranted) {
        await Permission.locationWhenInUse.request();
      }
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = !connectivityResult.contains(ConnectivityResult.none);
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _controller.runJavaScript("document.body.style.zoom = '100%'");

            // Automatically send FCM token to WebView after page loads
            _sendTokenToWebView();
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading page: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      // Add JavaScript Channel for FCM
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(_homeUrl));

    // Setup Android WebView
    if (Platform.isAndroid) {
      if (!kReleaseMode) {
        AndroidWebViewController.enableDebugging(true);
      }

      final androidController =
          _controller.platform as AndroidWebViewController;

      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnShowFileSelector(_onShowFileSelector);
    }

    // Initialize notification handler
    _notificationHandler = NotificationHandler(
      webViewController: _controller,
      baseUrl: _homeUrl,
    );
    _notificationHandler!.initialize();
  }

  Future<void> _sendTokenToWebView() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    String? token = await _fcmService.getToken();
    if (token == null) {
      await Future.delayed(const Duration(seconds: 1));
      token = await _fcmService.getToken();
    }

    if (token != null) {
      try {
        await _controller.runJavaScript("""
          (function() {
            var token = '$token';
            console.log('[FCM] Token:', token);
            
            if (typeof window.receiveFCMToken === 'undefined') {
              window.receiveFCMToken = function(t) {
                fetch('/api/device-tokens', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || ''
                  },
                  body: JSON.stringify({
                    fcm_token: t,
                    device_type: 'android',
                    device_name: navigator.userAgent
                  })
                })
                .then(r => r.json())
                .then(d => console.log('[FCM] OK:', d))
                .catch(e => console.error('[FCM] Err:', e));
              };
            }
            
            window.receiveFCMToken(token);
          })();
        """);
      } catch (e) {
        developer.log('[FCM] JS Error: $e', name: 'FCM');
      }
    } else {
      developer.log(
        '[FCM] Token is null after retry, cannot send',
        name: 'FCM',
      );
    }
  }

  void _handleJavaScriptMessage(String message) async {
    developer.log('[FCM] JavaScript message: $message', name: 'FCM');

    if (message == 'get_fcm_token') {
      // Get FCM token and send back to WebView
      String? token = await _fcmService.getToken();
      if (token != null) {
        developer.log('[FCM] Sending token to WebView: $token', name: 'FCM');
        _controller.runJavaScript("window.receiveFCMToken('$token')");
      } else {
        developer.log('[FCM] Token is null', name: 'FCM');
      }
    }
  }

  Future<List<String>> _onShowFileSelector(FileSelectorParams params) async {
    final ImagePicker picker = ImagePicker();

    // Show dialog to choose source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Pilih Sumber',
            style: TextStyle(fontFamily: 'PlusJakartaSans'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00AEE9)),
                title: const Text(
                  'Kamera',
                  style: TextStyle(fontFamily: 'PlusJakartaSans'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF00AEE9),
                ),
                title: const Text(
                  'Galeri',
                  style: TextStyle(fontFamily: 'PlusJakartaSans'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return [];

    try {
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        // Return file URI with proper format for WebView
        final File file = File(photo.path);
        if (await file.exists()) {
          // Use file:// URI scheme for proper file handling
          return ['file://${photo.path}'];
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return [];
  }

  Future<void> _reloadPage() async {
    await _checkConnectivity();
    if (_hasInternet) {
      _controller.loadRequest(Uri.parse(_homeUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/nointernet.json',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Tidak Ada Koneksi Internet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00AEE9),
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Periksa koneksi internet Anda dan coba lagi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _reloadPage,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Muat Ulang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEE9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _controller.canGoBack()) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            // Warna AppBar diubah
            backgroundColor: const Color(0xFF00AEE9),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            // Tombol 'leading' (kembali) dihilangkan secara otomatis
            automaticallyImplyLeading: false,
            titleSpacing: 16, // Memberi sedikit jarak dari kiri
            title: const Row(
              children: [
                Text(
                  'Al-Biruni Preschool Day Care',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            // Semua tombol 'actions' telah dihilangkan
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                // Warna indikator loading diubah
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00AEE9)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
