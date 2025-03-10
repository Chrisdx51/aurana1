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
import 'business_profile_page.dart';
import 'submit_service_page.dart';
import 'all_ads_page.dart';

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
  double _buttonScale = 1.0; // ✅ Tracks button press animation
  Timer? _inactivityTimer; // ✅ Track inactivity timer
  Timer? _periodicTimer; // ✅ Periodic timer for marking offline
  bool _isPanelOpen = false; // ✅ Tracks if the recent users panel is open

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
          child: SingleChildScrollView( // ✅ Make page scrollable!
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  _buildGreetingSection(),
                  SizedBox(height: 20),
                  _buildAnimatedButtons(userId),
                  SizedBox(height: 20),
                  _buildAdCarousel(),
                  SizedBox(height: 20),
// "See All Ads" Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AllAdsPage()), // ✅ Make sure you have imported this page
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent, // Button color
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'See All Ads',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Adjust height if you want more or less space
                  // ❌ DO NOT wrap in Expanded inside SingleChildScrollView
                  Container(
                    height: 300,  // ✅ You can adjust the height later!
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInspirationSection()),
                        SizedBox(width: 10),
                        Expanded(child: _buildRecentUsersSection()),
                      ],
                    ),
                  ),


                  SizedBox(height: 40), // ✅ Bottom spacing for scrolling
                ],
              ),
            ),
          ),
        ),

      ),
    );
  }

  Widget _buildAdCarousel() {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAdCard(isCallToAction: true),   // CTA Card (First)
          _buildAdCard(),                      // Placeholder Ad
          _buildAdCard(),                      // Placeholder Ad
          _buildAdCard(isCallToAction: true),   // CTA Card (Last)
        ],
      ),
    );
  }

  Widget _buildAdCard({bool isCallToAction = false}) {
    return GestureDetector(
      onTap: () {
        print('Tapped! isCallToAction: $isCallToAction'); // 👈 Add this for debugging!

        if (isCallToAction) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SubmitYourServicePage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessProfilePage(
                name: 'Celestial Healer',
                serviceType: 'Tarot Reader',
                tagline: 'Unlock your destiny!',
                description: 'I am an experienced Tarot Reader helping you find clarity and purpose in life. Connect with your higher self today!',
                profileImageUrl: 'https://i.pravatar.cc/300',
                rating: 4.5,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 140,
        height: 180,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCallToAction
                ? [Colors.amberAccent, Colors.orangeAccent]
                : [Colors.deepPurpleAccent.withOpacity(0.8), Colors.indigo.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isCallToAction ? Icons.add_circle_outline : Icons.auto_awesome,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isCallToAction ? "✨ Place Your Ad Here! ✨" : "Spiritual Guide",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (isCallToAction)
              SizedBox(height: 8),
            if (isCallToAction)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Share your spiritual services with the community!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
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
          if (!mounted) return;
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
                  color: Colors.white),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "✨ Daily Affirmations ✨",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),

          // ✅ Wrap Affirmations in Flexible
          Flexible(
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
    return Stack(
      children: [
        // ✅ Slide-Out Panel
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          left: _isPanelOpen ? 0 : -250, // ✅ Slide from left
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              if (!mounted) return;
              setState(() {
                _isPanelOpen = false;
              });
            },
            child: Container(
              width: 200,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), // ✅ Dark background
                borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👤 Recent Users",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<UserModel>>(
                      future: supabaseService.getRecentUsers(10), // ✅ Fetch last 10 users
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                        final users = snapshot.data!;
                        if (users.isEmpty) {
                          return Center(child: Text("No recent users yet!", style: TextStyle(color: Colors.white)));
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() => _isPanelOpen = false);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProfileScreen(userId: user.id)),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Column( // ✅ NEW layout here!
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: (user.icon != null && user.icon!.isNotEmpty)
                                          ? NetworkImage(user.icon!)
                                          : AssetImage("assets/default_avatar.png") as ImageProvider,
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user.name, style: TextStyle(fontSize: 14, color: Colors.white)),
                                        Text(
                                          user.isOnline == true
                                              ? "🟢 Online"
                                              : (user.lastSeen != null
                                              ? "🔴 Last Seen: ${_formatLastSeen(user.lastSeen!)}"
                                              : "🔴 Last Seen: Unknown"),
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),


        // ✅ Open Panel Button
        Positioned(
          left: 0,
          top: 20,
          child: IconButton(
            icon: Icon(Icons.chevron_right, size: 30, color: Colors.white),
            onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
          ),
        ),
      ],
    );
  }
}

// ✅ Format lastSeen as 'X time ago' or a friendly date
String _formatLastSeen(String isoDateString) {
  try {
    DateTime lastSeenTime = DateTime.parse(isoDateString);
    Duration difference = DateTime.now().difference(lastSeenTime);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hrs ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return "${difference.inDays} days ago";
    }
  } catch (e) {
    print("❌ Error parsing lastSeen: $e");
    return "Unknown";
  }
}



