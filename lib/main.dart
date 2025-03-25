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
import 'screens/aura_catcher.dart';
import 'screens/tarot_reading_screen.dart';
import 'screens/spiritual_guidance_screen.dart';
import 'screens/more_menu_screen.dart';
import 'screens/moon_cycle_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/soul_match_page.dart';
import 'screens/horoscope_screen.dart';
import '../widgets/custom_nav_bar.dart';
import 'screens/connections_and_notifications_screen.dart'; // ✅ Your new notifications page

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
    sound: RawResourceAndroidNotificationSound('aurana_tranquil'), // 👈 This line!
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
    super.dispose();
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
      ConnectionsAndNotificationsScreen(userId: widget.userId), //
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
  final List<_ToolItem> tools = [
    _ToolItem(
      title: "Aura Catcher",
      description: "Discover the energy fields around you.",
      icon: Icons.light_mode,
      color: Colors.deepPurpleAccent,
      destination: AuraCatcherScreen(),
    ),
    _ToolItem(
      title: "Spiritual Guidance",
      description: "Receive messages from your higher self.",
      icon: Icons.self_improvement,
      color: Colors.indigoAccent,
      destination: SpiritualGuidanceScreen(),
    ),
    _ToolItem(
      title: "Tarot Reading",
      description: "Unveil the wisdom of the tarot cards.",
      icon: Icons.style,
      color: Colors.pinkAccent,
      destination: TarotReadingScreen(),
    ),
    _ToolItem(
      title: "Horoscope",
      description: "Explore your cosmic insights today.",
      icon: Icons.auto_awesome,
      color: Colors.tealAccent,
      destination: HoroscopeScreen(),
    ),
    _ToolItem(
      title: "Moon Cycle",
      description: "Track the moon phases and energy shifts.",
      icon: Icons.wb_sunny,
      color: Colors.amberAccent,
      destination: MoonCycleScreen(),
    ),
    _ToolItem(
      title: "Sacred Journal",
      description: "Reflect and write your soul’s journey.",
      icon: Icons.book,
      color: Colors.greenAccent,
      destination: JournalScreen(),
    ),
    _ToolItem(
      title: "Sacred Services (Ads)",
      description: "Explore offerings to support your path.",
      icon: Icons.campaign,
      color: Colors.redAccent,
      destination: AllAdsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Sacred Tools ✨",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/misc2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _introText(),
                  SizedBox(height: 20),
                  ...tools.map((tool) => _buildFeatureCard(context, tool)).toList(),
                  SizedBox(height: 40),
                  _closingMessage(),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _introText() {
    return Column(
      children: [
        Text(
          "Welcome to your Sacred Space",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Explore tools crafted for your spiritual journey. Let them guide you toward clarity, healing, and inner peace. ✨",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, _ToolItem tool) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => tool.destination));
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tool.color.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: tool.color.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: tool.color.withOpacity(0.8),
              radius: 28,
              child: Icon(tool.icon, size: 30, color: Colors.white),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    tool.description,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _closingMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "This isn't just a menu. It's your gateway to the divine tools that illuminate your soul's journey. 🌿",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Use these sacred tools with love and intention. Your path unfolds with each step you take here. ✨",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget destination;

  _ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.destination,
  });
}