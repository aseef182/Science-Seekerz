import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  bool _isAppNameDisplayed = false;
  bool _isTaglineDisplayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _playBackgroundMusic();
    _controller.forward().then((_) {
      _playAppNameVoice();
    });

    Timer(Duration(seconds: 15), () {
      _backgroundPlayer.stop();
      _voicePlayer.stop();
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  Future<void> _playBackgroundMusic() async {
    await _backgroundPlayer.play(AssetSource('audio/background_music.mp3'));
    await _backgroundPlayer.setVolume(0.3);
  }

  Future<void> _playAppNameVoice() async {
    await _voicePlayer.play(AssetSource('audio/app_name.mp3'));
    await _voicePlayer.setVolume(1.0);
  }

  Future<void> _playTaglineVoice() async {
    await _voicePlayer.play(AssetSource('audio/tagline.mp3'));
    await _voicePlayer.setVolume(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundPlayer.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE0F7FA),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.6 + (_animation.value * 0.6),
                        child: Transform.rotate(
                          angle: _animation.value * 2 * 3.14,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 250,
                            height: 250,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Learning Science through Fun Videos',
                          textAlign: TextAlign.center,
                          textStyle: GoogleFonts.cabinSketch(
                            textStyle: TextStyle(
                              fontSize: 28,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Colors.black26,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                          speed: Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                      onFinished: () {
                        if (!_isTaglineDisplayed) {
                          _isTaglineDisplayed = true;
                          _playTaglineVoice();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 150.0,
                  height: 150.0,
                  fit: BoxFit.contain,
                  animate: true,
                  repeat: true,
                  reverse: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}