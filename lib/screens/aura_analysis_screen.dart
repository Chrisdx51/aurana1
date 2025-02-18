import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuraAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final Color auraColor;
  final String auraMeaning;
  final List<String> affirmations;

  const AuraAnalysisScreen({
    Key? key,
    required this.imagePath,
    required this.auraColor,
    required this.auraMeaning,
    required this.affirmations,
  }) : super(key: key);

  @override
  _AuraAnalysisScreenState createState() => _AuraAnalysisScreenState();
}

class _AuraAnalysisScreenState extends State<AuraAnalysisScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Analysis'),
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
                        File(widget.imagePath),
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
                        colors: [widget.auraColor.withOpacity(0.5), Colors.transparent],
                        radius: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Aura Meaning: ${widget.auraMeaning}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.auraColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              _buildEnergyLevelIndicator(),
              const SizedBox(height: 20),
              _buildSpiritualRecommendations(),
              const SizedBox(height: 20),
              _buildDailyAffirmations(),
              const SizedBox(height: 20),

              // Save to Gallery Button (Currently Disabled)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Save to Gallery feature is currently disabled.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                child: const Text(
                  'Save to Gallery',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),

              // Share Aura Button
              ElevatedButton(
                onPressed: _shareAuraDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                child: const Text(
                  'Share Aura',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareAuraDetails() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.imagePath)],
        text: 'Check out my aura! It\'s ${widget.auraMeaning}. What does your aura look like?',
      );
    } catch (e) {
      print("Error sharing aura details: $e");
    }
  }

  Widget _buildEnergyLevelIndicator() {
    final energyLevel = _calculateEnergyLevel(widget.auraColor);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Aura Energy Level",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Energy: ${energyLevel.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: energyLevel / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: widget.auraColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateEnergyLevel(Color color) {
    final totalColorValue = color.red + color.green + color.blue;
    return (totalColorValue / (255 * 3)) * 100;
  }

  Widget _buildSpiritualRecommendations() {
    final recommendations = _getSpiritualRecommendations(widget.auraColor);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spiritual Recommendations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            ...recommendations.map((rec) => ListTile(
              leading: const Icon(Icons.self_improvement, color: Colors.blue),
              title: Text(rec),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAffirmations() {
    final affirmations = widget.affirmations;
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Affirmations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            ...affirmations.map((aff) => ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.orange),
              title: Text(aff),
            )),
          ],
        ),
      ),
    );
  }

  List<String> _getSpiritualRecommendations(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return ["Practice mindfulness.", "Engage in creative activities.", "Focus on grounding exercises."];
    } else if (color.green > color.red && color.green > color.blue) {
      return ["Spend time in nature.", "Practice yoga or tai chi.", "Start a gratitude journal."];
    }
    return ["Meditate daily.", "Listen to calming music.", "Explore spiritual books."];
  }
}
