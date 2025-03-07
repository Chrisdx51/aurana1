import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_nav_bar.dart';
import 'profile_screen.dart';
import 'tarot_reading_screen.dart';
import 'aura_catcher.dart';
import 'moon_cycle_screen.dart';
import 'soul_journey_screen.dart';
import 'user_discovery_screen.dart';
import 'friends_page.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  HomeScreen({required this.userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService supabaseService = SupabaseService();
  UserModel? user;
  bool _isLoading = true;
  bool _hasError = false;
  double _buttonScale = 1.0;
  Timer? _inactivityTimer; // ✅ Track inactivity timer
  Timer? _periodicTimer; // ✅ Periodic timer for marking offline

  final List<String> backgroundImages = [
    'assets/images/bg1.png',
    'assets/images/bg2.png',
    'assets/images/bg3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _updateOnlineStatus(); // ✅ Mark user online when app starts
    _resetInactivityTimer(); // ✅ Start tracking inactivity

    // ✅ Auto Mark Offline After 10 Mins of Inactivity
    _periodicTimer = Timer.periodic(Duration(minutes: 10), (timer) async {
      if (!mounted) return;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'is_online': false})
          .eq('id', userId);
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // ✅ Mark user as online immediately
    await Supabase.instance.client
        .from('profiles')
        .update({'is_online': true})
        .eq('id', userId);

    print("🟢 User marked as online.");

    // ✅ Cancel previous timer
    _inactivityTimer?.cancel();

    // ✅ Set new timer for 10 minutes
    _inactivityTimer = Timer(Duration(minutes: 10), () async {
      if (!mounted) return;

      // ✅ Mark user offline after 10 minutes of inactivity
      await Supabase.instance.client
          .from('profiles')
          .update({'is_online': false})
          .eq('id', userId);

      print("🔴 User marked as offline due to inactivity.");
    });
  }

  Future<void> _updateOnlineStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'is_online': true})
        .eq('id', userId);
  }

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

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  String getRotatingBackground() {
    int day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    return backgroundImages[(day ~/ 3) % backgroundImages.length];
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return GestureDetector(
      onTap: _resetInactivityTimer, // ✅ Reset inactivity timer on tap
      onPanDown: (_) => _resetInactivityTimer(), // ✅ Reset on swipe/touch
      child: Scaffold(
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
          actions: [
            IconButton(
              icon: Icon(Icons.notifications, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FriendsPage()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(getRotatingBackground()),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 20),
              _buildGreetingSection(),
              SizedBox(height: 20),
              _buildAnimatedButtons(userId),
              SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildInspirationSection()),
                    SizedBox(width: 10),
                    Expanded(child: _buildRecentUsersSection()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButtons(String? userId) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAnimatedButton("Soul Journey", Colors.deepPurple,
                userId != null ? SoulJourneyScreen(userId: userId) : HomeScreen(userName: widget.userName)),
            _buildAnimatedButton("Aura Catcher", Colors.blueAccent, AuraCatcherScreen()),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAnimatedButton("Discovery", Colors.teal, UserDiscoveryScreen()),
            _buildAnimatedButton("Tarot", Colors.orange, TarotReadingScreen()),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedButton(String text, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _buttonScale = 0.9; // Shrink animation
        });
        Future.delayed(Duration(milliseconds: 200), () {
          setState(() {
            _buttonScale = 1.0; // Reset scale
          });
        });
        _navigateToPage(page);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 160,
        height: 90,
        transform: Matrix4.diagonal3Values(_buttonScale, _buttonScale, 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: user?.icon != null && user!.icon!.isNotEmpty
                ? NetworkImage(user!.icon!)
                : AssetImage("assets/images/default_avatar.png") as ImageProvider,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Welcome back, ${user?.name ?? "Guest"}!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            "✨ Daily Affirmations ✨",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                _buildAffirmation("I am at peace with my past and embrace my future."),
                _buildAffirmation("I radiate love, happiness, and positivity."),
                _buildAffirmation("I am in alignment with my higher self."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffirmation(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "• $text",
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            "👤 Recent Users",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: supabaseService.getRecentUsers(5), // ✅ Fetch last 5 users
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator()); // ✅ Show loader while fetching
                }
                final users = snapshot.data!;

                if (users.isEmpty) {
                  return Center(child: Text("No recent users yet!", style: TextStyle(color: Colors.white)));
                }

                return SizedBox(
                  height: 100, // ✅ Prevents stacking
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileScreen(userId: user.id)),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: (user.icon != null && user.icon!.isNotEmpty)
                                    ? NetworkImage(user.icon!)
                                    : AssetImage("assets/default_avatar.png") as ImageProvider,
                              ),
                              SizedBox(height: 5),
                              Text(user.name, style: TextStyle(fontSize: 14, color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}