import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'screens/all_ads_page.dart';  // ✅ THIS IS CORRECT

// ✅ Screens and Services
import 'services/supabase_service.dart';
import 'screens/settings_screen.dart'; // ✅ Add this if not already there
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/friends_page.dart';
import 'screens/aura_catcher.dart';
import 'screens/tarot_reading_screen.dart';
import 'screens/spiritual_guidance_screen.dart';
import 'screens/soul_journey_screen.dart';
import 'screens/more_menu_screen.dart';
import 'screens/moon_cycle_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/soul_match_page.dart';
import 'screens/horoscope_screen.dart';
import '../widgets/custom_nav_bar.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

// ✅ ADD THIS FUNCTION (NEW)
Future<void> saveFcmToken() async {
  String? userId = Supabase.instance.client.auth.currentUser?.id;
  String? fcmToken = await FirebaseMessaging.instance.getToken();

  if (userId == null || fcmToken == null) {
    print("❌ User not logged in or no FCM token");
    return;
  }

  // ✅ Save token to Supabase
  await Supabase.instance.client.from('profiles').update({
    'fcm_token': fcmToken,
  }).eq('id', userId);

  print("✅ FCM token saved to Supabase: $fcmToken");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();

    print("🔄 Loading environment variables...");
    await dotenv.load(fileName: ".env");
    print("✅ Environment variables loaded!");

    final bool available = await InAppPurchase.instance.isAvailable();
    print(available
        ? "✅ In-App Purchase is available!"
        : "❌ In-App Purchase not available on this device.");

    final String? openAiKey = dotenv.env['OPENAI_API_KEY'];
    if (openAiKey == null || openAiKey.isEmpty) {
      throw Exception("❌ Missing OpenAI API Key in .env file!");
    }

    final String? apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("❌ Missing Gemini API Key in .env file!");
    }

    print("✅ Gemini API Key Loaded!");

    OpenAI.apiKey = openAiKey;
    print("✅ OpenAI API Initialized!");

    print("🔄 Initializing Supabase...");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase initialized!");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    // ✅ Initialize flutterLocalNotificationsPlugin
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        print('🔔 Notification payload: ${notificationResponse.payload}');
        // Optional: You can navigate to specific screens here
      },
    );

    // ✅ Create Notification Channel for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'aurana_channel',
        'Aurana Notifications',
        description: 'Aurana App Notifications Channel',
        importance: Importance.high,
      ),
    );

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await saveFcmToken();

    messaging.onTokenRefresh.listen((newToken) {
      print("🔄 Refreshed FCM Token: $newToken");
      saveFcmToken();
    });

    FirebaseMessaging.onMessage.listen((message) {
      print("🔔 Foreground notification received: ${message.notification?.title}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("👉 Notification tapped: ${message.notification?.title}");
      // Optional: Navigate to page
    });

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
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/login': (context) => AuthScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final SupabaseService supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      await Supabase.instance.client.from('profiles').update({
        'is_online': true,
        'last_seen': null,
      }).eq('id', user.id);
    } else {
      await Supabase.instance.client.from('profiles').update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
  }

  Future<void> _checkSession() async {
    await Future.delayed(Duration(seconds: 2));
    bool sessionRestored = await supabaseService.restoreSession();

    if (!sessionRestored) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
      return;
    }

    final userId = user.id;

    await Supabase.instance.client.from('profiles').update({
      'is_online': true,
      'last_seen': null,
    }).eq('id', userId);

    // ✅ ADD THIS TOO (to make sure token is up to date on login success)
    await saveFcmToken();

    final response = await Supabase.instance.client.from('profiles')
        .select('name, bio, dob, city, country, gender, privacy_setting')
        .eq('id', userId)
        .maybeSingle();

    if (response == null || response.values.any((value) => value == null || value.toString().trim().isEmpty)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EditProfileScreen(userId: userId, forceComplete: true)),
      );
      return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(userId: userId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
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

    // ✅ Start periodic updates to last_active
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel(); // Stops the timer when screen is disposed
        return;
      }

      Supabase.instance.client.from('profiles').update({
        'last_active': DateTime.now().toIso8601String(),
      }).eq('id', widget.userId);

      print("🔄 Updated last_active timestamp");
    });
  }


  void _initializeScreens() {
    _screens = [
      HomeScreen(userName: Supabase.instance.client.auth.currentUser?.email ?? "User"),
      SoulMatchPage(),
      AuraCatcherScreen(),
      SoulJourneyScreen(userId: widget.userId),
      FriendsPage(),
      ProfileScreen(userId: widget.userId),
      MoreMenuScreen(),
      SettingsScreen(),
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
      body: Expanded(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sacred Tools ✨"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/guide.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _glowingCard(
                context,
                title: "Spiritual Guidance",
                icon: Icons.self_improvement,
                color: Colors.indigoAccent,
                destination: SpiritualGuidanceScreen(),
              ),
              _glowingCard(
                context,
                title: "Tarot Reading",
                icon: Icons.style,
                color: Colors.pinkAccent,
                destination: TarotReadingScreen(),
              ),
              _glowingCard(
                context,
                title: "Horoscope",
                icon: Icons.auto_awesome,
                color: Colors.tealAccent,
                destination: HoroscopeScreen(),
              ),
              _glowingCard(
                context,
                title: "Moon Cycle",
                icon: Icons.wb_sunny,
                color: Colors.amberAccent,
                destination: MoonCycleScreen(),
              ),
              _glowingCard(
                context,
                title: "Journal",
                icon: Icons.book,
                color: Colors.greenAccent,
                destination: JournalScreen(),
              ),
              _glowingCard(
                context,
                title: "Sacred Services (Ads)",
                icon: Icons.campaign,
                color: Colors.redAccent,
                destination: AllAdsPage(),
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "This sacred space offers more than features. 🌿",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Each path here is part of your spiritual journey, guiding you closer to your higher self and cosmic purpose. ✨",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _glowingCard(BuildContext context,
      {required String title,
        required IconData icon,
        required Color color,
        required Widget destination}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.4),
            ],
            radius: 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
