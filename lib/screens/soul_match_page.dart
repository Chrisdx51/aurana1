import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'chat_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:audioplayers/audioplayers.dart';

class SoulMatchPage extends StatefulWidget {
  @override
  _SoulMatchPageState createState() => _SoulMatchPageState();
}

class _SoulMatchPageState extends State<SoulMatchPage> {
  final SupabaseClient supabase = Supabase.instance.client;
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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final query = supabase
          .from('profiles')
          .select('id, name, icon, bio')
          .neq('id', userId);

      // 🟢 First get the data
      final response = await query.limit(20);

      // 🟢 Now check if empty
      if (response.isEmpty) {
        // Add some **dummy users** for testing
        potentialMatches = [
          {
            'id': 'dummy1',
            'name': 'Luna Star',
            'icon': 'https://i.pravatar.cc/150?img=1',
            'bio': 'Dreamwalker & healer 🌙',
          },
          {
            'id': 'dummy2',
            'name': 'Zen Blaze',
            'icon': 'https://i.pravatar.cc/150?img=2',
            'bio': 'Seeker of the soul fire 🔥',
          },
          {
            'id': 'dummy3',
            'name': 'Nova Sky',
            'icon': 'https://i.pravatar.cc/150?img=3',
            'bio': 'Guide to cosmic journeys 🚀',
          },
        ];
      } else {
        // 🟢 Otherwise use real matches
        potentialMatches = response;
      }
    } catch (e) {
      print('❌ Error fetching matches: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> swipeYes(Map<String, dynamic> user) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('soul_matches').insert({
        'user_id': userId,
        'matched_user_id': user['id'],
        'status': 'liked',
      });

      final checkMutual = await supabase
          .from('soul_matches')
          .select()
          .eq('user_id', user['id'])
          .eq('matched_user_id', userId)
          .eq('status', 'liked')
          .maybeSingle();

      if (checkMutual != null) {
        _audioPlayer.play(AssetSource('sounds/match.mp3'));
        _confettiController.play();
        _showMatchDialog(user);
      } else {
        print('💫 Awaiting mutual match...');
      }
    } catch (e) {
      print('❌ Error on swipeYes: $e');
    }
  }

  Future<void> swipeNo(Map<String, dynamic> user) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('soul_matches').insert({
        'user_id': userId,
        'matched_user_id': user['id'],
        'status': 'disliked',
      });

      final theyLikedYou = await supabase
          .from('soul_matches')
          .select()
          .eq('user_id', user['id'])
          .eq('matched_user_id', userId)
          .eq('status', 'liked')
          .maybeSingle();

      if (theyLikedYou != null) {
        print('⚠️ They liked you… missed soul journey.');
        _showMissedSoulDialog(user);
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
            CircleAvatar(
              radius: 40,
              backgroundImage: user['icon'] != null
                  ? NetworkImage(user['icon'])
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            SizedBox(height: 10),
            Text('You and ${user['name']} are connected!', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(
                  receiverId: user['id'],
                  receiverName: user['name'],
                ),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: Text('Message Now'),
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
        content: Text(
          'You missed a connection with ${user['name']}. Trust the journey.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg2.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 50),
                Text('Soul Match', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      dropdownColor: Colors.black87,
                      value: selectedGender,
                      hint: Text('Filter: Gender', style: TextStyle(color: Colors.white)),
                      items: ['All', 'Male', 'Female']
                          .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender, style: TextStyle(color: Colors.white)),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value!;
                          fetchPotentialMatches(); // re-fetch with filter
                        });
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : potentialMatches.isEmpty
                      ? Center(child: Text('No souls to match with today...', style: TextStyle(color: Colors.white70)))
                      : _buildSwipableCards(),
                ),
                _buildActionButtons(),
                SizedBox(height: 20),
              ],
            ),
          ),
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
          swipeAnchor: SwipeAnchor.bottom,
          detectableSwipeDirections: {
            SwipeDirection.left,
            SwipeDirection.right,
          },
          onSwipeCompleted: (index, direction) {
            if (index >= potentialMatches.length) return;

            final user = potentialMatches[index];

            if (direction == SwipeDirection.right) {
              swipeYes(user);
            } else if (direction == SwipeDirection.left) {
              swipeNo(user);
            }
          },
          builder: (context, swipeProps) {
            final user = potentialMatches[swipeProps.index];
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: _buildProfileCard(user),
              ),
            );
          },
        )
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user) {
    String imageUrl = user['icon'] ?? 'assets/default_avatar.png';

    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.purpleAccent.withOpacity(0.5),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          image: DecorationImage(
            image: imageUrl.contains('http')
                ? NetworkImage(imageUrl)
                : AssetImage(imageUrl) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] ?? 'Unknown Soul',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                user['bio'] ?? 'Exploring the universe...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
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
          GestureDetector(
            onTap: () => _controller.next(swipeDirection: SwipeDirection.left),
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Icon(Icons.spa, color: Colors.pinkAccent, size: 36),
            ),
          ),
          GestureDetector(
            onTap: () => _controller.next(swipeDirection: SwipeDirection.right),
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome, color: Colors.yellowAccent, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}