import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/banner_ad_widget.dart';

// 🟣 Animation & Effects Packages
import 'package:flutter_animate/flutter_animate.dart'; // Smooth Animations
import 'package:shimmer/shimmer.dart'; // Glowing Effect

class BlockedUsersScreen extends StatefulWidget {
  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final SupabaseService supabaseService = SupabaseService();
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> blockedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => isLoading = true);

    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      print("❌ No logged in user.");
      return;
    }

    final response = await supabaseService.getBlockedUsers(userId);

    setState(() {
      blockedUsers = response;
      isLoading = false;
    });
  }

  Future<void> _unblockUser(String blockedUserId) async {
    final blockerId = supabase.auth.currentUser?.id;

    if (blockerId == null) {
      print("❌ No logged in user.");
      _showMessage("You must be logged in to unblock.");
      return;
    }

    final success = await supabaseService.unblockUser(blockerId, blockedUserId);

    if (success) {
      _showMessage("✅ User unblocked!");
      _loadBlockedUsers(); // Refresh list
    } else {
      _showMessage("❌ Failed to unblock user.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade900,
                Colors.purple.shade600,
                Colors.amber.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🟣 Background Image
          Positioned.fill(
            child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover),
          ),

          Column(
            children: [
              BannerAdWidget(), // ✅ Your ad banner at the top

              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : blockedUsers.isEmpty
                    ? Center(
                  child: Text(
                    '✨ No blocked users.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                    : ListView.builder(
                  itemCount: blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = blockedUsers[index]['profiles'];

                    return Animate(
                      effects: [
                        FadeEffect(duration: 400.ms),
                        SlideEffect(duration: 400.ms),
                      ],
                      child: Card(
                        color: Colors.white.withOpacity(0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor:
                          Colors.amberAccent.withOpacity(0.5),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: user['avatar'] != null
                                  ? NetworkImage(user['avatar'])
                                  : AssetImage(
                                  'assets/images/default_avatar.png')
                              as ImageProvider,
                            ),
                            title: Text(
                              user['name'] ?? 'Unknown',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.block,
                                  color: Colors.red),
                              onPressed: () =>
                                  _unblockUser(user['id']),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
