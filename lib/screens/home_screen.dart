import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'social_feed_screen.dart'; // Update the paths based on actual locations
import 'profile_screen.dart'; // Update the paths based on actual locations
import 'spiritual_tools_screen.dart'; // Assuming a valid existing screen

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(
            fontFamily: 'fo18',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg2.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('assets/images/profile.png'),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'John Doe',
                              style: TextStyle(
                                fontFamily: 'fo18',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Empower Your Journey',
                              style: TextStyle(
                                fontFamily: 'fo18',
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.8),
                                backgroundColor: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Welcome Text
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Welcome to Aurana!',
                        style: TextStyle(
                          fontFamily: 'fo18',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Quick Access Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _quickAccessButton(
                          'Feed',
                          Icons.public,
                          screenWidth,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SocialFeedScreen(),
                              ),
                            );
                          },
                        ),
                        _quickAccessButton(
                          'Profile',
                          Icons.person,
                          screenWidth,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _quickAccessButton(
                          'Tools',
                          Icons.star,
                          screenWidth,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpiritualToolsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Featured Content Slider
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: screenHeight * 0.25,
                      child: PageView(
                        children: [
                          _featuredContent(
                              'Explore Features', 'assets/images/feature1.png'),
                          _featuredContent(
                              'Your Daily Insight', 'assets/images/feature2.png'),
                          _featuredContent(
                              'Guided Meditations', 'assets/images/feature3.png'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Motivational Quote
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _cardWithText(
                      '“The journey of a thousand miles begins with one step.” - Lao Tzu',
                    ),
                  ),
                  SizedBox(height: 20),
                  // Aura Snapshot
                  AuraSnapshot(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessButton(
      String text, IconData icon, double screenWidth, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.purple),
      label: Text(
        text,
        style: TextStyle(
          fontFamily: 'fo18',
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(80, 40),
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _featuredContent(String title, String assetPath) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'fo18',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardWithText(String text) {
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'fo18',
            fontSize: 16,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AuraSnapshot extends StatefulWidget {
  @override
  _AuraSnapshotState createState() => _AuraSnapshotState();
}

class _AuraSnapshotState extends State<AuraSnapshot> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String auraColor = ""; // Holds the aura color name.
  String auraMessage = ""; // Holds the spiritual guidance message.

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);

    await _cameraController!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _scanAura() {
    // Randomly generate an aura color (you can add logic for actual detection later).
    final List<String> auraColors = ["Blue", "Green", "Red", "Purple", "Yellow"];
    final Map<String, String> auraMessages = {
      "Blue": "You are calm and peaceful today. Focus on mindfulness.",
      "Green": "Growth and healing are in your energy field.",
      "Red": "Passion and strength are driving your day.",
      "Purple": "Your intuition is heightened—trust your instincts.",
      "Yellow": "Joy and positivity radiate around you."
    };

    final selectedColor = (auraColors..shuffle()).first;

    setState(() {
      auraColor = selectedColor;
      auraMessage = auraMessages[selectedColor]!;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isCameraInitialized)
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          )
        else
          CircularProgressIndicator(),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _scanAura,
          child: Text("Scan Aura"),
        ),
        if (auraColor.isNotEmpty)
          Column(
            children: [
              Text(
                "Aura Color: $auraColor",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                auraMessage,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
      ],
    );
  }
}