import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ActivityScreen extends StatefulWidget {
  final String activityUrl;
  final String activityTitle;

  const ActivityScreen({
    Key? key,
    required this.activityUrl,
    required this.activityTitle,
  }) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with WidgetsBindingObserver {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _webViewController = WebViewController();
    _preloadResources();
  }

  Future<void> _preloadResources() async {
    if (!await _checkConnectivity()) {
      _handleError();
      return;
    }
    await _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      await _webViewController.clearCache();
      await _webViewController.clearLocalStorage();
      _webViewController
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFE0F7FA))
        ..enableZoom(false)
        ..setUserAgent('Mobile')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (_) => _handleError(),
            onNavigationRequest: (request) {
              final url = request.url.toLowerCase();
              if (url.contains('analytics') || url.contains('tracking') || url.contains('ads')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      final cachedFile = await _cacheManager.getFileFromCache(widget.activityUrl);
      if (cachedFile != null) {
        await _webViewController.loadFile(cachedFile.file.path);
      } else {
        await _webViewController.loadRequest(
          Uri.parse(widget.activityUrl),
          headers: {'Cache-Control': 'max-age=3600'},
        );
      }
    } catch (e) {
      print('WebView initialization error: $e');
      _handleError();
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      print("Connectivity Result: $result"); // Debugging
      return result != ConnectivityResult.none;
    } catch (e) {
      print("Connectivity Check Failed: $e"); // Debugging
      return false;
    }
  }

  void _handleError() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: Text(
          widget.activityTitle,
          style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00796B),
      ),
      body: Stack(
        children: [
          if (!_isLoading && !_hasError)
            WebViewWidget(controller: _webViewController),
          if (_isLoading) const _LoadingDisplay(),
          if (_hasError) _ErrorDisplay(onRetry: _initializeWebView),
        ],
      ),
    );
  }
}

class _LoadingDisplay extends StatelessWidget {
  const _LoadingDisplay();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00796B)),
          const SizedBox(height: 20),
          Text(
            'Getting ready...',
            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
          ),
        ],
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorDisplay({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Color(0xFF00796B)),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00796B)),
            child: Text('Try Again', style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
