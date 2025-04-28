import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import firebase_app_check
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart'; // Import the home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Disable App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use debug provider for Android (disables enforcement)
  );

  runApp(ScienceSeerkrzApp());
}

class ScienceSeerkrzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Science Seerkrz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFE0F7FA), // Set the primary color to the desired theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/', // Define the initial route
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(), // Define the route for HomeScreen
      },
    );
  }
}
