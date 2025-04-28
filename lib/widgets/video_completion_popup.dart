import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoCompletionPopup extends StatelessWidget {
  final VoidCallback onPlayActivity;
  final VoidCallback onWatchAgain;
  final VoidCallback onExit;

  const VideoCompletionPopup({
    Key? key,
    required this.onPlayActivity,
    required this.onWatchAgain,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Video Completed!',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'What would you like to do next?',
              style: GoogleFonts.fredoka(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Play Activity"),
              onPressed: onPlayActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.fredoka(fontSize: 18),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text("Watch Again"),
              onPressed: onWatchAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.fredoka(fontSize: 18),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text("Exit"),
              onPressed: onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.fredoka(fontSize: 18),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}