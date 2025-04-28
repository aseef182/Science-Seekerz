import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'language_selection_screen.dart';
import '../widgets/download_progress_popup.dart';

class VideoSelectionModeScreen extends StatefulWidget {
  final String videoTitle;

  const VideoSelectionModeScreen({Key? key, required this.videoTitle}) : super(key: key);

  @override
  _VideoSelectionModeScreenState createState() => _VideoSelectionModeScreenState();
}

class _VideoSelectionModeScreenState extends State<VideoSelectionModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<String?> _getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Create directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      print('Error getting download path: $e');
      return null;
    }
    return directory?.path;
  }

  Future<void> _downloadVideo(String language) async {
    // First check for storage permission
    if (!await _requestStoragePermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission is required to download videos'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final String? downloadPath = await _getDownloadPath();
    if (downloadPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access download directory'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _cancelToken = CancelToken();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final String videoPath = 'Videos/$language/${widget.videoTitle.replaceAll(' ', '_')}.mp4';
      final String videoUrl = await FirebaseStorage.instance.ref(videoPath).getDownloadURL();
      
      final dio = Dio(BaseOptions(
        receiveTimeout: Duration(seconds: 60),
        connectTimeout: Duration(seconds: 30),
      ));
      
      final filePath = '$downloadPath/${widget.videoTitle}_$language.mp4';

      await dio.download(
        videoUrl,
        filePath,
        cancelToken: _cancelToken,
        options: Options(
          headers: {
            'Accept-Encoding': 'gzip, deflate',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (!_cancelToken!.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video downloaded successfully to Downloads folder!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!_cancelToken!.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && !_cancelToken!.isCancelled) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.videoTitle,
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Color(0xFF00796B),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedTitle(),
                  SizedBox(height: 60),
                  _buildButtons(),
                ],
              ),
            ),
          ),
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: DownloadProgressPopup(
                progress: _downloadProgress,
                onCancel: _cancelDownload,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F7FA),
                Color(0xFFB2EBF2),
                Color(0xFF80DEEA),
                Color(0xFF4DD0E1),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 800.ms)
          .scaleXY(begin: 1.1, end: 1.0),
        ...List.generate(10, (index) {
          final random = index * 0.1;
          return Positioned(
            left: MediaQuery.of(context).size.width * (0.1 + random),
            top: MediaQuery.of(context).size.height * (0.1 + random),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            )
              .scaleXY(
                begin: 0.5,
                end: 1.5,
                duration: 3000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scaleXY(
                begin: 1.5,
                end: 0.5,
                duration: 3000.ms,
                curve: Curves.easeInOut,
              )
              .moveY(
                begin: 0,
                end: 50,
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: 50,
                end: 0,
                duration: 4000.ms,
                curve: Curves.easeInOut,
              ),
          );
        }),
      ],
    );
  }

  Widget _buildAnimatedTitle() {
    return Column(
      children: [
        Icon(
          Icons.play_circle_filled,
          size: 80,
          color: Color(0xFF00796B),
        ).animate()
          .fadeIn(duration: 600.ms)
          .scale(duration: 800.ms, curve: Curves.elasticOut)
          .then()
          .rotate(
            duration: 2000.ms,
            begin: 0,
            end: 0.1,
          )
          .then()
          .rotate(
            duration: 2000.ms,
            begin: 0.1,
            end: -0.1,
          )
          .then()
          .rotate(
            duration: 2000.ms,
            begin: -0.1,
            end: 0,
          ),
        SizedBox(height: 20),
        Text(
          'Choose Your\nPreferred Mode',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: Color(0xFF00796B),
            ),
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.2, end: 0)
          .then()
          .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.8))
          .then(delay: 2000.ms)
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .scaleXY(
            begin: 1,
            end: 1.05,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scaleXY(
            begin: 1.05,
            end: 1,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        _buildModeButton(
          context,
          'Play Online',
          Color(0xFF00C853),
          Icons.play_circle_filled,
          false,
        ),
        SizedBox(height: 20),
        _buildModeButton(
          context,
          'Download',
          Color(0xFF2979FF),
          Icons.download,
          true,
        ),
      ],
    ).animate()
      .fadeIn(duration: 800.ms)
      .scale(duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildModeButton(BuildContext context, String mode, Color color, IconData icon, bool isDownload) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton.icon(
        onPressed: () {
          if (isDownload) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LanguageSelectionScreen(
                  title: widget.videoTitle,
                  onLanguageSelected: (language) => _downloadVideo(language),
                  buttonText: 'Download in',
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LanguageSelectionScreen(
                  title: widget.videoTitle,
                ),
              ),
            );
          }
        },
        icon: Icon(icon, size: 28, color: Colors.white),
        label: Text(
          mode,
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 2000.ms, delay: 1000.ms)
      .then()
      .animate(onPlay: (controller) => controller.repeat())
      .scaleXY(begin: 1, end: 1.02, duration: 2000.ms)
      .then()
      .scaleXY(begin: 1.02, end: 1, duration: 2000.ms);
  }
}