import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<UserModel> _topUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    List<UserModel> users = await _supabaseService.fetchTopUsers();
    setState(() {
      _topUsers = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🏆 XP Leaderboard")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _topUsers.length,
        itemBuilder: (context, index) {
          final user = _topUsers[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.icon != null && user.icon!.isNotEmpty
                  ? NetworkImage(user.icon!)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            title: Text(user.name ?? "Unknown"),
            subtitle: Text("Level ${user.spiritualLevel} • XP: ${user.spiritualXP}"),
            trailing: Text("#${index + 1}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
