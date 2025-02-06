import 'package:flutter/material.dart';

class ChallengesScreen extends StatelessWidget {
  final List<Map<String, String>> challenges = [
    {'title': '7-Day Meditation Challenge', 'description': 'Commit to 7 days of daily meditation.'},
    {'title': 'Gratitude Challenge', 'description': 'Write down 3 things you’re grateful for each day.'},
    {'title': 'Manifestation Exercise', 'description': 'Practice positive affirmations and visualization.'},
    {'title': 'Breathwork Practice', 'description': 'Follow a structured breathing routine for mindfulness.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guided Spiritual Challenges')),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.star, color: Colors.purple),
              title: Text(challenge['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(challenge['description']!),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${challenge['title']} - Coming Soon!')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
