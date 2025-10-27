import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final String _homeUrl = 'https://dev-schalbiruni.myserverku.web.id/login';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkConnectivity();
    _initializeWebView();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request camera and photo permissions
      await Permission.camera.request();
      await Permission.photos.request();
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      // Request location permissions for attendance feature
      await Permission.location.request();
      await Permission.locationWhenInUse.request();
    } else if (Platform.isIOS) {
      // Request camera and photo permissions
      await Permission.camera.request();
      await Permission.photos.request();

      // Request location permissions for attendance feature
      await Permission.location.request();
      await Permission.locationWhenInUse.request();
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = !connectivityResult.contains(ConnectivityResult.none);
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      setState(() {
        _hasInternet = !result.contains(ConnectivityResult.none);
      });
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
      ..loadRequest(Uri.parse(_homeUrl));
  }

  void _reloadPage() {
    _checkConnectivity();
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
