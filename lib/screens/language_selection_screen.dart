import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'video_player_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final String title;
  final String? buttonText;

  final void Function(String language)? onLanguageSelected;

  LanguageSelectionScreen({
    required this.title,
    this.onLanguageSelected,
    this.buttonText,
  });

  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.title,  // Updated from 'Select Language' to widget.title
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
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE0F7FA),
          image: DecorationImage(
            image: AssetImage('assets/images/language_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                _buildAnimatedTitle(),
                SizedBox(height: 40),
                ScaleTransition(
                  scale: _animation,
                  child: _buildLanguageButton(
                    context,
                    'English',
                    Color(0xFF00C853),
                    Icons.language,
                  ),
                ),
                SizedBox(height: 20),
                ScaleTransition(
                  scale: _animation,
                  child: _buildLanguageButton(
                    context,
                    'Urdu',
                    Color(0xFF2979FF),
                    null,
                    'assets/images/urdu_icon.png',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return Text(
      'Choose Your\nPreferred Language',
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
      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.8));
  }

  Widget _buildLanguageButton(BuildContext context, String language, Color color, IconData? icon, [String? imageAsset]) {
    return ElevatedButton.icon(
      onPressed: () {
        if (widget.onLanguageSelected != null) {
          widget.onLanguageSelected!(language);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                title: widget.title,  // Updated from videoTitle
                language: language,
              ),
            ),
          );
        }
      },
      icon: imageAsset != null
          ? Image.asset(
              imageAsset,
              width: 28,
              height: 28,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            )
          : Icon(icon, size: 28, color: Colors.white),
      label: Text(
        widget.buttonText != null 
            ? '${widget.buttonText} $language'
            : 'Watch in $language',
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
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideX(begin: -0.2, end: 0)
      .then()
      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.8));
  }
}