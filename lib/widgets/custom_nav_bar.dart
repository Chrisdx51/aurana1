import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        // 🌈 Root Chakra - RED (Home)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.diamond,
            color: selectedIndex == 0 ? Colors.lightBlueAccent : Colors.white,
          ),
          label: 'Home',
        ),

        // 🟠 Sacral Chakra - ORANGE (Soul Match)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.favorite,
            color: selectedIndex == 1 ? Colors.orange : Colors.white,
          ),
          label: 'Soul Match',
        ),

        // 🟡 Solar Plexus Chakra - YELLOW (Aura Catcher with Spiritual Icon)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.star, // ✨ Spiritual Feel
            color: selectedIndex == 2 ? Colors.yellow : Colors.white,
          ),
          label: 'Aura',
        ),

        // 🟢 Heart Chakra - GREEN (Soul Journey Wall)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.visibility, // 🛤️ Path-like icon for Soul Journey
            color: selectedIndex == 3 ? Colors.green : Colors.white,
          ),
          label: 'Soul Journey',
        ),

        // 🔵 Throat Chakra - BLUE (Friends)
        BottomNavigationBarItem(
          icon: FutureBuilder<int>(
            future: _getPendingFriendRequests(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                children: [
                  Icon(
                    Icons.people,
                    color: selectedIndex == 4 ? Colors.blue : Colors.white,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Friends',
        ),

        // 🟣 Third Eye Chakra - INDIGO (Profile)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color: selectedIndex == 5 ? Colors.indigo : Colors.white,
          ),
          label: 'Profile',
        ),

        // 🔮 Crown Chakra - VIOLET (More)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.self_improvement, // Swapped from more_horiz ➡️ Spiritual glow icon ✨
            color: selectedIndex == 6 ? Colors.purple : Colors.white,
          ),
          label: 'More',
        ),

        // ⚪️ White Light - SETTINGS (New Tab!)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: selectedIndex == 7 ? Colors.white : Colors.grey.shade400,
          ),
          label: 'Settings',
        ),
      ],

      backgroundColor: Colors.black,
      currentIndex: selectedIndex,
      onTap: onItemTapped,

      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
    );
  }

  // ✅ Fetch pending friend requests
  Future<int> _getPendingFriendRequests() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return 0;
    }

    try {
      final response = await Supabase.instance.client
          .from('friend_requests')
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      return response.length;
    } catch (e) {
      print('❌ Error fetching pending friend requests: $e');
      return 0;
    }
  }
}
