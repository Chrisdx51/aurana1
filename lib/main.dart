import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/notification_service.dart'; // ✅ Added for notifications
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/spiritual_tools_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/spiritual_guidance_screen.dart'; // ✅ Fixed import
import 'screens/spiritual_guidance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await NotificationService.init(); // ✅ Initialize notifications
  runApp(AuranaApp());
}

class AuranaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurana',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MainScreen(),
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
    CommunityScreen(),
    ChatScreen(),
    SpiritualToolsScreen(),
    JournalScreen(),
    ChallengesScreen(),
    SessionsScreen(),
    SpiritualGuidanceScreen(), // ✅ Fixed AI Insights Screen reference
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5354629198133392~9779711737', // Your real AdMob unit ID
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
    setState(() {
      _selectedIndex = index;
    });
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
                colors: [Colors.blue.shade100, Colors.blue.shade300], // Soft blue gradient
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
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Challenges'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Guidance'), // ✅ Renamed from AI Insights
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
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
