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
                          backgroundImage:
                          AssetImage('assets/images/profile.png'),
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
