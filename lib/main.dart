import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(message);
}

void _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'aurana_channel',
    'Aurana Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? "New Notification",
    message.notification?.body ?? "You have a new update",
    details,
  );
}

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

    print("🔄 Initializing Firebase...");
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🔥 Initialize Local Notifications
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.instance.getToken().then((token) {
      print("🔥 FCM Token: $token");
    });

    // 🔔 Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Foreground notification received: ${message.notification?.title}");
      _showNotification(message); // 🔥 Display Notification in Foreground
    });

    print("✅ Firebase initialized!");

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
      ProfileScreen(userId: Supabase.instance.client.auth.currentUser!.id), // ✅ Pass user ID
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
          BottomNavigationBarItem(
            icon: FutureBuilder<int>(
              future: SupabaseService().getPendingFriendRequestsCount(Supabase.instance.client.auth.currentUser?.id ?? ""),
              builder: (context, snapshot) {
                int count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    Icon(Icons.people, size: 30), // Friends Icon
                    if (count > 0) // ✅ Show notification only if requests exist
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            count.toString(),
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Friends',
          ),
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