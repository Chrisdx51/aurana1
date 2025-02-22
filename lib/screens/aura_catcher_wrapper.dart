// lib/screens/aura_catcher_wrapper.dart
import 'package:flutter/material.dart';
import 'aura_catcher_screen.dart'; // Adjust the import if the path is different

class AuraCatcherWrapper extends StatelessWidget {
  final String userId;

  const AuraCatcherWrapper({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // You can pass the userId to the AuraCatcherScreen using a constructor or any other method
    return AuraCatcherScreen(); // Adjust this line if AuraCatcherScreen can accept userId
  }
}
