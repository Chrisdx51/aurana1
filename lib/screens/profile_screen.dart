import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  List<String> selectedPaths = [];
  int completedChallenges = 0; // ✅ Track completed challenges
  List<String> earnedMedals = []; // ✅ Store earned medals (Emoji-Based)

  final List<String> interests = [
    'Meditation',
    'Tarot',
    'Astrology',
    'Energy Healing',
    'Mindfulness',
    'Law of Attraction',
    'Reading',
    'Music',
    'Fitness',
    'Cooking',
    'Traveling',
    'Technology',
    'Gaming',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMedals();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _bioController.text = prefs.getString('bio') ?? '';
      selectedPaths = prefs.getStringList('interests') ?? [];
      completedChallenges = prefs.getInt('completedChallenges') ?? 0;
    });
  }

  Future<void> _loadMedals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      earnedMedals = prefs.getStringList('medals') ?? [];
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('bio', _bioController.text);
    await prefs.setStringList('interests', selectedPaths);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Profile Saved!")));
  }

  // 📌 Ensure medals update when profile is loaded
  Future<void> _updateMedals() async {
    final prefs = await SharedPreferences.getInstance();
    int challengesCompleted = prefs.getInt('completedChallenges') ?? 0;

    // Define how medals are given
    List<String> medals = [];
    if (challengesCompleted >= 1) medals.add("🥉"); // Bronze Medal
    if (challengesCompleted >= 3) medals.add("🥈"); // Silver Medal
    if (challengesCompleted >= 5) medals.add("🥇"); // Gold Medal
    if (challengesCompleted >= 10) medals.add("🏆"); // Trophy for 10+ challenges

    await prefs.setStringList('medals', medals);

    setState(() {
      earnedMedals = medals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.blue.shade300),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📌 Profile Picture Placeholder
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 50, color: Colors.blue.shade700),
            ),
            SizedBox(height: 10),

            Text(
              'Your Medals 🏅',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // 📌 Medal Display (Emoji-Based)
            earnedMedals.isNotEmpty
                ? Wrap(
                    spacing: 10,
                    children: earnedMedals.map((medal) {
                      return Text(
                        medal,
                        style: TextStyle(fontSize: 30),
                      );
                    }).toList(),
                  )
                : Column(
                    children: [
                      Text("No Medals Earned Yet", style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("😔", style: TextStyle(fontSize: 24)),
                      SizedBox(height: 5),
                      Text("Start a challenge today and earn your first medal! 🚀", style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),

            SizedBox(height: 20),

            Text(
              "Completed Challenges: $completedChallenges",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: 'Bio'),
            ),
            SizedBox(height: 20),

            Text(
              'Select Your Interests:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Wrap(
              spacing: 8.0,
              children: interests.map((interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: selectedPaths.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedPaths.add(interest);
                      } else {
                        selectedPaths.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
