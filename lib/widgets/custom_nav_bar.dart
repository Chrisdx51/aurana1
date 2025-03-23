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
        // 🟥 ROOT CHAKRA - HOME
        BottomNavigationBarItem(
          icon: Icon(
            Icons.diamond,
            color: selectedIndex == 0 ? Colors.redAccent : Colors.white70,
          ),
          label: 'Home',
        ),

        // 🟧 SACRAL CHAKRA - SOUL MATCH
        BottomNavigationBarItem(
          icon: Icon(
            Icons.favorite,
            color: selectedIndex == 1 ? Colors.orangeAccent : Colors.white70,
          ),
          label: 'Soul Match',
        ),

        // 🟨 SOLAR PLEXUS CHAKRA - AURA
        BottomNavigationBarItem(
          icon: Icon(
            Icons.star,
            color: selectedIndex == 2 ? Colors.yellowAccent : Colors.white70,
          ),
          label: 'Aura',
        ),

        // 🟩 HEART CHAKRA - FRIENDS & NOTIFICATIONS
        BottomNavigationBarItem(
          icon: FutureBuilder<int>(
            future: _getPendingFriendRequests(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                children: [
                  Icon(
                    Icons.notifications,
                    color: selectedIndex == 3 ? Colors.greenAccent : Colors.white70,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Notifications',
        ),

        // 🟦 THROAT CHAKRA - PROFILE
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color: selectedIndex == 4 ? Colors.blueAccent : Colors.white70,
          ),
          label: 'Profile',
        ),

        // 🟪 THIRD EYE CHAKRA - MORE MENU
        BottomNavigationBarItem(
          icon: Icon(
            Icons.self_improvement,
            color: selectedIndex == 5 ? Colors.purpleAccent : Colors.white70,
          ),
          label: 'More',
        ),

        // ⚪️ DIVINE LIGHT - SETTINGS
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: selectedIndex == 6 ? Colors.white : Colors.grey.shade400,
          ),
          label: 'Settings',
        ),
      ],

      // NAV BAR DESIGN
      backgroundColor: Colors.black,
      currentIndex: selectedIndex,
      onTap: onItemTapped,

      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      unselectedLabelStyle: TextStyle(color: Colors.white70),
    );
  }

  // ✅ FRIEND REQUEST COUNTER FUNCTION
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
