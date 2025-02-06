import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  List<String> selectedPaths = [];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: () {
                  String name = _nameController.text;
                  String bio = _bioController.text;
                  print(
                      'Saved: Name - $name, Bio - $bio, Interests - $selectedPaths');
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Profile Saved!")));
                },
                child: Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
