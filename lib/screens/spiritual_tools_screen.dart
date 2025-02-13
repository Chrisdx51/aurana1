import 'package:flutter/material.dart';
import 'tarot_reading_screen.dart'; // Import all the screens
import 'moon_cycle_screen.dart';
import 'guided_breathing_screen.dart';
import 'horoscope_screen.dart';

class SpiritualToolsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tools = [
    {
      'name': 'Tarot Reading',
      'icon': Icons.style,
      'route': '/tarot', // Specify the route for each tool
    },
    {
      'name': 'Moon Cycle Tracker',
      'icon': Icons.nightlight_round,
      'route': '/moon',
    },
    {
      'name': 'Guided Breathing',
      'icon': Icons.self_improvement,
      'route': '/breathing',
    },
    {
      'name': 'Astrology Updates',
      'icon': Icons.star,
      'route': '/astrology',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spiritual Tools'),
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(tool['icon'], color: Colors.teal),
              title: Text(
                tool['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pushNamed(context, tool['route']);
              },
            ),
          );
        },
      ),
    );
  }
}
