import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuraAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final Color auraColor;
  final String auraMeaning;

  const AuraAnalysisScreen({
    Key? key,
    required this.imagePath,
    required this.auraColor,
    required this.auraMeaning,
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
              // Aura Image with Particle Effects
              Stack(
                alignment: Alignment.center,
                children: [
                  // Particle Effects
                  CircularParticle(
                    awayRadius: 80,
                    numberOfParticles: 100,
                    speedOfParticles: 2,
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: MediaQuery.of(context).size.width * 0.8,
                    onTapAnimation: true,
                    particleColor: widget.auraColor.withOpacity(0.7),
                    awayAnimationDuration: const Duration(milliseconds: 600),
                    maxParticleSize: 5,
                    isRandSize: true,
                    isRandColor: true,
                    connectDots: false,
                  ),

                  // Aura Image with Color Overlay
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

              // Aura Meaning
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

              // Aura Energy Level Section
              _buildEnergyLevelIndicator(widget.auraColor),

              const SizedBox(height: 20),

              // Chakra Analysis Section
              _buildChakraAnalysis(),

              const SizedBox(height: 20),

              // Spiritual Recommendations Section
              _buildSpiritualRecommendations(),

              const SizedBox(height: 20),

              // Daily Affirmations Section
              _buildDailyAffirmations(),

              const SizedBox(height: 20),

              // Save to Gallery Button
              ElevatedButton(
                onPressed: () async {
                  await _saveImageToGallery(context);
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
                onPressed: () {
                  _shareAuraDetails();
                },
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

  // Method to Build Chakra Analysis Section with Animated Emojis
  Widget _buildChakraAnalysis() {
    final chakraInsights = _getChakraAnalysis(widget.auraColor);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chakra Analysis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              chakraInsights,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            // Animated Emojis Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedEmoji('❤️'), // Root Chakra
                _buildAnimatedEmoji('💚'), // Heart Chakra
                _buildAnimatedEmoji('💙'), // Throat Chakra
                _buildAnimatedEmoji('💜'), // Crown Chakra
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Method to Create Animated Emojis
  Widget _buildAnimatedEmoji(String emoji) {
    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [
        ScaleEffect(
          duration: const Duration(milliseconds: 800),
          begin: Offset(1.0, 1.0),
          end: Offset(1.2, 1.2),
        ),
      ],
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 30),
      ),
    );
  }

  // Method to Get Chakra Insights Based on Aura Color
  String _getChakraAnalysis(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return "Root Chakra (Muladhara) is dominant. Focus on grounding and stability. Practice meditation and connect with nature.";
    } else if (color.green > color.red && color.green > color.blue) {
      return "Heart Chakra (Anahata) is dominant. Focus on love, compassion, and balance. Practice heart-opening yoga poses.";
    } else if (color.blue > color.red && color.blue > color.green) {
      return "Throat Chakra (Vishuddha) is dominant. Focus on communication and self-expression. Chant affirmations or sing.";
    }
    return "Crown Chakra (Sahasrara) is dominant. Focus on spiritual connection and enlightenment. Engage in deep meditation.";
  }

  // Method to Build Energy Level Indicator
  Widget _buildEnergyLevelIndicator(Color color) {
    final energyLevel = _calculateEnergyLevel(color);

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

  // Method to Calculate Energy Level Based on Aura Color
  double _calculateEnergyLevel(Color color) {
    final totalColorValue = color.red + color.green + color.blue;
    return (totalColorValue / (255 * 3)) * 100;
  }

  // Spiritual Recommendations
  Widget _buildSpiritualRecommendations() {
    final recommendations = _getSpiritualRecommendations(widget.auraColor);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spiritual Practices for Your Aura",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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

  // Daily Affirmations Section
  Widget _buildDailyAffirmations() {
    final affirmations = _getDailyAffirmations(widget.auraColor);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Spiritual Affirmations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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

  // Save Image to Gallery
  Future<void> _saveImageToGallery(BuildContext context) async {
    try {
      final result = await GallerySaver.saveImage(widget.imagePath, albumName: 'AuraAnalysis');
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image.')),
        );
      }
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while saving the image.')),
      );
    }
  }

  // Share Aura Details
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

  // Spiritual Recommendations Based on Aura Color
  List<String> _getSpiritualRecommendations(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return [
        "Practice mindfulness to channel your energy.",
        "Engage in a creative activity like painting or writing.",
        "Focus on grounding exercises to balance your passions.",
      ];
    } else if (color.green > color.red && color.green > color.blue) {
      return [
        "Spend time in nature to recharge.",
        "Practice yoga or tai chi to maintain balance.",
        "Engage in a gratitude journaling exercise.",
      ];
    } else if (color.blue > color.red && color.blue > color.green) {
      return [
        "Meditate to connect with your inner self.",
        "Listen to calming music or nature sounds.",
        "Explore introspective journaling prompts.",
      ];
    }
    return [
      "Embrace your unique aura with daily affirmations.",
      "Explore spiritual books or resources to deepen your journey.",
      "Engage in creative visualization exercises.",
    ];
  }

  // Daily Affirmations Based on Aura Color
  List<String> _getDailyAffirmations(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return [
        "I am full of energy and capable of achieving greatness.",
        "My passion fuels my success and happiness.",
        "I am grounded and balanced in my pursuits.",
      ];
    } else if (color.green > color.red && color.green > color.blue) {
      return [
        "I am at peace with myself and the world around me.",
        "I am in harmony with nature and its rhythms.",
        "I cultivate balance in all aspects of my life.",
      ];
    } else if (color.blue > color.red && color.blue > color.green) {
      return [
        "I trust my intuition and embrace my inner wisdom.",
        "I am calm, serene, and centered in all that I do.",
        "I am open to the universe's guidance and support.",
      ];
    }
    return [
      "I am unique and my energy is a gift to the world.",
      "I embrace my individuality and celebrate my journey.",
      "I radiate positivity and attract beautiful opportunities.",
    ];
  }
}