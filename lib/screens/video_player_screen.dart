import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'activity_screen.dart';
import '../widgets/video_completion_popup.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String language;

  const VideoPlayerScreen({
    Key? key,
    required this.title,
    required this.language,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showPopUp = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _initializeVideoLoading();
  }

  Future<void> _initializeVideoLoading() async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _showNetworkErrorDialog();
        return;
      }

      // Prepare video path
      String videoPath = 'Videos/${widget.language}/${widget.title.replaceAll(' ', '_')}.mp4';
      _videoUrl = await FirebaseStorage.instance.ref(videoPath).getDownloadURL();

      // Start background download and caching
      await _prepareVideoWithBackgroundDownload();
    } catch (e) {
      print("Error preparing video: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _prepareVideoWithBackgroundDownload() async {
  try {
    if (_videoUrl == null) {
      throw Exception('Video URL is null');
    }

    // Download file in background with error handling
    try {
      await compute(_downloadAndCacheVideo, _videoUrl!);
    } catch (e) {
      print("Background download error: $e");
      // Continue execution to check cache
    }

    // Get cached file
    File? cachedFile = await _getCachedFile(_videoUrl!);
    
    if (cachedFile == null) {
      throw Exception('Failed to cache video file');
    }

    // Initialize video controller with error handling
    try {
      _controller = VideoPlayerController.file(cachedFile);
      await _controller.initialize();
    } catch (e) {
      throw Exception('Failed to initialize video controller: $e');
    }
    
    // Configure additional controller settings
    _controller.setVolume(0.7);
    _controller.addListener(_onVideoProgressChanged);

    // Create Chewie controller with error handling
    try {
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        customControls: CustomControls(
          onVideoComplete: _onVideoComplete,
        ),
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        progressIndicatorDelay: const Duration(seconds: 0),
        placeholder: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Preparing video...'),
            ],
          ),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: Colors.deepOrangeAccent,
          handleColor: Colors.deepOrangeAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.deepOrangeAccent,
          handleColor: Colors.deepOrangeAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
      );
    } catch (e) {
      throw Exception('Failed to create video player interface: $e');
    }

    // Update state only if the widget is still mounted
    if (!mounted) {
      return;
    }
    
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
    
  } catch (e) {
    print("Error in video preparation: $e");
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
    
    // Clean up resources in case of error
    _controller.dispose();
    _chewieController?.dispose();
  }
}

  // Helper method to get cached file safely
  Future<File?> _getCachedFile(String url) async {
    try {
      FileInfo? cachedFile = await DefaultCacheManager().getFileFromCache(url);
      return cachedFile?.file ?? await DefaultCacheManager().getSingleFile(url);
    } catch (e) {
      print("Error getting cached file: $e");
      return null;
    }
  }

