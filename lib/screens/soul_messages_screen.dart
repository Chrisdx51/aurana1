import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'message_screen.dart';
import '../widgets/banner_ad_widget.dart';

class SoulMessagesScreen extends StatefulWidget {
  @override
  _SoulMessagesScreenState createState() => _SoulMessagesScreenState();
}

class _SoulMessagesScreenState extends State<SoulMessagesScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService supabaseService = SupabaseService();
  TabController? _tabController;

  List<Map<String, dynamic>> friendMessages = [];
  List<Map<String, dynamic>> nonFriendMessages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => isLoading = true);

    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      print("❌ No user logged in!");
      setState(() => isLoading = false);
      return;
    }

    try {
      friendMessages = await supabaseService.getMessagedUsers(currentUserId, friendsOnly: true);
      nonFriendMessages = await supabaseService.getMessagedUsers(currentUserId, friendsOnly: false);
    } catch (e) {
      print("❌ Error loading messages: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Soul Messages"),
        centerTitle: true,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: "🌿 Soul Circle"),
            Tab(text: "🌙 Cosmic Echoes"),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg8.png', fit: BoxFit.cover),
          ),
          Column(
            children: [
              BannerAdWidget(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMessageList(friendMessages, true),
                    _buildMessageList(nonFriendMessages, false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> users, bool isFriendTab) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_chat_unread, color: Colors.white70, size: 60),
            SizedBox(height: 12),
            Text(
              isFriendTab
                  ? "No Soul Connections yet.\nReach out to your friends!"
                  : "No Cosmic Echoes yet.\nSend a message and make a new connection!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final unreadCount = user['unread_count'] ?? 0;

        return Card(
          color: isFriendTab ? Colors.white.withOpacity(0.9) : Colors.deepPurple.withOpacity(0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            title: Text(
              user['name'] ?? "Unknown",
              style: TextStyle(
                color: isFriendTab ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: unreadCount > 0
                ? Text("$unreadCount unread", style: TextStyle(color: Colors.yellowAccent))
                : Text(isFriendTab ? 'Soul Connection' : 'Cosmic Echo', style: TextStyle(color: Colors.white70)),
            trailing: Icon(Icons.arrow_forward_ios, color: isFriendTab ? Colors.black54 : Colors.amberAccent),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageScreen(
                    receiverId: user['id'],
                    receiverName: user['name'],
                  ),
                ),
              ).then((_) => _loadMessages());
            },
          ),
        );
      },
    );
  }
}
