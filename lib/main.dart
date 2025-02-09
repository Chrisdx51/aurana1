import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/notification_service.dart'; // ✅ Added for notifications
import 'screens/astrology_updates_screen.dart'; // ✅ Added import
import 'screens/challenges_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/friends_list_screen.dart'; // ✅ Added import
import 'screens/guided_breathing_screen.dart'; // ✅ Added import
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/moon_cycle_screen.dart'; // ✅ Added import
import 'screens/profile_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/social_feed_screen.dart'; // ✅ Updated import
import 'screens/spiritual_guidance_screen.dart'; // ✅ Fixed import
import 'screens/spiritual_tools_screen.dart';
import 'screens/tarot_reading_screen.dart'; // ✅ Added import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await NotificationService.init(); // ✅ Initialize notifications
  runApp(SacredConnectionsApp()); // ✅ Updated app name
}

class SacredConnectionsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sacred Connections', // ✅ Updated title
      theme: ThemeData(primarySwatch: Colors.teal), // ✅ Updated theme
      home: MainScreen(), // ✅ Set MainScreen as the default home
      routes: {
        '/tarot': (context) => TarotReadingScreen(),
        '/moon': (context) => MoonCycleScreen(), // Added MoonCycleScreen route
        '/breathing': (context) =>
            GuidedBreathingScreen(), // Added GuidedBreathingScreen route
        '/astrology': (context) => AstrologyUpdatesScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final List<Widget> _screens = [
    HomeScreen(),
    SocialFeedScreen(), // ✅ Replaced CommunityScreen
    FriendsListScreen(), // Now navigating to the Friends List
    SpiritualToolsScreen(),
    JournalScreen(),
    ChallengesScreen(),
    SessionsScreen(),
    SpiritualGuidanceScreen(), // ✅ Fixed AI Insights Screen reference
    ProfileScreen(),
    MoonCycleScreen(), // Added MoonCycleScreen
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-5354629198133392~9779711737', // Corrected AdMob unit ID
      size: AdSize.largeBanner, // Ensures correct size
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print("Ad failed to load: $error");
          _isBannerAdLoaded = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  void _onItemTapped(int index) {
    if (index < 7) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // Show modal or navigate to a new screen with the remaining tabs
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.lightbulb),
                title: Text('Guidance'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 7;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 8;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.nightlight_round),
                title: Text('Moon Cycle'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 9;
                  });
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 25), // Moves banner down to avoid notification area
          // Blue banner area for the ad
          Container(
            width: double.infinity,
            height: 100, // Adjusted for large banner size
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade100,
                  Colors.blue.shade300,
                ], // Soft blue gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _isBannerAdLoaded
                ? Center(
                    child: SizedBox(
                      height: _bannerAd!.size.height.toDouble(),
                      width: _bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  )
                : Center(
                    child: Text(
                      "Ad Loading...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
          Expanded(
            child: _screens[_selectedIndex], // Display the selected screen
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.public), // Spiritual icon for "Social Feed"
              label: 'Feed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt), label: 'Friends'), // ✅ Fixed icon
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_run), label: 'Challenges'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Sessions'),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ), // Added More item
        ],
        currentIndex: _selectedIndex < 7 ? _selectedIndex : 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
