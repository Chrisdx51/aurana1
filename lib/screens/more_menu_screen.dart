import 'package:flutter/material.dart';
import 'aura_catcher.dart';
import 'spiritual_guidance_screen.dart';
import 'tarot_reading_screen.dart';
import 'horoscope_screen.dart';
import 'moon_cycle_screen.dart';
import 'journal_screen.dart';
import 'all_ads_page.dart';

class MoreMenuScreen extends StatelessWidget {
  final List<_ToolItem> tools = [
    _ToolItem(
      title: "Aura Catcher",
      description: "Discover the energy fields around you.",
      icon: Icons.light_mode,
      color: Colors.deepPurpleAccent,
      destination: AuraCatcherScreen(),
    ),
    _ToolItem(
      title: "Spiritual Guidance",
      description: "Receive messages from your higher self.",
      icon: Icons.self_improvement,
      color: Colors.indigoAccent,
      destination: SpiritualGuidanceScreen(),
    ),
    _ToolItem(
      title: "Tarot Reading",
      description: "Unveil the wisdom of the tarot cards.",
      icon: Icons.style,
      color: Colors.pinkAccent,
      destination: TarotReadingScreen(),
    ),
    _ToolItem(
      title: "Horoscope",
      description: "Explore your cosmic insights today.",
      icon: Icons.auto_awesome,
      color: Colors.tealAccent,
      destination: HoroscopeScreen(),
    ),
    _ToolItem(
      title: "Moon Cycle",
      description: "Track the moon phases and energy shifts.",
      icon: Icons.wb_sunny,
      color: Colors.amberAccent,
      destination: MoonCycleScreen(),
    ),
    _ToolItem(
      title: "Sacred Journal",
      description: "Reflect and write your soul’s journey.",
      icon: Icons.book,
      color: Colors.greenAccent,
      destination: JournalScreen(),
    ),
    _ToolItem(
      title: "Sacred Services (Ads)",
      description: "Explore offerings to support your path.",
      icon: Icons.campaign,
      color: Colors.redAccent,
      destination: AllAdsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Sacred Tools ✨",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/guide.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _introText(),
                  SizedBox(height: 20),
                  ...tools.map((tool) => _buildFeatureCard(context, tool)).toList(),
                  SizedBox(height: 40),
                  _closingMessage(),
                ],
              ),
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
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Explore tools crafted for your spiritual journey. Let them guide you toward clarity, healing, and inner peace. ✨",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, _ToolItem tool) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => tool.destination));
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tool.color.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: tool.color.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: tool.color.withOpacity(0.8),
              radius: 28,
              child: Icon(tool.icon, size: 30, color: Colors.white),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    tool.description,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
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
}

class _ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget destination;

  _ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.destination,
  });
}
