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
