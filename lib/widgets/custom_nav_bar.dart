import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/soul_journey_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/friends_page.dart';
import '../screens/aura_catcher.dart';
import '../screens/spiritual_guidance_screen.dart';
import '../screens/tarot_reading_screen.dart';
import '../screens/more_menu_screen.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Soul Journey"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(
          icon: FutureBuilder<int>(
            future: _getPendingFriendRequests(),
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
        BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: 'Guidance'),
        BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Tarot'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'), // ✅ More menu button
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }

  // ✅ Fetch pending friend requests count
  Future<int> _getPendingFriendRequests() async {
    return 0; // Replace with the actual API call to fetch the count
  }
}
