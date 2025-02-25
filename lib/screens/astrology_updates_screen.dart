import 'package:flutter/material.dart';

class AstrologyUpdatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Astrology Updates'),
        backgroundColor: Colors.teal.shade400,
      ),
      body: Center(
        child: Text(
          'Astrology updates will be available soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
