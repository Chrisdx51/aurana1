import 'package:flutter/material.dart';
import 'challenge_details_screen.dart';

class ChallengesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> challenges = [
    {
      "title": "7-Day Meditation Challenge",
      "description": "Build a habit of daily meditation.",
      "tasks": [
        "Day 1: Meditate for 5 minutes",
        "Day 2: Meditate for 10 minutes",
        "Day 3: Meditate for 15 minutes",
        "Day 4: Focus on deep breathing",
        "Day 5: Try guided meditation",
        "Day 6: Meditate in nature",
        "Day 7: Reflect on your progress"
      ]
    },
    {
      "title": "7-Day Gratitude Challenge",
      "description": "Practice gratitude every day to improve mindset.",
      "tasks": [
        "Day 1: Write down 3 things you're grateful for",
        "Day 2: Express gratitude to someone",
        "Day 3: Think about past blessings",
        "Day 4: Keep a gratitude journal",
        "Day 5: Find gratitude in challenges",
        "Day 6: Practice mindful appreciation",
        "Day 7: Reflect on how gratitude changed you"
      ]
    },
    {
      "title": "7-Day Self-Care Challenge",
      "description": "Take time for self-care and relaxation.",
      "tasks": [
        "Day 1: Drink more water today",
        "Day 2: Do a 10-minute stretching session",
        "Day 3: Get enough sleep tonight",
        "Day 4: Take a relaxing bath",
        "Day 5: Practice deep breathing",
        "Day 6: Listen to calming music",
        "Day 7: Do something that makes you happy"
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Guided Challenges"), backgroundColor: Colors.blue.shade300),
      body: ListView.builder(
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(challenges[index]["title"], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(challenges[index]["description"]),
              trailing: Icon(Icons.arrow_forward, color: Colors.blue),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChallengeDetailsScreen(
                      title: challenges[index]["title"],
                      description: challenges[index]["description"],
                      tasks: List<String>.from(challenges[index]["tasks"]),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
