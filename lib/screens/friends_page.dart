import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'notification_page.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ConfettiController _confettiController =
  ConfettiController(duration: Duration(seconds: 1));

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> suggestedFriends = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchFriends();
    fetchSuggestedFriends();
    setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    supabase.removeAllChannels();
    super.dispose();
  }

  Future<void> fetchFriends() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('relations')
          .select(
          'friend_id, friend:profiles!fk_friend(id, name, icon, is_online, last_seen)')
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
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profiles = await supabase
          .from('profiles')
          .select('id, name, icon')
          .neq('id', user.id);

      final relations = await supabase
          .from('relations')
          .select('user_id, friend_id')
          .or('user_id.eq.${user.id}, friend_id.eq.${user.id}');

      final friendIds = relations.expand((rel) {
        return [rel['user_id'], rel['friend_id']];
      }).toSet();

      final suggestions = profiles
          .where((profile) => !friendIds.contains(profile['id']))
          .toList();

      setState(() => suggestedFriends = suggestions);
    } catch (error) {
      print("❌ Error fetching suggested friends: $error");
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existingRequest = await supabase
          .from('relations')
          .select()
          .or('and(user_id.eq.${user.id}, friend_id.eq.$receiverId), and(user_id.eq.$receiverId, friend_id.eq.${user.id})')
          .maybeSingle();

      if (existingRequest != null) {
        print("⚠️ Friend request already exists.");
        return;
      }

      await supabase.from('relations').insert({
        'user_id': user.id,
        'friend_id': receiverId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      _confettiController.play();
      fetchSuggestedFriends();
    } catch (error) {
      print("❌ Error sending friend request: $error");
    }
  }

  Future<void> removeFriend(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('relations').delete().or(
          'and(user_id.eq.${user.id}, friend_id.eq.$friendId), and(user_id.eq.$friendId, friend_id.eq.${user.id})');
      fetchFriends();
    } catch (error) {
      print("❌ Error removing friend: $error");
    }
  }

  Future<void> blockUser(String blockId) async {
    print('🚫 User $blockId blocked.');
    fetchFriends();
  }

  void setupRealtimeUpdates() {
    final channel = supabase.channel('public:profiles');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: (payload) {
        final updatedProfile = payload.newRecord;
        final updatedId = updatedProfile['id'];

        final index = friends.indexWhere((friend) => friend['id'] == updatedId);

        if (index != -1) {
          setState(() {
            friends[index]['is_online'] = updatedProfile['is_online'];
            friends[index]['last_seen'] = updatedProfile['last_seen'];
          });
        }
      },
    );

    channel.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Friends',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          IconButton(
                            icon: Icon(Icons.notifications, color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage()));
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
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
                      _buildSectionTitle('My Friends'),
                      SizedBox(height: 10),
                      friends.isEmpty
                          ? _buildEmptyState('No friends found.')
                          : _buildFriendsGrid(friends),
                      SizedBox(height: 30),
                      _buildSectionTitle('Suggested Friends'),
                      SizedBox(height: 10),
                      suggestedFriends.isEmpty
                          ? _buildEmptyState('No suggestions available.')
                          : _buildSuggestedFriendsHorizontal(suggestedFriends),
                      SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Share.share("Join me on Aurana! Discover your soul tribe 🌌 https://aurana.app/invite");
                            _confettiController.play();
                          },
                          icon: Icon(Icons.share),
                          label: Text('Invite Friends'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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


  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message, style: TextStyle(color: Colors.white70)));
  }

  Widget _buildFriendsGrid(List<Map<String, dynamic>> friendList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8, // New ratio to shrink the cards
      ),
      itemCount: friendList.length,
      itemBuilder: (context, index) {
        final friend = friendList[index];

        if (searchQuery.isNotEmpty && !friend['name'].toString().toLowerCase().contains(searchQuery)) {
          return Container();
        }

        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    bool isOnline = friend['is_online'] == true;

    return Container(
      decoration: BoxDecoration(
        gradient: isOnline
            ? LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC), Color(0xFFFF416C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(colors: [Color(0xFFB0E0E6).withOpacity(0.8), Colors.white.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: friend['id'])));
            },
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: friend['icon'] != null ? NetworkImage(friend['icon']) : AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    Icon(isOnline ? Icons.star : Icons.star_border, color: isOnline ? Colors.yellow : Colors.grey, size: 16),
                  ],
                ),
                SizedBox(height: 8),
                Text(friend['name'], style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 8, color: isOnline ? Colors.greenAccent : Colors.grey),
                    SizedBox(width: 4),
                    Text(isOnline ? "Online" : _formatLastSeen(friend['last_seen']), style: TextStyle(color: Colors.black54, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(receiverId: friend['id'], receiverName: friend['name'])));
                },
                icon: Icon(Icons.message, size: 14),
                label: Text('Chat', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') removeFriend(friend['id']);
                  if (value == 'block') blockUser(friend['id']);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'remove', child: Text('Remove Friend')),
                  PopupMenuItem(value: 'block', child: Text('Block/Report')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSuggestedFriendsHorizontal(List<Map<String, dynamic>> suggestedList) {
    return Container(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestedList.length,
        itemBuilder: (context, index) {
          final user = suggestedList[index];
          return Container(
            width: 120,
            margin: EdgeInsets.only(right: 12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id'])));
                  },
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage: user['icon'] != null ? NetworkImage(user['icon']) : AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                ),
                SizedBox(height: 8),
                Text(user['name'], style: TextStyle(fontWeight: FontWeight.w600)),
                IconButton(icon: Icon(Icons.person_add_alt_1, color: Colors.green), onPressed: () => sendFriendRequest(user['id'])),
              ],
            ),
          );
        },
      ),
    );
  }


  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return "Offline";
    final lastSeenTime = DateTime.tryParse(lastSeen);
    if (lastSeenTime == null) return "Unknown";
    final difference = DateTime.now().difference(lastSeenTime);
    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes} min ago";
    if (difference.inHours < 24) return "${difference.inHours} hrs ago";
    return "${difference.inDays} days ago";
  }
}
