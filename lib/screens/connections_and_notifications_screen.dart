import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
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
  final SupabaseClient supabase = Supabase.instance.client;
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 1));

  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> confirmedFriends = [];
  List<Map<String, dynamic>> notifications = [];

  bool _isAdLoaded = true;

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
    fetchConfirmedFriends();
    fetchNotifications();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    supabase.removeAllChannels();
    super.dispose();
  }

  Future<void> fetchPendingRequests() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('friend_requests')
        .select('*, sender:profiles(id, name, avatar)')
        .eq('receiver_id', userId)
        .eq('status', 'pending');

    setState(() => pendingRequests = List<Map<String, dynamic>>.from(response));
  }

  Future<void> fetchConfirmedFriends() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('friends')
        .select('*, profile:profiles!friends_friend_id_fkey(id, name, avatar, is_online)')
        .or('user_id.eq.$userId,friend_id.eq.$userId')
        .eq('status', 'accepted');

    final formattedFriends = response.map((friend) {
      return friend['profile'] ?? {};
    }).toList();

    setState(() => confirmedFriends = List<Map<String, dynamic>>.from(formattedFriends));
  }

  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    setState(() => notifications = List<Map<String, dynamic>>.from(response));
  }

  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    await supabase
        .from('friend_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);

    await supabase.from('friends').insert({
      'user_id': supabase.auth.currentUser!.id,
      'friend_id': senderId,
      'status': 'accepted',
    });

    fetchPendingRequests();
    fetchConfirmedFriends();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await supabase.from('friend_requests').delete().eq('id', requestId);
    fetchPendingRequests();
  }

  Future<void> removeFriend(String friendId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('friends')
        .delete()
        .or('and(user_id.eq.$userId, friend_id.eq.$friendId), and(user_id.eq.$friendId, user_id.eq.$userId)');

    fetchConfirmedFriends();
  }

  void _shareInviteLink() {
    final inviteLink = "https://aurana.app/invite";
    Share.share("🌟 Join me on Aurana! 🌌 Click to download: $inviteLink");
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/guide.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Connections & Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (_isAdLoaded) BannerAdWidget(), // ✅ Ad banner under title
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      fetchPendingRequests();
                      fetchConfirmedFriends();
                      fetchNotifications();
                    },
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPendingRequests(),
                            SizedBox(height: 20),
                            _buildConfirmedFriends(),
                            SizedBox(height: 20),
                            _buildNotifications(),
                            SizedBox(height: 20),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _shareInviteLink,
                                icon: Icon(Icons.share),
                                label: Text('Invite Friends'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Colors.purple, Colors.blue, Colors.pink],
            ),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.7),
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
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => acceptFriendRequest(request['id'], sender['id']),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => rejectFriendRequest(request['id']),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildConfirmedFriends() {
    if (confirmedFriends.isEmpty) {
      return _sectionTitle('No Friends Found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('My Friends'),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: confirmedFriends.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final friend = confirmedFriends[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: friend['id'])));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: friend['avatar'] != null
                          ? NetworkImage(friend['avatar'])
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    Text(friend['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverId: friend['id'], receiverName: friend['name'])));
                      },
                      child: Text('Chat'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                    ),
                    TextButton(
                      onPressed: () => removeFriend(friend['id']),
                      child: Text('Remove'),
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
      return _sectionTitle('No Notifications Yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Notifications'),
        ...notifications.map((note) {
          return Card(
            color: Colors.white.withOpacity(0.8),
            child: ListTile(
              title: Text(note['title'] ?? 'No Title'),
              subtitle: Text(note['body'] ?? 'No Body'),
              trailing: note['is_read'] == true ? null : Icon(Icons.circle, color: Colors.blue, size: 12),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
