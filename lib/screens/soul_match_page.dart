import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'matches_screen.dart'; // Make sure the path is correct!
import '../services/push_notification_service.dart';
import '../models/user_model.dart';

class SoulMatchPage extends StatefulWidget {
  @override
  _SoulMatchPageState createState() => _SoulMatchPageState();
}

class _SoulMatchPageState extends State<SoulMatchPage> {
  final SwipableStackController _controller = SwipableStackController();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> potentialMatches = [];
  List<Map<String, dynamic>> matchedSouls = [];
  bool isLoading = true;
  bool showMatchesTab = false;

  UserModel? currentUserProfile;

  String selectedGender = 'All';
  String swipeMessage = '';

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchPotentialMatches();
    _fetchMatches();
    _initBannerAd();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  Future<void> _loadUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final profile = await supabase
        .from('profiles')
        .select('name, avatar, fcm_token')
        .eq('id', userId)
        .maybeSingle();

    if (profile != null) {
      setState(() {
        currentUserProfile = UserModel.fromJson(profile);

      });
    }

    print('✅ Current user profile loaded: $currentUserProfile');
  }


  Future<void> _fetchPotentialMatches() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // Get ALL interactions you've made (liked, disliked, matched)
      final interactions = await supabase
          .from('soul_matches')
          .select('matched_user_id')
          .eq('user_id', userId);

      final interactedUserIds = interactions.map<String>((e) => e['matched_user_id'] as String).toList();

      // Add yourself to the list of exclusions (so you never see yourself)
      interactedUserIds.add(userId);

      var query = supabase
          .from('profiles')
          .select()
          .not('id', 'in', interactedUserIds); // exclude yourself & everyone you’ve swiped on

      // Optional: Apply gender filter if not "All"
      if (selectedGender != 'All') {
        query = query.eq('gender', selectedGender);
      }

      final response = await query.limit(20);

      setState(() {
        potentialMatches = List<Map<String, dynamic>>.from(response);
        isLoading = false;

        if (potentialMatches.isEmpty) {
          swipeMessage = "No souls found... ✨";
        } else {
          swipeMessage = ""; // Clear message if we found people
        }
      });
    } catch (e) {
      print('❌ Error fetching matches: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchMatches() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    try {
      final response = await supabase
          .from('soul_matches')
          .select('matched_user_id, profiles!matched_user_id(name, avatar, dob, soul_match_message)')
          .eq('user_id', userId)
          .eq('status', 'matched');

      setState(() {
        matchedSouls = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('❌ Error fetching soul matches: $e');
    }
  }

  Future<void> swipeYes(Map<String, dynamic> user) async {
    final userId = supabase.auth.currentUser!.id;
    final matchedUserId = user['id'];

    print('👉 Swiping YES on: $matchedUserId');

    // Insert swipe
    await supabase.from('soul_matches').insert({
      'user_id': userId,
      'matched_user_id': matchedUserId,
      'status': 'liked',
    });

    // Check for mutual like
    final mutual = await supabase
        .from('soul_matches')
        .select()
        .eq('user_id', matchedUserId)
        .eq('matched_user_id', userId)
        .eq('status', 'liked')
        .maybeSingle();

    print('🔥 Mutual like response: $mutual');

    if (mutual != null) {
      print('✅ MATCH! Updating both users to "matched".');

      // Update both records to matched
      await supabase.from('soul_matches').update({'status': 'matched'}).match({
        'user_id': userId,
        'matched_user_id': matchedUserId,
      });

      await supabase.from('soul_matches').update({'status': 'matched'}).match({
        'user_id': matchedUserId,
        'matched_user_id': userId,
      });

      _confettiController.play();
      setState(() {
        swipeMessage = "🌟 It's a soul match! 🌟";
      });

      _fetchMatches();

      // OPTIONAL: Send notifications if you like
    } else {
      print('❌ No mutual like. Waiting for them to like you back.');
      setState(() {
        swipeMessage = "✨ You feel a cosmic pull... ✨";
      });
    }

    // Refresh potential matches (remove this one from swipes)
    _fetchPotentialMatches();
  }

  Future<void> swipeNo(Map<String, dynamic> user) async {
    final userId = supabase.auth.currentUser!.id;
    final matchedUserId = user['id'];

    await supabase.from('soul_matches').insert({
      'user_id': userId,
      'matched_user_id': matchedUserId,
      'status': 'disliked',
    });

    setState(() {
      swipeMessage = "🌙 The journey continues... 🌙";
    });
  }

  void _reportUser(String reportedUserId) async {
    final currentUserId = supabase.auth.currentUser!.id;

    await supabase.from('reports').insert({
      'reporter_id': currentUserId,
      'target_id': reportedUserId,
      'target_type': 'profile',
      'reason': 'Inappropriate profile content',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Report submitted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soul Match'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.withOpacity(0.8), Colors.black.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(showMatchesTab ? Icons.favorite : Icons.people, color: Colors.white),
            onPressed: () {
              setState(() => showMatchesTab = !showMatchesTab);
              if (showMatchesTab) _fetchMatches();
            },
          ),
        ],
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
                if (_isAdLoaded)
                  Container(
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
                SizedBox(height: 10),
                if (!showMatchesTab) _genderDropdown(),
                if (swipeMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      swipeMessage,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ),
                ElevatedButton.icon(
                  icon: Icon(Icons.favorite),
                  label: Text('View Soul Matches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // ✅ Updated from primary
                    foregroundColor: Colors.white,       // ✅ Updated from onPrimary
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MatchesScreen()),
                    );
                  },
                ),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : showMatchesTab
                      ? _buildMatchesList()
                      : potentialMatches.isEmpty
                      ? Center(child: Text('No souls found...', style: TextStyle(color: Colors.white70)))
                      : _buildSwipableCards(),
                ),
                if (!showMatchesTab) _buildActionButtons(),
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

  Widget _genderDropdown() {
    return DropdownButton<String>(
      dropdownColor: Colors.black87,
      value: selectedGender,
      items: ['All', 'Male', 'Female', 'Non-binary', 'Rather not say']
          .map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender, style: TextStyle(color: Colors.white)),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedGender = value!;
          _fetchPotentialMatches();
        });
      },
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
    final avatarUrl = user['avatar'];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.7),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
                : Container(
              color: Colors.grey.withOpacity(0.2),
              alignment: Alignment.center,
              child: Icon(Icons.person_outline, size: 60, color: Colors.white54),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.flag_outlined, color: Colors.redAccent.shade100),
                onPressed: () => _reportUser(user['id']),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Unknown Soul',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.cake, color: Colors.amberAccent, size: 16),
                      SizedBox(width: 4),
                      Text('${calculateAge(user['dob'] ?? '2000-01-01')} years',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(width: 16),
                      Icon(Icons.star, color: Colors.amberAccent, size: 16),
                      SizedBox(width: 4),
                      Text('${getStarSign(user['dob'] ?? '2000-01-01')}',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    user['soul_match_message'] ?? 'Seeking a cosmic connection...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    if (matchedSouls.isEmpty) {
      return Center(child: Text('No soul matches yet...', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      itemCount: matchedSouls.length,
      itemBuilder: (context, index) {
        final match = matchedSouls[index]['profiles'];
        final avatarUrl = match['avatar'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Icon(Icons.person) : null,
          ),
          title: Text(match['name'] ?? 'Unknown Soul', style: TextStyle(color: Colors.white)),
          subtitle: Text(match['soul_match_message'] ?? 'No message', style: TextStyle(color: Colors.white54)),
        );
      },
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

  int calculateAge(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
      final today = DateTime.now();
      int age = today.year - dob.year;

      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return 0;
    }
  }

  String getStarSign(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
      final month = dob.month;
      final day = dob.day;

      if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
      if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Pisces";
      if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
      if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
      if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
      if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
      if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
      if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
      if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
      if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
      if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
      return "Capricorn";
    } catch (e) {
      return "Unknown";
    }
  }
}