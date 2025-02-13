import 'dart:io';
import 'package:flutter/material.dart';

class AuraDetailScreen extends StatelessWidget {
  final String imagePath;
  final String auraMeaning;
  final Color auraColor;
  final String timestamp;

  const AuraDetailScreen({
    Key? key,
    required this.imagePath,
    required this.auraMeaning,
    required this.auraColor,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Details'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Aura Image with Color Overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade700, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: RadialGradient(
                        colors: [auraColor.withOpacity(0.5), Colors.transparent],
                        radius: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Aura Meaning
              Text(
                'Aura Meaning: $auraMeaning',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: auraColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Timestamp
              Text(
                'Saved on: $timestamp',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Additional Insights
              Text(
                'Your aura suggests calmness and balance. Focus on mindfulness today!',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
