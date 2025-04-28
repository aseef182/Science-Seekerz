import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_selection_screen.dart';
import 'video_selection_mode_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, String>> videos = [
    {"title": "Our Solar System", "thumbnail": "assets/images/solar_system.jpg"},
    {"title": "Water Cycle", "thumbnail": "assets/images/water_cycle.jpg"},
    {"title": "Human Body Parts", "thumbnail": "assets/images/body_parts.jpg"},
    {"title": "States of matter", "thumbnail": "assets/images/States_of_matter.jpg"},
    {"title": "Photosynthesis Process", "thumbnail": "assets/images/photosynthesis.jpg"},
    {"title": "Five Senses", "thumbnail": "assets/images/five_senses.jpg"},
    {"title": "Electricity", "thumbnail": "assets/images/electricity.jpg"},
    {"title": "Plant Life Cycle", "thumbnail": "assets/images/plant_life_cycle.jpg"},
    {"title": "Weather and Seasons", "thumbnail": "assets/images/Weather_and_Seasons.jpg"},
    {"title": "Force", "thumbnail": "assets/images/Force.jpg"},

  ];

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 10), vsync: this)..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        exit(0);
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F7FA),
                Color(0xFF80DEEA),
                Color(0xFF4DD0E1),
                Color(0xFF26C6DA),
              ],
              stops: [
                _animation.value,
                (_animation.value + 0.3) % 1,
                (_animation.value + 0.6) % 1,
                (_animation.value + 0.9) % 1,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Color(0xFF00796B).withOpacity(0.8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Text(
              'Science Seekrz',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
            ),
          ),
          expandedHeight: 80,
          collapsedHeight: 80,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Explore Science Videos',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoCard(index),
              childCount: videos.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(int index) {
    return GestureDetector(
      onTap: () => _onVideoTap(index),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                videos[index]['thumbnail']!,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videos[index]['title']!,
                    style: GoogleFonts.fredoka(
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Icon(Icons.play_circle_filled, color: Colors.white, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onVideoTap(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>  VideoSelectionModeScreen(
          videoTitle: videos[index]['title']!,
        ),
      ),
    );
  }
}