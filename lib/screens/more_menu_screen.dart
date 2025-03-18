import 'package:flutter/material.dart';
import 'aura_catcher.dart';
import 'spiritual_guidance_screen.dart';
import 'tarot_reading_screen.dart';
import 'horoscope_screen.dart';
import 'moon_cycle_screen.dart';
import 'journal_screen.dart';
import 'all_ads_page.dart';

class MoreMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Sacred Tools ✨",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🌌 Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/guide.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌟 Content Area
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 120, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _introText(),
                SizedBox(height: 30),

                _glowingCard(context, "Aura Catcher", Icons.light_mode, Colors.deepPurpleAccent, AuraCatcherScreen()),
                _glowingCard(context, "Spiritual Guidance", Icons.self_improvement, Colors.indigoAccent, SpiritualGuidanceScreen()),
                _glowingCard(context, "Tarot Reading", Icons.style, Colors.pinkAccent, TarotReadingScreen()),
                _glowingCard(context, "Horoscope", Icons.auto_awesome, Colors.tealAccent, HoroscopeScreen()),
                _glowingCard(context, "Moon Cycle", Icons.wb_sunny, Colors.amberAccent, MoonCycleScreen()),
                _glowingCard(context, "Sacred Journal", Icons.book, Colors.greenAccent, JournalScreen()),
                _glowingCard(context, "Sacred Services (Ads)", Icons.campaign, Colors.redAccent, AllAdsPage()),

                SizedBox(height: 40),
                _closingMessage(),
                SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _introText() {
    return Column(
      children: [
        Text(
          "Welcome to your Sacred Space 🌌",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Explore tools crafted for your spiritual journey. Let them guide you toward clarity, healing, and inner peace. ✨",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _closingMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "This isn't just a menu. It's your gateway to the divine tools that illuminate your soul's journey. 🌿",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Use these sacred tools with love and intention. Your path unfolds with each step you take here. ✨",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowingCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.4),
            ],
            radius: 0.85,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 34, color: Colors.white),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
