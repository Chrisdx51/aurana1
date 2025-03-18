import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/banner_ad_widget.dart';

class SoulMatchPage extends StatefulWidget {
  @override
  _SoulMatchPageState createState() => _SoulMatchPageState();
}

class _SoulMatchPageState extends State<SoulMatchPage> {
  final SwipableStackController _controller = SwipableStackController();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));

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
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .neq('id', userId)
          .limit(20);

      setState(() {
        potentialMatches = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void swipeYes(Map<String, dynamic> user) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final matchedUserId = user['id'];

    try {
      await Supabase.instance.client.from('soul_matches').insert({
        'user_id': userId,
        'matched_user_id': matchedUserId,
        'status': 'liked',
      });

      final mutual = await Supabase.instance.client
          .from('soul_matches')
          .select()
          .eq('user_id', matchedUserId)
          .eq('matched_user_id', userId)
          .eq('status', 'liked')
          .maybeSingle();

      if (mutual != null) {
        _confettiController.play();
        _showMatchDialog(user);
      } else {
        _showLikedOnlyDialog(user);
      }
    } catch (e) {}
  }

  void swipeNo(Map<String, dynamic> user) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final matchedUserId = user['id'];

    try {
      await Supabase.instance.client.from('soul_matches').insert({
        'user_id': userId,
        'matched_user_id': matchedUserId,
        'status': 'disliked',
      });

      final theyLikedYou = await Supabase.instance.client
          .from('soul_matches')
          .select()
          .eq('user_id', matchedUserId)
          .eq('matched_user_id', userId)
          .eq('status', 'liked')
          .maybeSingle();

      if (theyLikedYou != null) {
        _showMissedSoulDialog(user);
      } else {
        _showNoMatchDialog(user);
      }
    } catch (e) {}
  }

  // ✅ DIALOGS ✅

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
            CircleAvatar(radius: 40, backgroundImage: NetworkImage(user['avatar'] ?? '')),
            SizedBox(height: 10),
            Text('You and ${user['name']} are connected!', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Later', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
        title: Text('Awaiting Connection...', style: TextStyle(color: Colors.white)),
        content: Text('You liked ${user['name']}. Let’s see if they like you back.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showMissedSoulDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Missed Soul Journey', style: TextStyle(color: Colors.white)),
        content: Text('You missed a connection with ${user['name']}. Trust the journey.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showNoMatchDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Moved On', style: TextStyle(color: Colors.white)),
        content: Text('You passed on ${user['name']}. Onward on your journey.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.deepPurple.withOpacity(0.6), Colors.black.withOpacity(0.9)],
              center: Alignment.topLeft,
              radius: 1.2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'About Soul Match',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Divider(color: Colors.white.withOpacity(0.3)),
              SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        "Swipe right to connect with a kindred spirit.\n\n"
                            "This is a sacred space to find your journey companion, a wise guide, or a new friend. Not just dating—connect with those who walk the same path.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "✨ Your soul tribe is waiting ✨",
                        style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Begin Journey', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ UI BUILDERS ✅

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.8),
                Colors.black.withOpacity(0.8),
                Colors.white.withOpacity(0.1)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Soul Match', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showInfoDialog,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: BannerAdWidget(),
                ),
                SizedBox(height: 10),

                DropdownButton<String>(
                  dropdownColor: Colors.black87,
                  value: selectedGender,
                  items: ['All', 'Male', 'Female']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender, style: TextStyle(color: Colors.white)),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                      fetchPotentialMatches();
                    });
                  },
                ),

                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : potentialMatches.isEmpty
                      ? Center(child: Text('No souls to match today...', style: TextStyle(color: Colors.white70)))
                      : _buildSwipableCards(),
                ),
                _buildActionButtons(),
                SizedBox(height: 10),
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
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SwipableStack(
        controller: _controller,
        itemCount: potentialMatches.length,
        onSwipeCompleted: (index, direction) {
          if (index >= 0 && index < potentialMatches.length) {
            if (direction == SwipeDirection.right) swipeYes(potentialMatches[index]);
            if (direction == SwipeDirection.left) swipeNo(potentialMatches[index]);
          }
        },
        builder: (context, swipeProps) {
          if (swipeProps.index < 0 || swipeProps.index >= potentialMatches.length) return SizedBox();
          final user = potentialMatches[swipeProps.index];
          return Align(
            alignment: Alignment.center,
            child: _buildProfileCard(user),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user) {
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
              placeholder: 'assets/default_avatar.png',
              image: user['avatar'] ?? 'https://i.pravatar.cc/300',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.5)]),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? 'Unknown Soul', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(user['soul_match_message'] ?? 'Seeking a cosmic connection...', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _controller.next(swipeDirection: SwipeDirection.left),
            child: _actionButton(icon: Icons.cancel_outlined, iconColor: Colors.redAccent),
          ),
          GestureDetector(
            onTap: () => _controller.next(swipeDirection: SwipeDirection.right),
            child: _actionButton(icon: Icons.favorite_border, iconColor: Colors.greenAccent),
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
        boxShadow: [BoxShadow(color: iconColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 5)],
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }
}
