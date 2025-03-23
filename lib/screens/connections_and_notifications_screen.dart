import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/banner_ad_widget.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class ConnectionsAndNotificationsScreen extends StatefulWidget {
  final String userId;

  const ConnectionsAndNotificationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ConnectionsAndNotificationsScreenState createState() => _ConnectionsAndNotificationsScreenState();
}

class _ConnectionsAndNotificationsScreenState extends State<ConnectionsAndNotificationsScreen> {
  final supabase = Supabase.instance.client;
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 1));

  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> confirmedFriends = [];
  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;
  bool _isAdLoaded = true;

  late RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchAllData(); // Initial data load
    _setupRealtime(); // Realtime listeners
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _realtimeChannel.unsubscribe();
    super.dispose();
  }

  // ✅ Main fetch function (stops infinite loop)
  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        fetchPendingRequests(),
        fetchConfirmedFriends(),
        fetchNotifications(),
      ]);
    } catch (e) {
      print('❌ Error fetching data: $e');
    }

    setState(() => isLoading = false); // ✅ Stop spinner!
  }

  // ✅ Fetch pending requests
  Future<void> fetchPendingRequests() async {
    final response = await supabase
        .from('friend_requests')
        .select('*, sender:profiles(id, name, avatar)')
        .eq('receiver_id', widget.userId)
        .eq('status', 'pending');

    setState(() {
      pendingRequests = List<Map<String, dynamic>>.from(response);
    });
  }

  // ✅ Fetch confirmed friends
  Future<void> fetchConfirmedFriends() async {
    final response = await supabase
        .from('friends')
        .select('*, profile:profiles!friends_friend_id_fkey(id, name, avatar, is_online)')
        .or('user_id.eq.${widget.userId},friend_id.eq.${widget.userId}')
        .eq('status', 'accepted');

    setState(() {
      confirmedFriends = response.map<Map<String, dynamic>>(
            (friend) => Map<String, dynamic>.from(friend['profile']),
      ).toList();
    });
  }

  // ✅ Fetch notifications
  Future<void> fetchNotifications() async {
    final response = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    setState(() {
      notifications = List<Map<String, dynamic>>.from(response);
    });
  }

  // ✅ Realtime updates
  void _setupRealtime() {
    _realtimeChannel = supabase.channel('aurana_notifications_channel');

    _realtimeChannel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'friend_requests',
        callback: (payload) {
          print("🔔 New Friend Request Received!");
          fetchPendingRequests();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: (payload) {
          print("🔔 New Notification Received!");
          fetchNotifications();
        },
      )
      ..subscribe();
  }

  // ✅ Accept friend request
  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    await supabase.from('friend_requests').update({'status': 'accepted'}).eq('id', requestId);

    await supabase.from('friends').insert({
      'user_id': widget.userId,
      'friend_id': senderId,
      'status': 'accepted',
    });

    _confettiController.play();
    _fetchAllData();
  }

  // ✅ Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await supabase.from('friend_requests').delete().eq('id', requestId);
    _fetchAllData();
  }

  // ✅ Remove friend
  Future<void> removeFriend(String friendId) async {
    await supabase.from('friends').delete().or(
        'and(user_id.eq.${widget.userId}, friend_id.eq.$friendId), and(user_id.eq.$friendId, friend_id.eq.${widget.userId})');
    _fetchAllData();
  }

  // ✅ Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await supabase.from('notifications').update({'read': true}).eq('id', notificationId);
    fetchNotifications();
  }

  // ✅ Share invite link
  void _shareInviteLink() {
    Share.share("🌟 Join me on Aurana! 🌌 https://aurana.app/invite");
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: notifications.isNotEmpty
          ? FloatingActionButton(
        onPressed: () {
          notifications.forEach((notif) => markNotificationAsRead(notif['id']));
        },
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.notifications_off),
        tooltip: 'Clear Notifications',
      )
          : null,
      body: Stack(
        children: [
          _backgroundGradient(),
          SafeArea(child: _mainContent()),
          _buildConfetti(),
        ],
      ),
    );
  }

  Widget _backgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade800, Colors.purpleAccent.shade400, Colors.pink.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _mainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
            onRefresh: _fetchAllData,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildPendingRequests(),
                SizedBox(height: 20),
                _buildConfirmedFriends(),
                SizedBox(height: 20),
                _buildNotifications(),
                SizedBox(height: 20),
                _buildInviteButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.yellow,
            highlightColor: Colors.white,
            child: Text('Connections & Notifications',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
        ),
        if (_isAdLoaded) BannerAdWidget(),
      ],
    );
  }

  Widget _buildPendingRequests() {
    if (pendingRequests.isEmpty) {
      return _sectionTitle('No Pending Requests');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pending Friend Requests'),
        ...pendingRequests.map((request) {
          final sender = request['sender'];
          return Card(
            color: Colors.white.withOpacity(0.1),
            elevation: 5,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: sender['avatar'] != null
                    ? NetworkImage(sender['avatar'])
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
              title: Text(sender['name'], style: TextStyle(color: Colors.white)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.check, color: Colors.greenAccent), onPressed: () => acceptFriendRequest(request['id'], sender['id'])),
                  IconButton(icon: Icon(Icons.close, color: Colors.redAccent), onPressed: () => rejectFriendRequest(request['id'])),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfirmedFriends() {
    if (confirmedFriends.isEmpty) return _sectionTitle('No Friends Yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('My Friends'),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: confirmedFriends.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8),
          itemBuilder: (context, index) {
            final friend = confirmedFriends[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: friend['id'])));
              },
              child: Card(
                color: Colors.white.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: friend['avatar'] != null
                          ? NetworkImage(friend['avatar'])
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    SizedBox(height: 8),
                    Text(friend['name'], style: TextStyle(color: Colors.white)),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverId: friend['id'], receiverName: friend['name']))),
                      child: Text("Chat"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    if (notifications.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No Notifications Yet',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Notifications'),
        ...notifications.map((note) {
          final isRead = note['read'] ?? false;

          return Card(
            color: isRead ? Colors.grey.withOpacity(0.4) : Colors.white.withOpacity(0.8),
            child: ListTile(
              title: Text(note['title'] ?? 'No Title'),
              subtitle: Text(note['body'] ?? 'No Body'),
              trailing: isRead
                  ? Icon(Icons.done, color: Colors.green)
                  : Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
              onTap: () => markNotificationAsRead(note['id']),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInviteButton() {
    return ElevatedButton.icon(
      onPressed: _shareInviteLink,
      icon: Icon(Icons.share),
      label: Text('Invite Friends'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purpleAccent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        colors: [Colors.purple, Colors.blue, Colors.pink],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
