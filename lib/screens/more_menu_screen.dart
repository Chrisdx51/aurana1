import 'package:flutter/material.dart';
import 'aura_catcher.dart';
import 'spiritual_guidance_screen.dart';
import 'tarot_reading_screen.dart';
import 'horoscope_screen.dart';
import 'moon_cycle_screen.dart';
import 'journal_screen.dart';
import 'profile_screen.dart'; // You might need this!
import 'all_ads_page.dart';       // Add your Ads page import here!

class MoreMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("More Features"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("Aura Catcher"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AuraCatcherScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.self_improvement),
            title: Text("Spiritual Guidance"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SpiritualGuidanceScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.style),
            title: Text("Tarot Reading"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TarotReadingScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text("Horoscope"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HoroscopeScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.wb_sunny),
            title: Text("Moon Cycle"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MoonCycleScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text("Journal"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JournalScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.campaign),
            title: Text("All Ads"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllAdsPage()), // Replace with your actual ads screen
            ),
          ),
        ],
      ),
    );
  }
}
