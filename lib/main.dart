import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ✅ Screens and Services
import 'services/supabase_service.dart';
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
import 'screens/all_ads_page.dart'; // ✅ Ads Page
import '../widgets/custom_nav_bar.dart';
import 'widgets/banner_ad_widget.dart'; // ✅ Added for the banner ad

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

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    messaging.getToken().then((token) {
      print("🔥 FCM Token: $token");
    });

    messaging.onTokenRefresh.listen((newToken) {
      print("🔄 Refreshed FCM Token: $newToken");
    });

    FirebaseMessaging.onMessage.listen((message) {
      print("🔔 Foreground notification received: ${message.notification?.title}");
      _showNotification(message);
    });

    MobileAds.instance.initialize(); // ✅ Initialize ads

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
        '/home': (context) => MainScreen(userId: 'TEMP'),
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

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await Supabase.instance.client.from('profiles').update({
        'fcm_token': fcmToken,
      }).eq('id', userId);
    }

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
  }

  void _initializeScreens() {
    _screens = [
      HomeScreen(userName: Supabase.instance.client.auth.currentUser?.email ?? "User"),
      SoulMatchPage(),
      SoulJourneyScreen(userId: widget.userId),
      FriendsPage(),
      ProfileScreen(userId: widget.userId),
      MoreMenuScreen(),
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
      body: Column(
        children: [
          const BannerAdWidget(), // ✅ Your Banner Ad
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
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
      appBar: AppBar(title: Text("More"), backgroundColor: Colors.deepPurple),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("Aura Catcher"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AuraCatcherScreen())),
          ),
          ListTile(
            leading: Icon(Icons.self_improvement),
            title: Text("Spiritual Guidance"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SpiritualGuidanceScreen())),
          ),
          ListTile(
            leading: Icon(Icons.style),
            title: Text("Tarot Reading"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TarotReadingScreen())),
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text("Horoscope"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HoroscopeScreen())),
          ),
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
          ListTile(
            leading: Icon(Icons.campaign),
            title: Text("All Ads"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllAdsPage())),
          ),
        ],
      ),
    );
  }
}
