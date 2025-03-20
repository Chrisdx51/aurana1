import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'message_screen.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MessageHomeScreen extends StatefulWidget {
  @override
  _MessageHomeScreenState createState() => _MessageHomeScreenState();
}

class _MessageHomeScreenState extends State<MessageHomeScreen> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService supabaseService = SupabaseService();

  List<Map<String, dynamic>> friendsMessages = [];
  List<Map<String, dynamic>> nonFriendMessages = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => isLoading = true);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      print("❌ Not logged in.");
      setState(() => isLoading = false);
      return;
    }

    try {
      final allThreads = await supabaseService.getMessagedUsers(userId);

      final friends = <Map<String, dynamic>>[];
      final nonFriends = <Map<String, dynamic>>[];

      // Optional improvement: run parallel friend checks later
      for (var user in allThreads) {
        final isFriend = await supabaseService.checkIfFriends(userId, user['id']);
        if (isFriend) {
          friends.add(user);
        } else {
          nonFriends.add(user);
        }
      }

      setState(() {
        friendsMessages = friends;
        nonFriendMessages = nonFriends;
        isLoading = false;
      });
    } catch (error) {
      print("❌ Error loading messages: $error");
      setState(() => isLoading = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          receiverId: user['id'],
          receiverName: user['name'] ?? 'Unknown',
        ),
      ),
    );
    _loadMessages(); // Refresh list after coming back from chat
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool isFriend = false}) {
    return Card(
      color: isFriend ? Colors.white.withOpacity(0.9) : Colors.deepPurple.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['avatar'] != null
              ? NetworkImage(user['avatar'])
              : AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          user['name'] ?? 'Unknown',
          style: TextStyle(
            color: isFriend ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isFriend ? 'Soul Connection' : 'New Vibe',
          style: TextStyle(color: isFriend ? Colors.deepPurple : Colors.amberAccent),
        ),
        trailing: Icon(Icons.message, color: isFriend ? Colors.deepPurple : Colors.amberAccent),
        onTap: () => _openChat(user),
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 500))
        .moveY(begin: 20, end: 0)
        .scale(begin: 0.95, end: 1.0, duration: Duration(milliseconds: 400));
  }

  Widget _buildTabContent(List<Map<String, dynamic>> users, {bool isFriend = false}) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 64),
            SizedBox(height: 16),
            Text(
              isFriend
                  ? 'No Soul Connections yet.\nStart messaging your friends!'
                  : 'No New Vibes.\nReach out and connect with new souls!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user, isFriend: isFriend);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aurana Messages'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade900,
                Colors.purple.shade700,
                Colors.amber.shade500
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Soul Connections 🧘'),
            Tab(text: 'New Vibes ✨'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: BannerAdWidget(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(friendsMessages, isFriend: true),
                    _buildTabContent(nonFriendMessages, isFriend: false),
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
