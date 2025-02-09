import 'package:flutter/material.dart';

class GuidedBreathingScreen extends StatefulWidget {
  @override
  _GuidedBreathingScreenState createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<Color> chakraColors = [
    Colors.red, // Root
    Colors.orange, // Sacral
    Colors.yellow, // Solar Plexus
    Colors.green, // Heart
    Colors.blue, // Throat
    Colors.indigo, // Third Eye
    Colors.purple, // Crown
  ];

  String breathingText = "Inhale...";
  int currentChakraIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 4), // 4 seconds for inhale and exhale
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          breathingText = "Exhale...";
          currentChakraIndex =
              (currentChakraIndex + 1) % chakraColors.length; // Update chakra
        });
        _controller.reverse(); // Reverse animation
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          breathingText = "Inhale...";
        });
        _controller.forward(); // Restart animation
      }
    });

    _controller.forward(); // Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guided Breathing"),
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/parchment_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chakra Color Breathing Animation
                ScaleTransition(
                  scale: _animation,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chakraColors[currentChakraIndex].withOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Breathing Text
                Text(
                  breathingText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Restart Button
                ElevatedButton(
                  onPressed: () {
                    _controller.forward(from: 0); // Restart the animation
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Restart Exercise"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
