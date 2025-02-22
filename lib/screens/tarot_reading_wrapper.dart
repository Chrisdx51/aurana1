// lib/screens/tarot_reading_wrapper.dart
import 'package:flutter/material.dart';
import 'tarot_reading_screen.dart'; // Adjust the import if the path is different

class TarotReadingWrapper extends StatelessWidget {
  final String userId;

  const TarotReadingWrapper({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // You can pass the userId to the TarotReadingScreen using a constructor or any other method
    return TarotReadingScreen(); // Adjust this line if TarotReadingScreen can accept userId
  }
}
