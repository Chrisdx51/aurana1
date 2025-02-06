import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/spiritual_tools_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/ai_insights_screen.dart';

void main() {
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

  final List<Widget> _screens = [
    HomeScreen(),
    CommunityScreen(),
    ChatScreen(),
    SpiritualToolsScreen(),
    JournalScreen(),
    ChallengesScreen(),
    SessionsScreen(),
    AIInsightsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex], // Display the selected screen
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the navigation bar
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1), // Add a top border for separation
                ),
              ),
              child: BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Community'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
                  BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Tools'),
                  BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
                  BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Challenges'),
                  BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Sessions'),
                  BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'AI Insights'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.black, // Text/Icon color when selected
                unselectedItemColor: Colors.grey, // Text/Icon color when unselected
                backgroundColor: Colors.white, // Background of the navigation bar
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed, // Keeps icons always visible
              ),
            ),
          ),
        ],
      ),
    );
  }
}