static Future<FileInfo> _downloadAndCacheVideo(String videoUrl) async {
  try {
    final result = await DefaultCacheManager().downloadFile(videoUrl).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Video download timed out after 30 seconds');
      },
    );
    
    if (result == null) {
      throw StateError('Download completed but no file was retrieved');
    }
    
    return result;
  } catch (e) {
    print('Background download error: $e');
    throw Exception('Failed to download video: $e');
  }
}

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Error'),
        content: const Text('No internet connection. Please check your network and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeVideoLoading();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onVideoProgressChanged() {
    if (_controller.value.hasError) {
      print("Video Error: ${_controller.value.errorDescription}");
      setState(() {
        _hasError = true;
      });
    } else if (_controller.value.position >= _controller.value.duration) {
      _onVideoComplete();
    }
  }

  void _onVideoComplete() {
    if (_chewieController != null && _chewieController!.isFullScreen) {
      _chewieController!.exitFullScreen();
    }

    setState(() {
      _showPopUp = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onVideoProgressChanged);
    _chewieController?.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _playVideoAgain() {
    setState(() {
      _showPopUp = false;
    });
    _controller.seekTo(Duration.zero);
    _controller.play();
  }

  void _exitToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _playActivity() async {
    String activityUrl = await getActivityUrl(widget.title);
    if (activityUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityScreen(
            activityUrl: activityUrl,
            activityTitle: widget.title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load activity. Please try again later.')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.play();
    } else if (state == AppLifecycleState.inactive) {
      _controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.fredoka(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.deepOrangeAccent,
            ),
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: SpinKitDoubleBounce(
                color: Colors.teal,
                size: 60.0,
              ),
            )
          else if (_hasError)
            const KidFriendlyErrorWidget()
          else
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: _chewieController != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Chewie(controller: _chewieController!),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          if (_showPopUp)
            AnimatedOpacity(
              opacity: _showPopUp ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: VideoCompletionPopup(
                    onPlayActivity: _playActivity,
                    onWatchAgain: _playVideoAgain,
                    onExit: _exitToHome,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<String> getActivityUrl(String videoTitle) async {
    try {
      String activityPath = 'Activities/${videoTitle.replaceAll(' ', '_')}.html';
      return await FirebaseStorage.instance.ref(activityPath).getDownloadURL();
    } catch (e) {
      print("Error fetching activity URL: $e");
      return '';
    }
  }
}

class KidFriendlyErrorWidget extends StatelessWidget {
  const KidFriendlyErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied,
              size: 100,
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
            Text(
              "Oops! The video is hiding!",
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(
                  fontSize: 24,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Let's try again later!",
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomControls extends StatefulWidget {
  final VoidCallback onVideoComplete;

  const CustomControls({Key? key, required this.onVideoComplete}) : super(key: key);

  @override
  _CustomControlsState createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _handleTap() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AbsorbPointer(
        absorbing: !_showControls,
        child: Stack(
          children: <Widget>[
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: _buildCenterControls(context),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildBottomControls(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSkipBack(context),
        const SizedBox(width: 20),
        _buildPlayPause(context),
        const SizedBox(width: 20),
        _buildSkipForward(context),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          _buildPosition(context),
          Expanded(child: _buildProgressBar(context)),
          _buildDuration(context),
          _buildMute(context),
          _buildFullScreenButton(context),
        ],
      ),
    );
  }

  Widget _buildPlayPause(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: chewieController.videoPlayerController,
      builder: (context, value, child) {
        return IconButton(
          iconSize: 70,
          icon: Icon(
            value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white,
          ),
          onPressed: () {
            chewieController.togglePause();
            _startHideTimer();
          },
        );
      },
    );
  }

  Widget _buildSkipBack(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return IconButton(
      iconSize: 50,
      icon: const Icon(Icons.replay_10, color: Colors.white),
      onPressed: () {
        final position = chewieController.videoPlayerController.value.position;
        chewieController.seekTo(position - const Duration(seconds: 10));
        _startHideTimer();
      },
    );
  }

  Widget _buildSkipForward(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return IconButton(
      iconSize: 50,
      icon: const Icon(Icons.forward_10, color: Colors.white),
      onPressed: () {
        final position = chewieController.videoPlayerController.value.position;
        chewieController.seekTo(position + const Duration(seconds: 10));
        _startHideTimer();
      },
    );
  }

  Widget _buildMute(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: chewieController.videoPlayerController,
      builder: (context, value, child) {
        return IconButton(
          iconSize: 30,
          icon: Icon(
            value.volume > 0 ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
          onPressed: () {
            chewieController.setVolume(value.volume > 0 ? 0 : 1);
          },
        );
      },
    );
  }

  Widget _buildPosition(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: chewieController.videoPlayerController,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            _formatDuration(value.position),
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildDuration(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: chewieController.videoPlayerController,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            _formatDuration(value.duration),
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return ValueListenableBuilder(
      valueListenable: chewieController.videoPlayerController,
      builder: (context, VideoPlayerValue value, child) {
        return Slider(
          value: value.position.inMilliseconds.toDouble(),
          min: 0,
          max: value.duration.inMilliseconds > 0 ? value.duration.inMilliseconds.toDouble() : 1.0,
          onChanged: (newPosition) {
            chewieController.seekTo(Duration(milliseconds: newPosition.round()));
          },
          activeColor: Colors.deepOrangeAccent,
          inactiveColor: Colors.white24,
        );
      },
    );
  }

  Widget _buildFullScreenButton(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    return IconButton(
      iconSize: 40,
      icon: Icon(
        chewieController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
        color: Colors.yellow,
      ),
      onPressed: chewieController.toggleFullScreen,
    );
  }
}