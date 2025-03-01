import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friends_page.dart'; // ✅ Keep only one Friends Page
import 'screens/aura_catcher.dart';
import 'screens/tarot_reading_screen.dart';
import 'screens/spiritual_guidance_screen.dart';
import 'screens/soul_journey_screen.dart';
import 'screens/more_menu_screen.dart'; // ✅ More Menu Screen
import 'screens/moon_cycle_screen.dart';
import 'screens/journal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print("🔄 Loading environment variables...");
    await dotenv.load(fileName: ".env");
    print("✅ Environment variables loaded!");

    print("🔄 Initializing Supabase...");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase initialized!");

    MobileAds.instance.initialize();
    runApp(AuranaApp());
  } catch (error) {
    print("❌ ERROR in main.dart: $error");
  }
}

class AuranaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aurana App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SupabaseService supabaseService = SupabaseService();
  bool _isChecking = true;
  bool _isLoggedIn = false;
  String userId = "";

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(Duration(seconds: 2));

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      userId = Supabase.instance.client.auth.currentUser?.id ?? "";
      _isLoggedIn = true;
    }

    setState(() {
      _isChecking = false;
    });

    if (!_isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _isChecking ? CircularProgressIndicator() : Container()),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;
  MainScreen({required this.userId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      HomeScreen(userName: "Guest"),
      SoulJourneyScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
      FriendsPage(), // ✅ Only one Friends Page now
      AuraCatcherScreen(),
      SpiritualGuidanceScreen(),
      TarotReadingScreen(),
      MoreMenuScreen(), // ✅ More Menu for extra features
    ];
  }

  void _onItemTapped(int index) {
    if (index == 7) {  // 7 is the More button index
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MoreMenuScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Soul Journey"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.light_mode), label: 'Aura Catcher'),
          BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: 'Spiritual Guidance'),
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Tarot Reading'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'), // ✅ More menu button
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("More")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.wb_sunny),
            title: Text("Moon Cycle"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MoonCycleScreen())),
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text("Journal"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JournalScreen())),
          ),
        ],
      ),
    );
  }
}
