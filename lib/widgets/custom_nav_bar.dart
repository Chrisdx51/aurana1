import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Ensure this is here!

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
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Soul Match'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Soul Journey'),

        // ✅ Friends with pending request badge
        BottomNavigationBarItem(
          icon: FutureBuilder<int>(
            future: _getPendingFriendRequests(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                children: [
                  Icon(Icons.people),
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          count.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Friends',
        ),

        // ✅ Profile tab (NEW!)
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),

        // ✅ More menu to hold everything else
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
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
          .from('friend_requests') // Change if using a different table!
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
