import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'tarot_reading_screen.dart';
import 'aura_catcher.dart';
import 'moon_cycle_screen.dart';
import 'soul_journey_screen.dart';
import 'user_discovery_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  HomeScreen({required this.userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final SupabaseService supabaseService = SupabaseService();
  UserModel? user;
  bool _isLoading = true;
  bool _hasError = false;
  int _spiritualXP = 0;
  int _spiritualLevel = 1;
  bool _challengeCompleted = false;
  bool _profileChecked = false;
  late TabController _tabController;

  final List<String> backgroundImages = [
    'assets/images/bg1.png',
    'assets/images/bg2.png',
    'assets/images/bg3.png',
  ];

  final List<String> _challengeList = [
    "Take 5 minutes to meditate and breathe deeply.",
    "Write down 3 things you're grateful for.",
    "Spend 10 minutes in silence, listening to your breath.",
    "Do one act of kindness today.",
    "Step outside and connect with nature.",
    "Visualize yourself achieving your goals for 5 minutes.",
    "Stretch your body and release tension for 5 minutes.",
  ];

  String _todaysChallenge = "Take 5 minutes to meditate and breathe deeply.";
  DateTime? _lastCompletedTime;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChallengeStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_profileChecked) return;
    _profileChecked = true;

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
          _spiritualXP = profile.spiritualXP ?? 0;
          _spiritualLevel = profile.spiritualLevel ?? 1;
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

  Future<void> _loadChallengeStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('challenge_status')
          .select('last_completed')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['last_completed'] != null) {
        _lastCompletedTime = DateTime.parse(response['last_completed']);
        if (DateTime.now().difference(_lastCompletedTime!).inHours < 24) {
          setState(() {
            _challengeCompleted = true;
          });
        }
      }
    } catch (error) {
      print("Error loading challenge status: $error");
    }

    _generateDailyChallenge();
  }

  void _generateDailyChallenge() {
    int today = DateTime.now().day;
    int challengeIndex = today % _challengeList.length;
    setState(() {
      _todaysChallenge = _challengeList[challengeIndex];
    });
  }

  void _completeChallenge() async {
    if (_challengeCompleted) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('challenge_status')
          .upsert({'user_id': userId, 'last_completed': DateTime.now().toIso8601String()});

      setState(() {
        _challengeCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Challenge completed! +10 XP')),
      );

      setState(() {
        _spiritualXP += 10;
      });
    } catch (error) {
      print("Error updating challenge status: $error");
    }
  }

  String getRotatingBackground() {
    int day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    return backgroundImages[(day ~/ 3) % backgroundImages.length];
  }

  void _navigateToPage(Widget page) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: User not logged in")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Celestial Path',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(getRotatingBackground()), // ✅ Dynamic Background
            fit: BoxFit.cover, // ✅ Ensures full coverage
            alignment: Alignment.topCenter, // ✅ Aligns correctly
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.purple))
                        : _hasError
                        ? _buildErrorMessage()
                        : _buildGreetingSection(),
                    SizedBox(height: 10),
                    _buildXPProgressBar(),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.style, color: Colors.blueAccent),
                          onPressed: () => _navigateToPage(TarotReadingScreen()),
                        ),
                        IconButton(
                          icon: Icon(Icons.blur_on, color: Colors.blueAccent),
                          onPressed: () => _navigateToPage(AuraCatcherScreen()),
                        ),
                        IconButton(
                          icon: Icon(Icons.brightness_2, color: Colors.blueAccent),
                          onPressed: () => _navigateToPage(MoonCycleScreen()),
                        ),
                        IconButton(
                          icon: Icon(Icons.auto_awesome, color: Colors.blueAccent),
                          onPressed: () {
                            if (userId != null) {
                              _navigateToPage(SoulJourneyScreen(userId: userId));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: User not logged in")),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildCardSection(
                      title: "Today's Affirmation",
                      content: '“I am in alignment with my higher purpose.”',
                      icon: Icons.lightbulb_outline,
                    ),
                    SizedBox(height: 10),
                    _buildCardSection(
                      title: "Today's Challenge",
                      content: _todaysChallenge,
                      icon: Icons.check_circle_outline,
                      onTap: _completeChallenge,
                      isDisabled: _challengeCompleted,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      padding: EdgeInsets.all(12),
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
            child: Text(
              'Welcome back, ${user?.name ?? "Guest"}!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgressBar() {
    int xpNeeded = _spiritualLevel * 100;
    double progress = _spiritualXP / xpNeeded;

    return Column(
      children: [
        Text(
          'Level $_spiritualLevel • XP: $_spiritualXP / $xpNeeded',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress > 1 ? 1 : progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildCardSection({
    required String title,
    required String content,
    IconData? icon,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 28, color: Colors.blueAccent),
          SizedBox(width: 10),
          Expanded(child: Text(content)),
          IconButton(
            icon: Icon(Icons.people, color: Colors.blueAccent),
            onPressed: () => _navigateToPage(UserDiscoveryScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(child: Text("Error loading profile", style: TextStyle(color: Colors.red)));
  }
}