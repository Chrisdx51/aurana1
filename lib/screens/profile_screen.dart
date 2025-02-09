import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _realNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  File? _profileImage;
  List<String> selectedInterests = [];
  int completedChallenges = 0;
  List<String> earnedMedals = [];
  bool _isSidebarCollapsed = false;
  String _selectedNameType = 'Real Name';
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
      _realNameController.text = prefs.getString('realName') ?? '';
      _nicknameController.text = prefs.getString('nickname') ?? '';
      _bioController.text = prefs.getString('bio') ?? '';
      _dobController.text = prefs.getString('dob') ?? '';
      selectedInterests = prefs.getStringList('interests') ?? [];
      completedChallenges = prefs.getInt('completedChallenges') ?? 0;
      final savedImagePath = prefs.getString('profileImage');
      if (savedImagePath != null) {
        _profileImage = File(savedImagePath);
      }
      _selectedNameType = prefs.getString('selectedNameType') ?? 'Real Name';
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
    await prefs.setString('realName', _realNameController.text);
    await prefs.setString('nickname', _nicknameController.text);
    await prefs.setString('bio', _bioController.text);
    await prefs.setString('dob', _dobController.text);
    await prefs.setStringList('interests', selectedInterests);
    await prefs.setString('selectedNameType', _selectedNameType);
    if (_profileImage != null) {
      await prefs.setString('profileImage', _profileImage!.path);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Profile Saved!")));
  }

  Future<void> _updateProfileImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue.shade300,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 50 : 100, // Sidebar size toggle
            color: Colors.blue.shade100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                IconButton(
                  icon: Icon(_isSidebarCollapsed
                      ? Icons.arrow_forward
                      : Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
                if (!_isSidebarCollapsed) ...[
                  Text(
                    'Medals',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ...earnedMedals.map((medal) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(medal, style: TextStyle(fontSize: 24)),
                    );
                  }).toList(),
                ],
                Spacer(),
              ],
            ),
          ),
          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _updateProfileImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      backgroundColor: Colors.grey.shade300,
                      child: _profileImage == null
                          ? Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _realNameController,
                    decoration: InputDecoration(labelText: 'Real Name'),
                  ),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(labelText: 'Nickname'),
                  ),
                  TextField(
                    controller: _bioController,
                    decoration: InputDecoration(labelText: 'Bio'),
                  ),
                  TextField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () {
                          _selectDate(context);
                        },
                      ),
                    ),
                    readOnly: true,
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 8.0,
                    children: interests.map((interest) {
                      return FilterChip(
                        label: Text(interest),
                        selected: selectedInterests.contains(interest),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedInterests.add(interest);
                            } else {
                              selectedInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text('Completed Challenges: $completedChallenges'),
                  SizedBox(height: 20),
                  // Name Type Selection
                  Text(
                    'Display Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('Real Name'),
                    leading: Radio<String>(
                      value: 'Real Name',
                      groupValue: _selectedNameType,
                      onChanged: (value) {
                        setState(() {
                          _selectedNameType = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Nickname'),
                    leading: Radio<String>(
                      value: 'Nickname',
                      groupValue: _selectedNameType,
                      onChanged: (value) {
                        setState(() {
                          _selectedNameType = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Statistics Section
                  Text(
                    'Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Total Posts: 50'),
                  Text('Likes Received: 120'),
                  Text('Comments Written: 30'),
                  Text('Challenges Completed: $completedChallenges'),
                  SizedBox(height: 20),
                  // Progress Tracker
                  Text(
                    'Spiritual Growth',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(value: 0.7),
                  SizedBox(height: 20),
                  // Profile Highlights
                  Text(
                    'Profile Highlights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Top Post: "Achieved Inner Peace"'),
                  Text('Meaningful Quote: "Be the change you wish to see."'),
                  SizedBox(height: 20),
                  // Recent Activity Feed
                  Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Liked a post: "Meditation Tips"'),
                  Text('Commented on: "Astrology Insights"'),
                  Text('Posted: "My Journey with Mindfulness"'),
                  Text('Completed Challenge: "30 Days of Yoga"'),
                  Text('Received Medal: "Mindfulness Master"'),
                  SizedBox(height: 20),
                  // Friends System
                  Text(
                    'Friends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Add friend functionality
                    },
                    child: Text('Add Friend'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Manage friends functionality
                    },
                    child: Text('Manage Friends'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
