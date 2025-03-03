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
  List<Map<String, dynamic>> receivedFriendRequests = [];
  List<Map<String, dynamic>> blockedUsers = []; // ✅ Blocked users list
  bool isLoading = true;
  String searchQuery = "";
  int _pendingFriendRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchFriends();
    fetchBlockedUsers();
    refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final countResponse = await supabase
          .from('friend_requests')
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      setState(() {
        _pendingFriendRequestsCount = countResponse.length;
      });
    } catch (error) {
      print("❌ Error refreshing notifications: $error");
    }
  }

  // ✅ Fetch Friends & Friend Requests
  Future<void> fetchFriends() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final friendsResponse = await supabase
          .from('relations')
          .select('friend_id, friend:profiles!fk_friend(id, name, icon)')
          .or('user_id.eq.${user.id}, friend_id.eq.${user.id}')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> formattedFriends = friendsResponse
          .map((relation) => relation['friend'] as Map<String, dynamic>)
          .where((friend) => friend['id'] != user.id)
          .toList();

      final requestsResponse = await supabase
          .from('friend_requests')
          .select('sender_id, sender:profiles!fk_sender(id, name, icon)')
          .eq('receiver_id', user.id)
          .eq('status', 'pending');

      List<Map<String, dynamic>> formattedRequests = requestsResponse
          .map((request) => request['sender'] as Map<String, dynamic>)
          .toList();

      setState(() {
        friends = formattedFriends;
        receivedFriendRequests = formattedRequests;
        isLoading = false;
      });
    } catch (error) {
      print("❌ Error fetching friends: $error");
      setState(() {
        isLoading = false;
      });
    }
  }


  // ✅ Fetch Blocked Users
  Future<void> fetchBlockedUsers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final blockedResponse = await supabase
          .from('blocked_users')
          .select('blocked_id, blocked:profiles!blocked_id(id, name, icon)')
          .eq('blocker_id', user.id);

      setState(() {
        blockedUsers = blockedResponse
            .map((entry) => entry['blocked'] as Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
      });

      print("✅ Blocked users loaded: ${blockedUsers.length}");
    } catch (error) {
      print("❌ Error fetching blocked users: $error");
    }
  }

  // ✅ Block a User
  Future<void> blockUser(String blockedId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('blocked_users').insert({
        'blocker_id': user.id,
        'blocked_id': blockedId,
      });

      await supabase.from('relations').delete().or(
          'and(user_id.eq.${user.id},friend_id.eq.$blockedId),and(user_id.eq.$blockedId,friend_id.eq.${user.id})');

      print("✅ User blocked successfully!");

      await fetchFriends();
      await fetchBlockedUsers();
    } catch (error) {
      print("❌ Error blocking user: $error");
    }
  }

  // ✅ Unblock a User
  Future<void> unblockUser(String blockedId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', user.id)
          .eq('blocked_id', blockedId);

      print("✅ User unblocked successfully!");

      await fetchBlockedUsers();
      await fetchFriends();
    } catch (error) {
      print("❌ Error unblocking user: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg2.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              AppBar(
                title: Text('My Friends'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Friends',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query.toLowerCase();
                    });
                  },
                ),
              ),

              Expanded(
                child: ListView(
                  children: [
                    // ✅ Blocked Users Section
                    if (blockedUsers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "Blocked Users",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                      ...blockedUsers.map(
                            (blockedUser) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: blockedUser['icon'] != null
                                ? NetworkImage(blockedUser['icon'])
                                : AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                          title: Text(blockedUser['name']),
                          trailing: IconButton(
                            icon: Icon(Icons.lock_open, color: Colors.orange, size: 28),
                            onPressed: () async {
                              await unblockUser(blockedUser['id']);
                            },
                          ),
                        ),
                      ),
                    ],

                    // ✅ Friends List
                    ...friends.map(
                          (friend) => Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: friend['icon'] != null
                                ? NetworkImage(friend['icon'])
                                : AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                          title: Text(friend['name']),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: Icon(Icons.person, color: Colors.teal, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(userId: friend['id']),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.message, color: Colors.blue, size: 28),
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
                              ),
                              IconButton(
                                icon: Icon(Icons.block, color: Colors.red, size: 28),
                                onPressed: () async {
                                  await blockUser(friend['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}