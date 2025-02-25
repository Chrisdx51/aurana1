import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart'; // Make sure to import this if it's not already imported

class HomeScreen extends StatefulWidget {
  final String userName;

  HomeScreen({required this.userName}); // Accept userName dynamically

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService supabaseService = SupabaseService();
  UserModel? user;
  bool _isLoading = true;
  bool _hasError = false;

  final List<String> backgroundImages = [
    'assets/images/bg1.png',
    'assets/images/bg2.png',
    'assets/images/bg3.png',
  ];

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
    _loadUserProfile();
  }

  Future<void> _checkProfileCompletion() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    bool isComplete = await SupabaseService().isProfileComplete(userId);

    if (!isComplete) {
      // 🚫 Redirect to ProfileScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
        );
      });
    }
  }

  // 🔥 Fetch User Profile from Supabase
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final profile = await supabaseService.getUserProfile(userId);
      if (profile != null) {
        setState(() {
          user = profile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // 🔄 Get background image based on the date
  String getRotatingBackground() {
    int day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    return backgroundImages[(day ~/ 3) % backgroundImages.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Celestial Path',
          style: TextStyle(
            fontFamily: 'fo18',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🔄 Rotating background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(getRotatingBackground()),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.purple))
                      : _hasError
                      ? _buildErrorMessage()
                      : _buildGreetingSection(),
                  SizedBox(height: 10),
                  _buildCardSection(
                    title: "Today's Affirmation",
                    content: '“I am in alignment with my higher purpose.”',
                    icon: Icons.lightbulb_outline,
                  ),
                  SizedBox(height: 10),
                  _buildCardSection(
                    title: "Today's Challenge",
                    content: "Take 5 minutes to meditate and breathe deeply.",
                    icon: Icons.check_circle_outline,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Challenge marked as complete!'),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  _buildCardSection(
                    title: "Today's Insight",
                    content:
                    "The energy of the universe flows within you. Take a moment to connect with your inner light.",
                    icon: Icons.self_improvement,
                  ),
                  SizedBox(height: 10),
                  _buildTrendingTopicsSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 Greeting Section with Dynamic Data
  Widget _buildGreetingSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage('assets/images/default_avatar.png'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${user?.name ?? "Guest"}!',
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Illuminate Your Path',
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 Card Section for Daily Messages
  Widget _buildCardSection({
    required String title,
    required String content,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 28, color: Colors.blueAccent),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'fo18',
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: Icon(Icons.done, color: Colors.blue),
              onPressed: onTap,
            ),
        ],
      ),
    );
  }

  // 🟢 Trending Topics Section
  Widget _buildTrendingTopicsSection() {
    final List<Map<String, String>> trendingTopics = [
      {"topic": "#Mindfulness", "posts": "324 posts"},
      {"topic": "#Gratitude", "posts": "289 posts"},
      {"topic": "#SpiritualGrowth", "posts": "415 posts"},
      {"topic": "#InnerPeace", "posts": "198 posts"},
      {"topic": "#DailyAffirmations", "posts": "350 posts"},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: trendingTopics.map((topic) {
          return ListTile(
            title: Text(topic["topic"]!, style: TextStyle(fontSize: 12, color: Colors.black)),
            subtitle: Text(topic["posts"]!, style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }).toList(),
      ),
    );
  }

  // 🔥 Error Message UI
  Widget _buildErrorMessage() {
    return Center(child: Text("Error loading profile", style: TextStyle(color: Colors.red)));
  }
}