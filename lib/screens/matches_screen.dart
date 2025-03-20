import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

// If you have ChatScreen, import it here (skip if not ready)
// import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final supabase = Supabase.instance.client;
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));

  List<Map<String, dynamic>> matchedSouls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSoulMatches();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchSoulMatches() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('soul_matches')
          .select('matched_user_id, profiles!matched_user_id(name, avatar, dob, soul_match_message, is_online)')
          .eq('user_id', userId)
          .eq('status', 'matched');

      setState(() {
        matchedSouls = List<Map<String, dynamic>>.from(response);
        isLoading = false;

        if (matchedSouls.isNotEmpty) {
          _confettiController.play();
        }
      });
    } catch (error) {
      print('❌ Error fetching matches: $error');
      setState(() => isLoading = false);
    }
  }

  void _goToChat(String userId, String name) {
    // 🔥 Placeholder - Replace when you have ChatScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🚀 Open chat with $name")),
    );

    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => ChatScreen(receiverId: userId, receiverName: name),
    // ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soul Matches'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.withOpacity(0.8), Colors.black.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(),
          isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : matchedSouls.isEmpty
              ? Center(child: Text('No soul matches yet...', style: TextStyle(color: Colors.white70)))
              : _buildMatchesList(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: [Colors.purple, Colors.pinkAccent, Colors.cyan],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/home.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      itemCount: matchedSouls.length,
      itemBuilder: (context, index) {
        final match = matchedSouls[index]['profiles'];
        final avatarUrl = match['avatar'];
        final name = match['name'] ?? 'Unknown Soul';
        final message = match['soul_match_message'] ?? 'Ready for a connection!';
        final isOnline = match['is_online'] ?? false;

        return Card(
          color: Colors.black.withOpacity(0.5),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(Icons.star, color: Colors.yellowAccent, size: 16),
                  ),
              ],
            ),
            title: Text(
              name,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              message,
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            trailing: IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.greenAccent),
              onPressed: () => _goToChat(matchedSouls[index]['matched_user_id'], name),
            ),
          ),
        );
      },
    );
  }
}
