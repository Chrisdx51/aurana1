import 'package:flutter/material.dart';
import 'social_feed_screen.dart';
import 'profile_screen.dart';
import 'spiritual_tools_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;

  HomeScreen({required this.userName}); // Accept userName dynamically

  // List of rotating backgrounds
  final List<String> backgroundImages = [
    'assets/images/bg1.png',
    'assets/images/bg2.png',
    'assets/images/bg3.png',
  ];

  // Function to calculate the current background index based on the date
  String getRotatingBackground() {
    int day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    return backgroundImages[(day ~/ 3) % backgroundImages.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Celestial Path',
          style: TextStyle(
            fontFamily: 'fo18',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Rotating background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(getRotatingBackground()),
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
                children: [
                  SizedBox(height: 10),
                  // Greeting Section
                  _buildGreetingSection(),
                  SizedBox(height: 10),
                  // Daily Affirmation Section
                  _buildCardSection(
                    title: "Today's Affirmation",
                    content: '“I am in alignment with my higher purpose.”',
                    icon: Icons.lightbulb_outline,
                  ),
                  SizedBox(height: 10),
                  // Daily Challenge Section
                  _buildCardSection(
                    title: "Today's Challenge",
                    content: "Take 5 minutes to meditate and breathe deeply.",
                    icon: Icons.check_circle_outline,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Challenge marked as complete!'),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  // Spiritual Insight Section
                  _buildCardSection(
                    title: "Today's Insight",
                    content:
                        "The energy of the universe flows within you. Take a moment to connect with your inner light.",
                    icon: Icons.self_improvement,
                  ),
                  SizedBox(height: 10),
                  // Trending Topics Section
                  _buildTrendingTopicsSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Illuminate Your Path',
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required String content,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 28, color: Colors.blueAccent),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: Icon(Icons.done, color: Colors.blue),
              onPressed: onTap,
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingTopicsSection() {
    final List<Map<String, String>> trendingTopics = [
      {"topic": "#Mindfulness", "posts": "324 posts"},
      {"topic": "#Gratitude", "posts": "289 posts"},
      {"topic": "#SpiritualGrowth", "posts": "415 posts"},
      {"topic": "#InnerPeace", "posts": "198 posts"},
      {"topic": "#DailyAffirmations", "posts": "350 posts"},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trending Topics",
            style: TextStyle(
              fontFamily: 'fo18',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Column(
            children: trendingTopics.map((topic) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        topic["topic"]!,
                        style: TextStyle(
                          fontFamily: 'fo18',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      topic["posts"]!,
                      style: TextStyle(
                        fontFamily: 'fo18',
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
