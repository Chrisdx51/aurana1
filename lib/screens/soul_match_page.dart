import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoulMatchPage extends StatefulWidget {
  @override
  _SoulMatchPageState createState() => _SoulMatchPageState();
}

class _SoulMatchPageState extends State<SoulMatchPage> {
  final SwipableStackController _controller = SwipableStackController();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> potentialMatches = [];
  bool isLoading = true;
  String selectedGender = 'All';

  @override
  void initState() {
    super.initState();
    fetchPotentialMatches();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> fetchPotentialMatches() async {
    print('🔮 Fetching potential matches from Supabase...');

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    if (userId.isEmpty) {
      print('❌ No valid userId found. Are you logged in?');
      setState(() => isLoading = false);
      return;
    }

    print('🟢 Current User ID: $userId');


    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .neq('id', userId) // exclude current user
          .limit(20);

      setState(() {
        potentialMatches = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      print('✅ Fetched ${potentialMatches.length} matches!');
    } catch (e) {
      print('❌ Error fetching matches: $e');
      setState(() => isLoading = false);
    }
  }


  void swipeYes(Map<String, dynamic> user) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final matchedUserId = user['id'];

    print('💖 You liked ${user['name']}');

    try {
      // 1. Insert your like into soul_matches
      await Supabase.instance.client.from('soul_matches').insert({
        'user_id': userId,
        'matched_user_id': matchedUserId,
        'status': 'liked',
      });

      // 2. Check if they liked you first (mutual match)
      final mutual = await Supabase.instance.client
          .from('soul_matches')
          .select()
          .eq('user_id', matchedUserId)
          .eq('matched_user_id', userId)
          .eq('status', 'liked')
          .maybeSingle();

      if (mutual != null) {
        print('💥 Mutual match with ${user['name']}!');

        try {
          await _audioPlayer.play(AssetSource('sounds/match.mp3'));
        } catch (e) {
          print('⚠️ Sound error: $e');
        }

        _confettiController.play();
        _showMatchDialog(user);
      } else {
        print('💫 Awaiting mutual match...');
        _showLikedOnlyDialog(user);
      }
    } catch (e) {
      print('❌ Error on swipeYes: $e');
    }
  }


  void swipeNo(Map<String, dynamic> user) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final matchedUserId = user['id'];

    print('❌ You passed on ${user['name']}');

    try {
      // 1. Insert your dislike into soul_matches
      await Supabase.instance.client.from('soul_matches').insert({
        'user_id': userId,
        'matched_user_id': matchedUserId,
        'status': 'disliked',
      });

      // 2. Check if they liked you first
      final theyLikedYou = await Supabase.instance.client
          .from('soul_matches')
          .select()
          .eq('user_id', matchedUserId)
          .eq('matched_user_id', userId)
          .eq('status', 'liked')
          .maybeSingle();

      if (theyLikedYou != null) {
        print('⚠️ You missed a soul who liked you first!');
        _showMissedSoulDialog(user);
      } else {
        print('🚫 Moved on. No mutual connection.');
        _showNoMatchDialog(user);
      }
    } catch (e) {
      print('❌ Error on swipeNo: $e');
    }
  }


  void _showMatchDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('✨ Soul Match!', style: TextStyle(color: Colors.white, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, backgroundImage: NetworkImage(user['icon'])),
            SizedBox(height: 10),
            Text('You and ${user['name']} are connected!', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Later', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement ChatScreen navigation if needed!
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: Text('Message Now'),
          ),
        ],
      ),
    );
  }
  void _showLikedOnlyDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Awaiting Connection...', style: TextStyle(color: Colors.white)),
        content: Text(
          'You liked ${user['name']}. Let’s see if they like you back!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showNoMatchDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Moved On', style: TextStyle(color: Colors.white)),
        content: Text(
          'You passed on ${user['name']}. Onward on your journey.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMissedSoulDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Missed Soul Journey', style: TextStyle(color: Colors.white)),
        content: Text('You missed a connection with ${user['name']}. Trust the journey.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text('Soul Match'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 🏠 Returns to previous screen
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image

          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 50),
                Text('Soul Match', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),

                // Gender Filter Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      dropdownColor: Colors.black87,
                      value: selectedGender,
                      items: ['All', 'Male', 'Female'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender, style: TextStyle(color: Colors.white)))).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value!;
                          fetchPotentialMatches();
                        });
                      },
                    ),
                  ],
                ),

                // Swipable cards or loading spinner
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : potentialMatches.isEmpty
                      ? Center(child: Text('No souls to match today...', style: TextStyle(color: Colors.white70)))
                      : _buildSwipableCards(),
                ),

                _buildActionButtons(),
                SizedBox(height: 20),
              ],
            ),
          ),

          // Confetti
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

  Widget _buildSwipableCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SwipableStack(
        controller: _controller,
        itemCount: potentialMatches.length,
        onSwipeCompleted: (index, direction) {
          if (index < 0 || index >= potentialMatches.length) return;
          final user = potentialMatches[index];
          if (direction == SwipeDirection.right) {
            swipeYes(user);
          } else if (direction == SwipeDirection.left) {
            swipeNo(user);
          }
        },
        builder: (context, swipeProps) {
          if (swipeProps.index < 0 || swipeProps.index >= potentialMatches.length) {
            return SizedBox();
          }
          final user = potentialMatches[swipeProps.index];
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: _buildProfileCard(user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user) {
    String imageUrl = user['icon'] ?? 'https://i.pravatar.cc/300';
    String userName = user['name'] ?? 'Unknown Soul';
    String soulMessage = user['soul_match_message'] ?? 'Seeking a cosmic connection...';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.7), blurRadius: 20, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            FadeInImage.assetNetwork(
              placeholder: 'assets/default_avatar.png', // Fallback image
              image: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              imageErrorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(soulMessage, style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spiritual Reject Button
          GestureDetector(
            onTap: () => _controller.next(swipeDirection: SwipeDirection.left),
            child: _actionButton(
              icon: Icons.self_improvement, // meditating icon for reject
              iconColor: Colors.redAccent,
            ),
          ),
          // Spiritual Accept Button
          GestureDetector(
            onTap: () => _controller.next(swipeDirection: SwipeDirection.right),
            child: _actionButton(
              icon: Icons.auto_awesome, // sparkle icon for accept
              iconColor: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color iconColor}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 2))],
      ),
      child: Icon(icon, color: iconColor, size: 36),
    );
  }
}
