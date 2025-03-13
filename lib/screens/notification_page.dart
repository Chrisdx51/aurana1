import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> friendRequests = [];
  List<Map<String, dynamic>> appNotifications = [];

  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
    fetchAppNotifications();
  }

  Future<void> fetchFriendRequests() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('friend_requests')
          .select('id, sender_id, sender:profiles!fk_sender(id, name, icon)')
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      setState(() {
        friendRequests = response;
      });
    } catch (error) {
      print('❌ Error fetching friend requests: $error');
    }
  }

  Future<void> fetchAppNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('notifications')
          .select('id, type, message, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        appNotifications = response;
      });
    } catch (error) {
      print('❌ Error fetching app notifications: $error');
    }
  }

  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    final receiverId = supabase.auth.currentUser?.id;
    if (receiverId == null) return;

    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      await supabase.from('friends').insert([
        {'user_id': senderId, 'friend_id': receiverId, 'status': 'accepted'},
        {'user_id': receiverId, 'friend_id': senderId, 'status': 'accepted'},
      ]);

      fetchFriendRequests();
      print("✅ Friend request accepted!");
    } catch (error) {
      print('❌ Error accepting friend request: $error');
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await supabase.from('friend_requests').delete().eq('id', requestId);
      fetchFriendRequests();
      print("✅ Friend request declined.");
    } catch (error) {
      print('❌ Error declining friend request: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows background behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // No solid color
        elevation: 0,
        title: Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A11CB).withOpacity(0.9), // Mystic purple
                Color(0xFF2575FC).withOpacity(0.8), // Deep blue
                Color(0xFF5F72BE).withOpacity(0.8), // Spiritual blue/lavender
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          children: [
            _buildSectionTitle('Friend Requests'),
            SizedBox(height: 10),
            friendRequests.isEmpty
                ? _buildEmptyState('No new friend requests.')
                : Column(
              children: friendRequests.map((request) {
                final sender = request['sender'];
                return Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: sender['icon'] != null
                          ? NetworkImage(sender['icon'])
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    title: Text(sender['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Wants to connect with you!'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => acceptFriendRequest(request['id'], sender['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => declineFriendRequest(request['id']),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            _buildSectionTitle('Other Notifications'),
            SizedBox(height: 10),
            appNotifications.isEmpty
                ? _buildEmptyState('No new notifications.')
                : Column(
              children: appNotifications.map((notif) {
                return Card(
                  color: Colors.white.withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_active,
                      color: Colors.deepPurpleAccent,
                    ),
                    title: Text(
                      notif['message'],
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _formatTimestamp(notif['created_at']),
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          message,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.tryParse(timestamp);
    if (date == null) return "Unknown time";

    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }
}
