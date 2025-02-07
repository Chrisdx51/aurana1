import 'package:flutter/material.dart';
import 'challenge_details_screen.dart';

class ChallengesScreen extends StatefulWidget {
  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
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
        "Day 6: Meditate before sleep",
        "Day 7: Reflect on your progress"
      ]
    },
    {
      "title": "Gratitude Challenge",
      "description": "Write three things you're grateful for every day.",
      "tasks": [
        "Day 1: Write 3 things you’re grateful for",
        "Day 2: Express gratitude to someone",
        "Day 3: Reflect on a past challenge with gratitude",
        "Day 4: Find gratitude in small things",
        "Day 5: Write a gratitude letter",
        "Day 6: Spend time appreciating nature",
        "Day 7: Meditate on gratitude"
      ]
    },
    {
      "title": "Manifestation Journey",
      "description": "Learn how to manifest positive energy.",
      "tasks": [
        "Day 1: Visualize your ideal life",
        "Day 2: Write affirmations",
        "Day 3: Meditate on your goals",
        "Day 4: Focus on positive thoughts",
        "Day 5: Create a vision board",
        "Day 6: Practice gratitude for your desires",
        "Day 7: Reflect on your progress"
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Guided Spiritual Challenges"), backgroundColor: Colors.blue.shade300),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(challenges[index]["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(challenges[index]["description"]),
                trailing: ElevatedButton(
                  onPressed: () {
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
                  child: Text("Start"),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
