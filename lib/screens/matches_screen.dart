import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

// ✅ Your screens
import 'profile_screen.dart';       // Already have this!
import 'message_screen.dart';       // Your existing MessageScreen

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

  // ✅ Fetch soul matches from Supabase
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

  // ✅ Navigate to ChatScreen (message screen)
  void _goToChat(String userId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          receiverId: userId,
          receiverName: name,
        ),
      ),
    );
  }

  // ✅ Navigate to ProfileScreen
  void _goToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soul Matches'),
        centerTitle: true,
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

  // ✅ Build the background image
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/home.png'), // ✅ Make sure this exists
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ✅ Build the matches list
  Widget _buildMatchesList() {
    return ListView.builder(
      itemCount: matchedSouls.length,
      itemBuilder: (context, index) {
        final matchData = matchedSouls[index];
        final match = matchData['profiles'];
        final avatarUrl = match['avatar'];
        final name = match['name'] ?? 'Unknown Soul';
        final message = match['soul_match_message'] ?? 'Ready for a connection!';
        final isOnline = match['is_online'] ?? false;
        final matchId = matchData['matched_user_id'];

        return GestureDetector(
          onTap: () => _goToProfile(matchId), // ✅ Tap the whole card to go to profile
          child: Card(
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
                onPressed: () {
                  // ✅ Stops the profile tap and opens chat directly
                  _goToChat(matchId, name);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
