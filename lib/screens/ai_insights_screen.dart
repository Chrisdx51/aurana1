import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SpiritualGuidanceScreen extends StatefulWidget {
  @override
  _SpiritualGuidanceScreenState createState() => _SpiritualGuidanceScreenState();
}

class _SpiritualGuidanceScreenState extends State<SpiritualGuidanceScreen> {
  String dailyMessage = "";

  final List<String> spiritualMessages = [
    "✨ Trust the journey. Everything is unfolding as it should.",
    "🌿 Breathe deeply. The universe is guiding you.",
    "💫 Your energy attracts your reality—choose your thoughts wisely.",
    "🕊 Peace comes when we embrace the present moment fully.",
    "🔮 Intuition is your soul speaking—listen closely.",
    "🌙 The moon reminds us that even in darkness, we can shine.",
    "🔥 Transformation begins when you step outside your comfort zone.",
    "🌿 Nature heals—take a moment to feel its presence.",
    "💖 Love is the highest vibration. Share it freely.",
    "🌞 Today is a new day. Align your energy and step forward with purpose."
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyMessage();
  }

  // 📌 Load a saved message or generate a new one
  Future<void> _loadDailyMessage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedMessage = prefs.getString('dailyMessage');
    if (savedMessage != null) {
      setState(() {
        dailyMessage = savedMessage;
      });
    } else {
      _generateNewMessage();
    }
  }

  // 📌 Generate a new daily message
  void _generateNewMessage() async {
    final prefs = await SharedPreferences.getInstance();
    String newMessage = spiritualMessages[Random().nextInt(spiritualMessages.length)];
    
    setState(() {
      dailyMessage = newMessage;
    });

    await prefs.setString('dailyMessage', newMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Divine Guidance"),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Message for Today",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dailyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateNewMessage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: Text("Receive New Wisdom ✨"),
            ),
          ],
        ),
      ),
    );
  }
}
