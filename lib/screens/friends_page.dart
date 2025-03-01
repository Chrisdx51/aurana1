import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart'; // ✅ Import ProfileScreen

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> friends = [];
  List<dynamic> pendingRequests = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    print("🔍 Fetching friends for user: ${user.id}");

    try {
      // ✅ Fetch Friends with Correct Relationship
      final friendsResponse = await supabase
          .from('relations')
          .select('friend_id, profiles!fk_friend_profile(id, name, icon)')
          .or('user_id.eq.${user.id}, friend_id.eq.${user.id}')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      print("✅ Friends response from Supabase: $friendsResponse");

      // ✅ Ensure correct friend profile is selected and exclude current user
      List<dynamic> formattedFriends = friendsResponse.map((relation) {
        var friend = relation['profiles'];
        return (friend['id'] != user.id) ? friend : null;
      }).where((friend) => friend != null).toList();

      // ✅ Fetch Pending Friend Requests
      final requestsResponse = await supabase
          .from('relations')
          .select('user_id, profiles!fk_friend_profile(id, name, icon)')
          .eq('friend_id', user.id)
          .eq('status', 'pending');

      print("✅ Pending requests response from Supabase: $requestsResponse");

      if (mounted) {
        setState(() {
          friends = formattedFriends ?? [];
          pendingRequests = requestsResponse ?? [];
          isLoading = false;
        });
      }

      if (friends.isEmpty) {
        print("⚠ No friends found in app!");
      }
    } catch (error) {
      print("❌ Error fetching friends: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchFriends(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  void removeFriend(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('relations')
        .delete()
        .or('and(user_id.eq.${user.id},friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.${user.id}))');

    setState(() {
      friends.removeWhere((friend) => friend['id'] == friendId);
    });
  }

  void acceptFriendRequest(String requesterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('relations')
        .update({'status': 'accepted'})
        .match({'user_id': requesterId, 'friend_id': user.id});

    setState(() {
      pendingRequests.removeWhere((request) => request['user_id'] == requesterId);
      fetchFriends(); // Refresh friends list
    });
  }

  void declineFriendRequest(String requesterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('relations')
        .delete()
        .match({'user_id': requesterId, 'friend_id': user.id});

    setState(() {
      pendingRequests.removeWhere((request) => request['user_id'] == requesterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Friends'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Friends',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: searchFriends,
            ),
          ),
          if (pendingRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Friend Requests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index]['profiles'];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: request['icon'] != null
                              ? NetworkImage(request['icon'])
                              : AssetImage('assets/default_avatar.png')
                          as ImageProvider,
                        ),
                        title: Text(request['name']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => acceptFriendRequest(request['id']),
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => declineFriendRequest(request['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];

                if (searchQuery.isNotEmpty &&
                    !friend['name'].toLowerCase().contains(searchQuery)) {
                  return SizedBox.shrink();
                }
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend['icon'] != null
                        ? NetworkImage(friend['icon'])
                        : AssetImage('assets/default_avatar.png')
                    as ImageProvider,
                  ),
                  title: Text(friend['name']),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => removeFriend(friend['id']),
                  ),
                  onTap: () {
                    print("📌 Navigating to friend's profile: ${friend['id']}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: friend['id']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
