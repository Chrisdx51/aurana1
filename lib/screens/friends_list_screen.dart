import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class FriendsListScreen extends StatefulWidget {
  final String userId;
  FriendsListScreen({required this.userId});

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    List<Map<String, dynamic>> friends =
    await _supabaseService.getFriendsList(widget.userId);
    setState(() {
      _friends = friends;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Friends List")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _friends.isEmpty
          ? Center(child: Text("No friends yet."))
          : ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          var friend = _friends[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: friend['profiles']['icon'] != null
                  ? NetworkImage(friend['profiles']['icon'])
                  : AssetImage('assets/images/default_avatar.png')
              as ImageProvider,
            ),
            title: Text(friend['profiles']['name']),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () async {
                bool removed = await _supabaseService.removeFriend(
                    widget.userId, friend['friend_id']);
                if (removed) _loadFriends();
              },
            ),
          );
        },
      ),
    );
  }
}
