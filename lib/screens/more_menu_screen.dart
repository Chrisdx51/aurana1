import 'package:flutter/material.dart';
import 'spiritual_tools_screen.dart';
import 'challenges_screen.dart';
import 'sessions_screen.dart';
import 'spiritual_guidance_screen.dart';
import 'aura_catcher.dart';
import 'moon_cycle_screen.dart';
import 'horoscope_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("More Options")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.star),
            title: Text("Spiritual Tools"),
            onTap: () => _navigate(context, SpiritualToolsScreen()),
          ),
          ListTile(
            leading: Icon(Icons.directions_run),
            title: Text("Challenges"),
            onTap: () => _navigate(context, ChallengesScreen()),
          ),
          ListTile(
            leading: Icon(Icons.live_tv),
            title: Text("Sessions"),
            onTap: () => _navigate(context, SessionsScreen()),
          ),
          ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text("Guidance"),
            onTap: () => _navigate(context, SpiritualGuidanceScreen()),
          ),
          ListTile(
            leading: Icon(Icons.camera),
            title: Text("Aura Capture"),
            onTap: () => _navigate(context, AuraCatcherScreen()),
          ),
          ListTile(
            leading: Icon(Icons.nightlight_round),
            title: Text("Moon Cycle"),
            onTap: () => _navigate(context, MoonCycleScreen()),
          ),
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text("Horoscope"),
            onTap: () => _navigate(context, HoroscopeScreen(zodiacSign: "Aries")), // ✅ Pass a default zodiac sign
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
