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
import 'business_profile_page.dart';
import 'submit_service_page.dart';
import 'all_ads_page.dart';
import '../widgets/banner_ad_widget.dart'; // ✅ BannerAdWidget import
import 'feedback_screen.dart'; // 👈 Add this with the other imports
import 'horoscope_screen.dart';
import 'package:confetti/confetti.dart';
import 'new_features_slider_screen.dart'; // ✅ Correct file import

class HomeScreen extends StatefulWidget {
  final String userName;

  HomeScreen({required this.userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  final supabaseService = SupabaseService();
  final _audioPlayer = AudioPlayer();
  String _mysticReadingResult = '';
  bool _isLoadingBirthChart = false;

// Animation controllers for the Mystic Card
  late AnimationController _cardController;
  late Animation<Offset> _cardOffsetAnimation;

// Confetti controller for celebration 🎉
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));


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

  DateTime? _selectedMysticDOB;

  late AnimationController _pulseController;

  // ✅ Auto Carousel Controllers
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _pageController = PageController(initialPage: 0);

    _cardOffsetAnimation = Tween<Offset>(
      begin: Offset(0, 1), // Starts off-screen
      end: Offset(0, 0), // Ends on-screen
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));

    _loadUserProfile();
    _fetchTodaysAffirmation();
    _loadAds();
    _fetchLatestUsers();
    _startInactivityTimer();
    _updateOnlineStatus(true);
    _startCarouselAutoScroll();

    // ✅ Fetch achievements cleanly
    supabaseService.fetchUserAchievements(userId).then((result) {
      setState(() {
        _achievements = result;
      });
    });
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _inactivityTimer?.cancel();
    _cardController.dispose();
    _confettiController.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this); // Clean up
    print("🔵 HomeScreen Observer Detached");
    super.dispose();
    _updateOnlineStatus(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🟢 AppLifecycleState changed: $state");

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (state == AppLifecycleState.resumed) {
      print("✅ App resumed - mark user ONLINE");
      supabase.from('profiles').update({
        'is_online': true,
        'last_seen': null,
      }).eq('id', userId);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      print("⛔ App paused/inactive/detached - mark user OFFLINE");
      supabase.from('profiles').update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }
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

  void _startCarouselAutoScroll() {
    _carouselTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= _ads.length + 1) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
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
       // await _audioPlayer.play(AssetSource('sounds/affirmation_chime.mp3'));
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
      final fetchedAds = await supabase
          .from('service_ads')
          .select('''
      id,
      user_id,
      name,
      tagline,
      description,
      profile_image_url,
      rating,
      created_at,
      expiry_date,
      service_ads_categories (
        service_categories (
          id,
          name
        )
      )
    ''')
          .order('created_at', ascending: false);

      final now = DateTime.now();

      final activeAds = fetchedAds.map<Map<String, dynamic>>((ad) {
        final categories = (ad['service_ads_categories'] as List)
            .map((item) => item['service_categories']['name'] as String)
            .toList();

        return {
          ...ad,
          'categories': categories, // ✅ Add categories to the ad object
        };
      }).where((ad) {
        final expiry = DateTime.tryParse(ad['expiry_date'] ?? '');
        return expiry == null || expiry.isAfter(now);
      }).toList();

      activeAds.shuffle();

      setState(() {
        _ads = activeAds.take(4).toList(); // ✅ Or however many you want to show
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

  Future<void> _pickMysticDOB(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMysticDOB = pickedDate;
        _mysticReadingResult = ''; // clear previous reading

      });
    }
  }


  Future<void> _submitMysticBirthChart() async {
    if (_selectedMysticDOB == null) return;

    final dobString = '${_selectedMysticDOB!.year}-${_selectedMysticDOB!.month.toString().padLeft(2, '0')}-${_selectedMysticDOB!.day.toString().padLeft(2, '0')}';

    // Show loading
    setState(() {
      _isLoadingBirthChart = true;
      _mysticReadingResult = ''; // Clear previous
    });

    try {
      final reading = await supabaseService.getMysticBirthReading(dobString);

      setState(() {
        _mysticReadingResult = reading;
        _isLoadingBirthChart = false;
      });

      _cardController.forward();   // Slide up!
      _confettiController.play();  // 🎉 Party!
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isLoadingBirthChart = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get reading.')));
    }
  }


  List<Map<String, dynamic>> _achievements = [];



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
              'Aurana 🌌',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,

          ),
        ),
      ),

      // ✅ The ad comes here!
      body: Stack(
        children: [
          // ✅ 1. Background Image at the bottom
          Positioned.fill(
            child: Image.asset(
              getRotatingBackground(), // Your dynamic background function!
              fit: BoxFit.cover,
            ),
          ),

          // ✅ 2. Main UI content layered above
          Column(
            children: [
              // ✅ Banner Ad + Confetti on top
              Stack(
                children: [
                  BannerAdWidget(), // ⬅️ Your Ad at the top
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      emissionFrequency: 0.05,
                      numberOfParticles: 30,
                      gravity: 0.2,
                      colors: [Colors.amber, Colors.purpleAccent, Colors.cyanAccent],
                    ),
                  ),
                ],
              ),

              // ✅ Scrollable Content
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildGreetingSection(),
                      SizedBox(height: 20),
                      _buildAnimatedButtons(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _soulMatchButton()),
                          SizedBox(width: 10),
                          Expanded(child: _spiritualGuidanceButton()),
                        ],
                      ),
                      SizedBox(height: 20),
                      _adCarousel(),
                      SizedBox(height: 20),
                      _spiritualServicesButton(),
                      SizedBox(height: 20),
                      _exploreRealmsButton(), // ⬅️ Insert this right after any section
                      SizedBox(height: 20),
                      _affirmationSection(),
                      SizedBox(height: 20),
                      _buildMysticBirthChartBox(),
                      SizedBox(height: 20),
                      _buildLatestSoulTribeSection(),
                      SizedBox(height: 20),
                      _buildAchievementsAndQuestTab(),
                      SizedBox(height: 20),
                      _buildFeedbackFooter(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),


    );
  }

  Widget _loadingCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(color: Colors.amberAccent),
      ),
    );
  }

  Widget _animatedMysticCard(String readingText) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10), // space for the close button
              Text(
                '🌟 Mystic Reading',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                readingText,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => Share.share('Check out my Mystic Birth Chart!\n\n$readingText'),
                icon: Icon(Icons.share, color: Colors.white),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          // Close (X) button
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mysticReadingResult = ''; // Clear the reading and hide the card
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysticBirthChartBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade900.withOpacity(0.8),
                Colors.deepPurple.shade800.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔮 Mystic Birth Chart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Discover the spiritual meaning of any date of birth. Enter a date and reveal its hidden wisdom!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 16),

              // Date Picker Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickMysticDOB(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedMysticDOB == null
                              ? 'Select a Date of Birth'
                              : '${_selectedMysticDOB!.day}/${_selectedMysticDOB!.month}/${_selectedMysticDOB!.year}',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _selectedMysticDOB == null ? null : _submitMysticBirthChart,
                    icon: Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text('Reveal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade400,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // The result card (if available)
              SlideTransition(

              position: _cardOffsetAnimation,
                child: _mysticReadingResult.isNotEmpty
                    ? _animatedMysticCard(_mysticReadingResult)
                    : SizedBox.shrink(),
              ),

            ],
          ),
        ),
      ],
    );
  }

