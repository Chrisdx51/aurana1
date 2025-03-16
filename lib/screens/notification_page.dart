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

  late RealtimeChannel _notificationsChannel;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
    fetchAppNotifications();
    setupRealtimeNotifications();
  }

  @override
  void dispose() {
    _notificationsChannel.unsubscribe();
    super.dispose();
  }

  // ✅ Fetch Friend Requests
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

  // ✅ Fetch App Notifications
  Future<void> fetchAppNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('notifications')
          .select('id, type, message, created_at, has_read')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        appNotifications = response;
      });
    } catch (error) {
      print('❌ Error fetching app notifications: $error');
    }
  }

  // ✅ Accept Friend Request
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

  // ✅ Decline Friend Request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await supabase.from('friend_requests').delete().eq('id', requestId);
      fetchFriendRequests();
      print("✅ Friend request declined.");
    } catch (error) {
      print('❌ Error declining friend request: $error');
    }
  }

  // ✅ Mark Notification As Read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'has_read': true})
          .eq('id', notificationId);

      fetchAppNotifications();
      print("✅ Notification marked as read");
    } catch (error) {
      print('❌ Error marking notification as read: $error');
    }
  }

  // ✅ Realtime Notifications Listener
  void setupRealtimeNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationsChannel = supabase.channel('notifications_channel');

    _notificationsChannel
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final newNotification = payload.newRecord;

        if (newNotification['user_id'] == userId) {
          print('🔔 New notification received: $newNotification');

          setState(() {
            appNotifications.insert(0, newNotification);
            notificationCount += 1; // ✅ Increase counter
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${newNotification['title'] ?? 'New Notification'}: ${newNotification['body'] ?? ''}'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.deepPurpleAccent,
            ),
          );
        }
      },
    ).subscribe((status, [error]) {
      print('✅ Realtime subscription status: $status');
      if (error != null) {
        print('❌ Realtime subscription error: $error');
      }
    });
  }

  // ✅ Notification Icon Selector
  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icon(Icons.person_add, color: Colors.blueAccent);
      case 'friend_accept':
        return Icon(Icons.person, color: Colors.green);
      case 'message':
        return Icon(Icons.message, color: Colors.orange);
      case 'like':
        return Icon(Icons.thumb_up, color: Colors.pink);
      case 'comment':
        return Icon(Icons.comment, color: Colors.purple);
      default:
        return Icon(Icons.notifications_active, color: Colors.deepPurpleAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A11CB).withOpacity(0.9),
                Color(0xFF2575FC).withOpacity(0.8),
                Color(0xFF5F72BE).withOpacity(0.8),
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
                          : AssetImage('assets/default_avatar.png')
                      as ImageProvider,
                    ),
                    title: Text(sender['name'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Wants to connect with you!'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () => acceptFriendRequest(
                              request['id'], sender['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => declineFriendRequest(
                              request['id']),
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
                bool isRead = notif['has_read'] ?? false;

                return GestureDetector(
                  onTap: () {
                    markNotificationAsRead(notif['id']);
                  },
                  child: Card(
                    color: isRead
                        ? Colors.grey.withOpacity(0.5)
                        : Colors.white.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: _getNotificationIcon(notif['type']),
                      title: Text(
                        notif['message'],
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isRead
                                ? Colors.grey[600]
                                : Colors.black),
                      ),
                      subtitle: Text(
                        _formatTimestamp(notif['created_at']),
                        style: TextStyle(
                            color: Colors.black54, fontSize: 12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            backgroundColor: Colors.deepPurpleAccent,
            onPressed: () {
              setState(() {
                notificationCount = 0;
              });
              // Optional: navigate to notifications or refresh
            },
            child: Icon(Icons.notifications_active, color: Colors.white),
          ),
          if (notificationCount > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$notificationCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
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
