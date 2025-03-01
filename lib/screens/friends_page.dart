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
  List<String> sentFriendRequests = [];
  List<String> receivedFriendRequests = [];
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

    try {
      final friendsResponse = await supabase
          .from('relations')
          .select('friend_id, profiles!fk_friend(id, name, icon)')
          .or('user_id.eq.${user.id}, friend_id.eq.${user.id}')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      List<dynamic> formattedFriends = friendsResponse
          .map((relation) => relation['profiles'])
          .where((friend) => friend['id'] != user.id)
          .toList();

      if (mounted) {
        setState(() {
          friends = formattedFriends;
        });
      }

      print("✅ Friends list updated");
    } catch (error) {
      print("❌ Error fetching friends: $error");
    }
  }

  Future<void> sendFriendRequest(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('friend_requests').insert({
        'sender_id': user.id,
        'receiver_id': friendId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        sentFriendRequests.add(friendId);
      });

      await fetchFriends(); // ✅ Ensure UI refreshes after sending request

    } catch (error) {
      print("❌ Error sending friend request: $error");
    }
  }

  Future<void> cancelFriendRequest(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('friend_requests')
          .delete()
          .eq('sender_id', user.id)
          .eq('receiver_id', friendId);

      // ✅ Refresh pending requests list
      await fetchFriends();

      print("✅ Friend request canceled");
    } catch (error) {
      print("❌ Error canceling friend request: $error");
    }
  }



  Future<void> removeFriend(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('relations')
          .delete()
          .or('and(user_id.eq.${user.id},friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.${user.id}))');

      // ✅ Refresh the friend list immediately
      await fetchFriends();

      print("✅ Friend removed successfully");
    } catch (error) {
      print("❌ Error removing friend: $error");
    }
  }



  Future<void> acceptFriendRequest(String requesterId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('friend_requests')
          .delete()
          .eq('sender_id', requesterId)
          .eq('receiver_id', user.id);

      await supabase.from('relations').insert([
        {'user_id': user.id, 'friend_id': requesterId, 'created_at': DateTime.now().toIso8601String()},
        {'user_id': requesterId, 'friend_id': user.id, 'created_at': DateTime.now().toIso8601String()},
      ]);

      setState(() {
        receivedFriendRequests.remove(requesterId);
      });

      await fetchFriends(); // ✅ Ensure UI refreshes after accepting friend request

    } catch (error) {
      print("❌ Error accepting friend request: $error");
    }
  }

  Future<String> checkFriendshipStatus(String friendId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'not_friends';

    if (friends.any((friend) => friend['id'] == friendId)) {
      return 'friends';
    }
    if (sentFriendRequests.contains(friendId)) {
      return 'sent';
    }
    if (receivedFriendRequests.contains(friendId)) {
      return 'received';
    }

    return 'not_friends';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Friends')),
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
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];

                if (searchQuery.isNotEmpty && !friend['name'].toLowerCase().contains(searchQuery)) {
                  return SizedBox.shrink();
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend['icon'] != null
                        ? NetworkImage(friend['icon'])
                        : AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  title: Text(friend['name']),
                  trailing: FutureBuilder(
                    future: checkFriendshipStatus(friend['id']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();

                      final status = snapshot.data as String;

                      if (status == "friends") {
                        return IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () async {
                            await removeFriend(friend['id']);
                            setState(() {});
                          },
                        );
                      } else if (status == "sent") {
                        return ElevatedButton(
                          onPressed: () async {
                            await cancelFriendRequest(friend['id']);
                            setState(() {});
                          },
                          child: Text("Cancel Request ❌"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        );
                      } else if (status == "received") {
                        return ElevatedButton(
                          onPressed: () async {
                            await acceptFriendRequest(friend['id']);
                            setState(() {});
                          },
                          child: Text("Accept Friend ✅"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: () async {
                            await sendFriendRequest(friend['id']);
                            setState(() {});
                          },
                          child: Text("Add Friend ➕"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        );
                      }
                    },
                  ),
                  onTap: () {
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
