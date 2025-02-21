import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/social_feed_screen.dart';
import 'screens/friends_list_screen.dart';
import 'screens/spiritual_tools_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/more_menu_screen.dart';
import 'screens/aura_catcher.dart';
import 'screens/likes_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/relations_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/moon_cycle_screen.dart'; // ✅ Re-added
import 'screens/tarot_reading_screen.dart'; // ✅ Fixed Tarot Reading import
import 'screens/spiritual_guidance_screen.dart'; // ✅ Restored Spiritual Guidance
import 'screens/aura_catcher.dart'; // ✅ Already added, ensuring it's present

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
      home: AuthGate(), // ✅ Redirect users properly
    );
  }
}

// ✅ Checks if user is logged in & redirects correctly
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
    await Future.delayed(Duration(seconds: 2)); // Simulate loading

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      userId = session.user!.id;
      _isLoggedIn = true;
    }

    setState(() {
      _isChecking = false;
    });

    // ✅ Always redirect users to `MainScreen` to ensure navigation bar is present
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

// ✅ Main Navigation with Bottom Navigation Bar
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
    _screens = [
      HomeScreen(userName: "Guest"), // 🏠 Home
      SocialFeedScreen(), // 🌍 Feed
      FriendsListScreen(), // 👥 Friends
      JournalScreen(), // 📖 Journal
      ProfileScreen(userId: widget.userId), // 👤 Profile
      MoreMenuScreen(), // 📂 More Menu (Holds extra pages)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // ✅ Ensures the screen changes with the bottom bar
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
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

// 🟢 More Menu (For Extra Pages)
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
            leading: Icon(Icons.style),
            title: Text("Tarot Reading"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TarotReadingScreen())),
          ),
          ListTile(
            leading: Icon(Icons.self_improvement),
            title: Text("Spiritual Guidance"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SpiritualGuidanceScreen())),
          ),
          ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("Aura Catcher"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AuraCatcherScreen())),
          ),
          ListTile(
            leading: Icon(Icons.message),
            title: Text("Messages"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesScreen())),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen())),
          ),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text("Likes"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LikesScreen())),
          ),
          ListTile(
            leading: Icon(Icons.group),
            title: Text("Relations"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RelationsScreen())),
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text("Chats"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatsScreen())),
          ),
        ],
      ),
    );
  }
}

// 🟢 SETTINGS PAGE (Fully Included)
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
