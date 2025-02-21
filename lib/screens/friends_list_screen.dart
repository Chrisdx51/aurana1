import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsListScreen extends StatefulWidget {
  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // 🔥 Fetch Friends List from Supabase
  Future<void> _loadFriends() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('friends')
          .select('friend_id, profiles(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        friends = response;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading friends: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🔥 Remove Friend
  Future<void> _removeFriend(String friendId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('friends')
        .delete()
        .match({'user_id': userId, 'friend_id': friendId});

    _loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Friends")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : friends.isEmpty
          ? Center(child: Text("No friends yet. Add some!"))
          : ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(friend['profiles']['name'] ?? "Unknown"),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removeFriend(friend['friend_id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
