import 'package:flutter/material.dart';
import 'dart:async';
import 'auth_screen.dart'; // Update this to the correct home screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthScreen()), // ✅ Use AuthScreen

      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset("assets/media/splash.gif", fit: BoxFit.cover),
      ),
    );
  }
}
