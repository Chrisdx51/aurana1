import 'package:flutter/material.dart';

class HoroscopeScreen extends StatelessWidget {
  final String zodiacSign;

  const HoroscopeScreen({Key? key, required this.zodiacSign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$zodiacSign Horoscope'),
        backgroundColor: Colors.teal.shade400,
      ),
      body: Center(
        child: Text(
          'Horoscope for $zodiacSign is coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