// 🟣 ADD THIS METHOD BELOW _buildLatestSoulTribeSection()

  Widget _buildAchievementsAndQuestTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20),

        // ⭐ Achievements Section
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10),

              _achievements.isEmpty
                  ? Text('No achievements yet!', style: TextStyle(color: Colors.white70))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _achievements.map((achievement) {
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
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: achievement['icon_url'] != null
                                  ? NetworkImage(achievement['icon_url'])
                                  : AssetImage('assets/images/default_icon.png') as ImageProvider,
                            ),
                            SizedBox(height: 8),
                            Text(
                              achievement['title'] ?? 'Achievement',
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

      ],
    );
  }



  Widget _buildGreetingSection() {
    return GestureDetector(
      onTap: () {
        final userId = supabase.auth.currentUser?.id;

        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: userId),
            ),
          );
        } else {
          print("❌ No user ID found.");
        }
      },
      child: Container(
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
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
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
                  Color(0xFFFFEB3B), // Yellow
                  Color(0xFF4CAF50), // Green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              AuraCatcherScreen(),
            ),
            _animatedButton(
              "Tribe Finder",
              LinearGradient(
                colors: [
                  Color(0xFF2196F3), // Blue
                  Color(0xFF3F51B5), // Indigo
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              SoulConnectionsScreen(),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _animatedButton(
              "Tarot",
              LinearGradient(
                colors: [
                  Color(0xFF9C27B0), // Violet
                  Color(0xFFFFFFFF),  // White
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              TarotReadingScreen(),
            ),
            _animatedButton(
              "Horoscope",
              LinearGradient(
                colors: [
                  Color(0xFFFF9800), // Orange
                  Color(0xFFFF5722), // Deep Orange
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              HoroscopeScreen(), // ✅ Your new Horoscope screen
            ),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoonCycleScreen())),
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
            'Moon Cycle',
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

  Widget _exploreRealmsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewFeaturesSliderScreen()),
        );
      },
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
                  Colors.lightBlueAccent.withOpacity(0.9),
                  Colors.deepPurpleAccent.withOpacity(0.8),
                ],
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.7),
                  blurRadius: 25,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.crisis_alert, // Looks like a glowing magical star 💫
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Explore Realms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.cyanAccent,
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
              IconButton(
                icon: Icon(Icons.share, color: Colors.lightBlueAccent),
                onPressed: () {
                  if (_affirmation != null && _affirmation!['text'] != null) {
                    Share.share('✨ Today\'s Affirmation on Aurana: \n\n"${_affirmation!['text']}" 🌟');
                  } else {
                    print("⚠️ No affirmation to share.");
                  }
                },
              ),

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
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _ads.length + 1,
        itemBuilder: (context, index) {
          if (index < _ads.length) {
            return _adCard(_ads[index]);
          }
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
          name: ad['name'] ?? '',
          serviceType: (ad['categories'] as List<dynamic>).join(', '),
          tagline: ad['tagline'] ?? '',
          description: ad['description'] ?? '',
          profileImageUrl: ad['profile_image_url'] ?? '',
          rating: (ad['rating'] as num?)?.toDouble() ?? 0.0,
          adCreatedDate: ad['created_at'] ?? '',
          userId: ad['user_id'] ?? '',
          adId: ad['id'] ?? '',
        )),
      ),
      child: Container(
        width: 160,
        height: 220,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge, // ✅ Stops overflow issues!
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: ad['profile_image_url'] != null && ad['profile_image_url'] != ''
                  ? Image.network(
                ad['profile_image_url'],
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                'assets/images/serv1.png',
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ✅ Less vertical padding
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ad['name'] ?? 'Service',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      (ad['categories'] as List<dynamic>).join(', '),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
        width: 150,
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
              Text("Place Your Service Here!", style: TextStyle(color: Colors.white)),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: user['id']), // ✅ Add this line
                    ),
                  );
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




