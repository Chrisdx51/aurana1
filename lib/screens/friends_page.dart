import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> suggestedFriends = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchFriends();
    fetchSuggestedFriends();
  }

  Future<void> fetchFriends() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('relations')
          .select('friend_id, friend:profiles!fk_friend(id, name, icon)')
          .or('user_id.eq.${user.id}, friend_id.eq.${user.id}')
          .eq('status', 'accepted');

      final formattedFriends = response
          .map((relation) => relation['friend'] as Map<String, dynamic>)
          .where((friend) => friend['id'] != user.id)
          .toList();

      setState(() => friends = formattedFriends);
    } catch (error) {
      print("❌ Error fetching friends: $error");
    }
  }

  Future<void> fetchSuggestedFriends() async {
    try {
      final response = await supabase.from('profiles').select('id, name, icon').limit(5);
      setState(() => suggestedFriends = response);
    } catch (error) {
      print("❌ Error fetching suggested friends: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg2.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Friends',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(Icons.notifications_none, color: Colors.white, size: 28),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Search Bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search friends...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Friends Grid
                  _buildSectionTitle('My Friends'),
                  SizedBox(height: 10),
                  friends.isEmpty
                      ? _buildEmptyState('No friends found.')
                      : _buildFriendsGrid(friends),

                  SizedBox(height: 30),

                  // Suggested Friends
                  _buildSectionTitle('Suggested Friends'),
                  SizedBox(height: 10),
                  suggestedFriends.isEmpty
                      ? _buildEmptyState('No suggestions available.')
                      : _buildSuggestedFriendsList(suggestedFriends),

                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------
  // Helper Widgets Below Here
  // --------------------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildFriendsGrid(List<Map<String, dynamic>> friendList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // parent scroll view handles scrolling
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: friendList.length,
      itemBuilder: (context, index) {
        final friend = friendList[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB0E0E6).withOpacity(0.8),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: friend['icon'] != null
                ? NetworkImage(friend['icon'])
                : AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          SizedBox(height: 12),
          Text(
            friend['name'],
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverId: friend['id'],
                    receiverName: friend['name'],
                  ),
                ),
              );
            },
            icon: Icon(Icons.message, size: 18),
            label: Text('Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedFriendsList(List<Map<String, dynamic>> suggestedList) {
    return Column(
      children: suggestedList.map((user) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: user['icon'] != null
                ? NetworkImage(user['icon'])
                : AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text(
            user['name'],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              // Future implementation: send friend request!
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Add'),
          ),
        );
      }).toList(),
    );
  }
}
