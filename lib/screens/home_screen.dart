// ⬇️ IMPORTS
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'spiritual_guidance_screen.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'soul_match_page.dart';
import 'tarot_reading_screen.dart';
import 'aura_catcher.dart';
import 'moon_cycle_screen.dart';
import 'soul_connections_screen.dart'; // ✅ New Import!
import 'friends_page.dart';
import 'business_profile_page.dart';
import 'submit_service_page.dart';
import 'all_ads_page.dart';
import '../widgets/banner_ad_widget.dart'; // ✅ BannerAdWidget import
import 'feedback_screen.dart'; // 👈 Add this with the other imports

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
// Add this to store your tribe members
  List<Map<String, dynamic>> _latestUsers = [];

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
    _fetchLatestUsers();
    _startInactivityTimer();
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
    _updateOnlineStatus(false);
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
  void _startInactivityTimer() {
    // Cancel any previous timer to avoid duplicates
    _inactivityTimer?.cancel();

    // Start a new periodic timer
    _inactivityTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      _updateLastActive();
    });
  }

  void _updateLastActive() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('profiles').update({
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    print("🕒 Last active updated at ${DateTime.now()}");
  }

  void _updateOnlineStatus(bool isOnline) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('profiles').update({
      'is_online': isOnline,
      'last_seen': isOnline ? null : DateTime.now().toIso8601String(),
    }).eq('id', userId);

    print(isOnline ? "✅ User marked ONLINE" : "❌ User marked OFFLINE");
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
      print("⚠️ No affirmation found for today.");

      // ✅ Automatically trigger weekly generation if none found
      await supabaseService.generateAndInsertWeeklyAffirmations();

      // ✅ Retry fetching after generating
      final retryResult = await supabaseService.fetchTodaysAffirmation();
      setState(() {
        _affirmation = retryResult;
        _isAffirmationLoading = false;
      });
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
  Future<void> _fetchLatestUsers() async {
    try {
      final latestUsers = await supabaseService.getLatestUsers(limit: 10);

      print("👀 Latest Users Returned: $latestUsers");

      setState(() {
        _latestUsers = latestUsers;
      });
    } catch (error) {
      print('❌ Error fetching latest users: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurpleAccent.withOpacity(0.3),
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Welcome to Aurana 🌌',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsPage())),
              ),
            ],
          ),
        ),
      ),

      // ✅ The ad comes here!
      body: Column(
        children: [
          BannerAdWidget(), // ✅ AD BANNER HERE, NO AD UNIT REQUIRED!
          Expanded(
            child: _isLoading
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
                    _adCarousel(),
                    SizedBox(height: 20),
                    _buildLatestSoulTribeSection(),
                    SizedBox(height: 20),
                    _buildFeedbackFooter(context),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
// 🟣 ADD THIS METHOD BELOW _buildLatestSoulTribeSection()

  Widget _buildAchievementsAndQuestTab() {
    // Dummy achievements for display; in real case, you would fetch from Supabase
    final List<Map<String, dynamic>> earnedAchievements = [
      {
        'title': 'First Quest Complete',
        'description': 'You completed your first quest!',
        'icon': Icons.emoji_events,
      },
      {
        'title': 'Aura Boost I',
        'description': 'Your aura reached level 1!',
        'icon': Icons.bolt,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20),

        // ⭐ Medals / Achievements Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '🏅 Your Achievements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10),

              // Achievements Display
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: earnedAchievements.map((achievement) {
                    return GestureDetector(
                      onTap: () {
                        Share.share('I just earned the "${achievement['title']}" badge on Aurana! 🌟');
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purpleAccent, Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              achievement['icon'],
                              color: Colors.yellowAccent,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              achievement['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // 🟣 Spiritual Quest Button
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/mystic-quests'); // Or use MaterialPageRoute if not yet in routes
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.tealAccent.shade400, Colors.teal.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.6),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'Spiritual Quest',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            _animatedButton(
              "Aura Catcher",
              LinearGradient(
                colors: [
                  Color(0xFFFFEB3B), // Yellow (Solar Plexus)
                  Color(0xFF4CAF50), // Green (Heart Chakra)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              AuraCatcherScreen(),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _animatedButton(
              "Tribe Finder",
              LinearGradient(
                colors: [
                  Color(0xFF2196F3), // Blue (Throat Chakra)
                  Color(0xFF3F51B5), // Indigo (Third Eye Chakra)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              SoulConnectionsScreen(),
            ),
            _animatedButton(
              "Tarot",
              LinearGradient(
                colors: [
                  Color(0xFF9C27B0), // Violet (Crown Chakra)
                  Color(0xFFFFFFFF), // White (Spirit)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              TarotReadingScreen(),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Keep your orbs as they are.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _soulMatchButton(),
            SizedBox(width: 20),
            _spiritualGuidanceButton(),
          ],
        ),
      ],
    );
  }


  Widget _spiritualGuidanceButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpiritualGuidanceScreen())),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.8),
                  Colors.cyanAccent.withOpacity(0.6),
                ],
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.auto_awesome, size: 50, color: Colors.white), // ✅ You can swap this with an image if you like!
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Guidance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.cyanAccent.withOpacity(0.8),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedButton(String text, LinearGradient gradient, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        width: 150,
        height: 80,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }


  Widget _soulMatchButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SoulMatchPage())),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              child: Image.asset('assets/images/yinyang.png', width: 70, height: 70), // ✅ Yin Yang Icon
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
          Text("✨ Today's Affirmation ✨", style: TextStyle(fontSize: 14, color: Colors.amberAccent)),
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
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                "Spiritual Services",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adCarousel() {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _ads.length + 1,
        itemBuilder: (context, index) {
          if (index < _ads.length) return _adCard(_ads[index]);
          return _ctaAdCard();
        },
      ),
    );
  }

  Widget _adCard(Map<String, dynamic> ad) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BusinessProfilePage(
          name: ad['name'],
          serviceType: ad['service_type'],
          tagline: ad['tagline'],
          description: ad['description'],
          profileImageUrl: ad['profile_image_url'],
          rating: ad['rating'] ?? 4.5,
          adCreatedDate: ad['created_at'],
          userId: ad['user_id'],
        )),
      ),
      child: Container(
        width: 140,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: ad['profile_image_url'] != null
                  ? Image.network(ad['profile_image_url'], height: 100, fit: BoxFit.cover)
                  : Image.asset('assets/images/serv1.png', height: 100, fit: BoxFit.cover),
            ),
            Expanded(
              child: Center(
                child: Text(ad['service_type'] ?? 'Service', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctaAdCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitYourServicePage())),
      child: Container(
        width: 140,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.amberAccent, Colors.purpleAccent]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 40, color: Colors.white),
              SizedBox(height: 10),
              Text("Place Your Ad Here!", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestSoulTribeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("⭐ Latest Aurana Tribe Members", style: TextStyle(color: Colors.white, fontSize: 12)),
        SizedBox(height: 10),
        _latestUsers.isEmpty
            ? Center(child: Text("No new tribe members yet!", style: TextStyle(color: Colors.white70)))
            : Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _latestUsers.length,
            itemBuilder: (context, index) {
              final user = _latestUsers[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to their profile or show details
                },
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user['avatar'] != null
                            ? NetworkImage(user['avatar'])
                            : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      ),
                      SizedBox(height: 8),
                      Text(user['name'] ?? "No Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildFeedbackFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Divider(color: Colors.white54, thickness: 1, indent: 40, endIndent: 40),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FeedbackScreen()),
              );
            },
            icon: Icon(Icons.bug_report, color: Colors.white, size: 16), // made icon smaller if you want
            label: Text(
              'If you sense a glitch in the matrix of Aurana, whisper it to us.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,  // 👈 THIS IS WHERE WE ADD FONT SIZE
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // optional, smaller padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Aurana © 2025 🌙',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }


}




