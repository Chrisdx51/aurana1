import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'horoscope_screen.dart';

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
  String? _zodiacSign; // Variable to store zodiac sign
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
      _zodiacSign = prefs.getString('zodiacSign'); // Load zodiac sign
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

    // Save Zodiac Sign if DOB is provided
    if (_dobController.text.isNotEmpty) {
      DateTime dob = DateTime.parse(_dobController.text);
      String zodiacSign = _calculateZodiacSign(dob);
      await prefs.setString('zodiacSign', zodiacSign);
      setState(() {
        _zodiacSign = zodiacSign; // Update UI with zodiac sign
      });
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
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  String _calculateZodiacSign(DateTime dob) {
    int day = dob.day;
    int month = dob.month;

    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Pisces";
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";

    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soul Essence'), // Spiritual name
        backgroundColor: Colors.blue.shade300,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade200,
              Colors.purple.shade100,
              Colors.pink.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Sidebar for Medals
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _isSidebarCollapsed ? 50 : 120,
                    color: Colors.blue.shade100.withOpacity(0.6),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          ...earnedMedals.map((medal) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(medal,
                                  style: TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  // Profile Content
                  Expanded(
                    child: Column(
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
                                ? Icon(Icons.person,
                                size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        TextField(
                          controller: _realNameController,
                          decoration: InputDecoration(labelText: 'Real Name'),
                          style: TextStyle(fontSize: 14),
                        ),
                        TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(labelText: 'Nickname'),
                          style: TextStyle(fontSize: 14),
                        ),
                        TextField(
                          controller: _bioController,
                          decoration: InputDecoration(labelText: 'Bio'),
                          style: TextStyle(fontSize: 14),
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
                          style: TextStyle(fontSize: 14),
                        ),
                        if (_zodiacSign != null)
                          Text(
                            "Your Zodiac Sign: $_zodiacSign",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(height: 10),
                        Text(
                          'Completed Challenges: $completedChallenges',
                          style: TextStyle(fontSize: 14),
                        ),
                        // Friends Buttons
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
                        SizedBox(height: 10),
                        // View Daily Horoscope Button
                        ElevatedButton(
                          onPressed: () {
                            if (_zodiacSign != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HoroscopeScreen(zodiacSign: _zodiacSign!),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Please provide your Date of Birth.")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text('View Daily Horoscope'),
                        ),
                        SizedBox(height: 10),
                        // Interests at the Bottom
                        Text(
                          'Select Interests',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: interests.map((interest) {
                            return FilterChip(
                              label: Text(interest,
                                  style: TextStyle(fontSize: 12)),
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
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}