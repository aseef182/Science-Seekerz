import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DownloadProgressPopup extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;

  const DownloadProgressPopup({
    Key? key,
    required this.progress,
    required this.onCancel,
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
              'Downloading Video',
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ).animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.teal.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.fredoka(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms)
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.fredoka(fontSize: 18),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text("Cancel Download"),
            ).animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
          ],
        ),
      ).animate()
        .scale(duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms),
    );
  }
}
