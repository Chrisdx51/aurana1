import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_openai/dart_openai.dart';
import 'services/supabase_service.dart';
import 'screens/auth_screen.dart';
import 'package:aurana/screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friends_page.dart'; // ✅ Keep only one Friends Page
import 'screens/aura_catcher.dart';
import 'screens/tarot_reading_screen.dart';
import 'screens/spiritual_guidance_screen.dart';
import 'screens/soul_journey_screen.dart';
import 'screens/more_menu_screen.dart'; // ✅ More Menu Screen
import 'screens/moon_cycle_screen.dart';
import 'screens/journal_screen.dart';
import '../widgets/custom_nav_bar.dart'; // Import custom navigation bar
import 'screens/splash_screen.dart';  // ✅ Import splash screen
import 'package:in_app_purchase/in_app_purchase.dart';

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
    await Firebase.initializeApp();


    print("🔄 Loading environment variables...");
    await dotenv.load(fileName: ".env");
    print("✅ Environment variables loaded!");

    // Initialize In-App Purchase Connection
    final bool available = await InAppPurchase.instance.isAvailable();

    if (!available) {
      print("❌ In-App Purchase not available on this device.");
    } else {
      print("✅ In-App Purchase is available!");
    }

    // ✅ Load OpenAI API Key from the environment
    final String? openAiKey = dotenv.env['OPENAI_API_KEY']; // ✅ Fetch key properly

    if (openAiKey == null || openAiKey.isEmpty) {
      throw Exception("❌ Missing OpenAI API Key in .env file!");
    }
    final String? apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("❌ Missing Gemini API Key in .env file!");
    }

    print("✅ Gemini API Key Loaded!");

    OpenAI.apiKey = openAiKey; // ✅ Securely assign OpenAI API Key
    print("✅ OpenAI API Initialized!");
    print("🔄 Initializing Supabase...");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase initialized!");

    print("🔄 Initializing Firebase...");
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Add the new FCM token listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('🔄 Refreshed FCM Token: $newToken');

      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        print("❌ No logged-in user. Can't save token!");
        return;
      }

      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': newToken})
            .eq('id', user.id);

        print("✅ New FCM token saved to Supabase!");
      } catch (error) {
        print("❌ Error saving FCM token to Supabase: $error");
      }
    });


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

    String? fcmToken = await messaging.getToken();


    if (fcmToken != null) {
      print("🔥 NEW FCM Token: $fcmToken");
    } else {
      print("❌ No FCM Token generated.");
    }
    // ✅ Step 3: Listen for token refresh (optional but good practice)
    messaging.onTokenRefresh.listen((newToken) {
      print("🔄 Refreshed FCM Token: $newToken");
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
      //home: SplashScreen(),
      home: AuthGate(),  // ✅ Go directly to login or home

    );
  }
}


class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final SupabaseService supabaseService = SupabaseService();
  bool _isChecking = true;
  bool _isLoggedIn = false;
  String userId = "";

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
      // App is active again
      await Supabase.instance.client.from('profiles').update({
        'is_online': true,
        'last_seen': null, // Reset last seen
      }).eq('id', user.id);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is closed or in background
      await Supabase.instance.client.from('profiles').update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(), // Save last active time
      }).eq('id', user.id);
      print("❌ User is now OFFLINE");
    }
  }

  Future<void> _checkSession() async {
    await Future.delayed(Duration(seconds: 2));

    bool sessionRestored = await supabaseService.restoreSession();

    if (!sessionRestored) {
      print("❌ No session found. Redirecting to login.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print("❌ No user found. Redirecting to login.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
      return;
    }

    String userId = user.id;

    // ✅ Set user as ONLINE in Supabase
    await Supabase.instance.client.from('profiles').update({
      'is_online': true,
      'last_seen': null,
    }).eq('id', userId);

    // ✅ Get the FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    // ✅ Save the FCM token to Supabase
    if (fcmToken != null) {
      await Supabase.instance.client.from('profiles').update({
        'fcm_token': fcmToken,
      }).eq('id', userId);
      print("✅ FCM token saved to Supabase: $fcmToken");
    } else {
      print("❌ Failed to get FCM token");
    }

    // 🔍 Check if the user has completed their profile
    final response = await Supabase.instance.client
        .from('profiles')
        .select('name, bio, dob')
        .eq('id', userId)
        .maybeSingle();

    if (response == null ||
        response['name'] == null ||
        response['bio'] == null ||
        response['dob'] == null ||
        response['name'].toString().trim().isEmpty ||
        response['bio'].toString().trim().isEmpty ||
        response['dob'].toString().trim().isEmpty) {
      print("❌ Incomplete Profile! Redirecting to Profile Setup.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userId, forceComplete: true),
        ),
      );
      return;
    }

    // ✅ User has completed profile → Proceed to Main Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(userId: userId),
      ),
    );
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
      HomeScreen(userName: Supabase.instance.client.auth.currentUser?.email ?? "User"),
      SoulJourneyScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId), // ✅ Pass user ID properly
      FriendsPage(),
      AuraCatcherScreen(),
      SpiritualGuidanceScreen(),
      TarotReadingScreen(),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomNavBar( // ✅ This ensures the nav bar is always there
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