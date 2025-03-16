// ⬇️ IMPORTS
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_nav_bar.dart';
import 'profile_screen.dart';
import 'soul_match_page.dart';
import 'tarot_reading_screen.dart';
import 'aura_catcher.dart';
import 'moon_cycle_screen.dart';
import 'soul_journey_screen.dart';
import 'user_discovery_screen.dart';
import 'friends_page.dart';
import 'business_profile_page.dart';
import 'submit_service_page.dart';
import 'all_ads_page.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  HomeScreen({required this.userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final supabaseService = SupabaseService();
  final _audioPlayer = AudioPlayer();

  UserModel? user;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isAffirmationLoading = true;
  bool _adsLoading = true;

  Timer? _inactivityTimer;

  Map<String, dynamic>? _affirmation;
  List<Map<String, dynamic>> _ads = [];

  final List<String> backgroundImages = [
    'assets/images/home.png',
    'assets/images/catcher.png',
    'assets/images/misc.png',
  ];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadUserProfile();
    _fetchTodaysAffirmation();
    _loadAds();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("No user logged in");

      final profile = await supabaseService.getUserProfile(userId);
      setState(() {
        user = profile;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading profile: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTodaysAffirmation() async {
    setState(() => _isAffirmationLoading = true);

    final result = await supabaseService.fetchTodaysAffirmation();

    if (result != null) {
      setState(() {
        _affirmation = result;
        _isAffirmationLoading = false;
      });

      try {
        await _audioPlayer.play(AssetSource('sounds/affirmation_chime.mp3'));
      } catch (e) {
        print("🔇 Sound error: $e");
      }
    } else {
      setState(() => _isAffirmationLoading = false);
    }
  }

  Future<void> _loadAds() async {
    setState(() => _adsLoading = true);

    try {
      final fetchedAds = await supabaseService.fetchBusinessAds();
      final now = DateTime.now();

      final activeAds = fetchedAds.where((ad) {
        final expiry = DateTime.tryParse(ad['expiry_date'] ?? '');
        return expiry == null || expiry.isAfter(now);
      }).toList();

      activeAds.shuffle();

      setState(() {
        _ads = activeAds.take(4).toList();
        _adsLoading = false;
      });
    } catch (e) {
      print("❌ Ads load error: $e");
      setState(() => _adsLoading = false);
    }
  }

  String getRotatingBackground() {
    int day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    return backgroundImages[(day ~/ 3) % backgroundImages.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Aurana 🌌'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage())),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(getRotatingBackground()),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGreetingSection(),
              SizedBox(height: 20),
              _buildAnimatedButtons(),
              SizedBox(height: 20),
              _affirmationSection(),
              SizedBox(height: 20),
              _spiritualServicesButton(),
              SizedBox(height: 20),
              _buildLatestSoulTribeSection(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                ? NetworkImage(user!.avatar!)
                : AssetImage("assets/images/default_avatar.png") as ImageProvider,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Welcome back, ${user?.name ?? "Guest"}!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _animatedButton("Soul Journey", Colors.deepPurple, SoulJourneyScreen(userId: user!.id)),
            _animatedButton("Aura Catcher", Colors.blueAccent, AuraCatcherScreen()),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _animatedButton("Discovery", Colors.teal, UserDiscoveryScreen()),
            _animatedButton("Tarot", Colors.orange, TarotReadingScreen()),
          ],
        ),
        SizedBox(height: 20),
        _soulMatchButton(),
      ],
    );
  }

  Widget _animatedButton(String text, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        width: 150,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.5)]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _soulMatchButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SoulMatchPage())),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Keeps things neat!
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.8),
                  Colors.purpleAccent.withOpacity(0.6),
                ],
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.favorite,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Soul Match',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.purpleAccent.withOpacity(0.8),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _affirmationSection() {
    if (_isAffirmationLoading) return CircularProgressIndicator();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text("✨ Today's Affirmation ✨", style: TextStyle(fontSize: 18, color: Colors.amberAccent)),
          SizedBox(height: 12),
          Text(_affirmation?['text'] ?? "No affirmation today.", style: TextStyle(color: Colors.white70)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.favorite, color: Colors.pinkAccent), onPressed: () {}),
              IconButton(icon: Icon(Icons.share, color: Colors.lightBlueAccent), onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _spiritualServicesButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllAdsPage())),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // reduced horizontal padding
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.6),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                "Spiritual Services",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  overflow: TextOverflow.ellipsis, // 🛠️ Handles overflow safely!
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLatestSoulTribeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("⭐ Latest Aurana Tribe Members", style: TextStyle(color: Colors.white, fontSize: 18)),
        SizedBox(height: 10),
        // You can add your own implementation for showing latest members here.
      ],
    );
  }
}
