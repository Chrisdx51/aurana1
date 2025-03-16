import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/supabase_service.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService supabaseService = SupabaseService();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 3));
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> friendsList = [];
  String currentUserId = "";
  String friendStatus = "not_friends";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeProfile() async {
    setState(() => isLoading = true);
    currentUserId = supabase.auth.currentUser?.id ?? "";
    await _loadUserProfile();
    await _checkFriendStatus();
    await _loadAchievements();
    await _loadFriendsList();
    setState(() => isLoading = false);
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('''
            id,
            name,
            username,
            display_name_choice,
            bio,
            city,
            country,
            gender,
            dob,
            is_online,
            last_seen,
            spiritual_path,
            spiritual_level,
            spiritual_xp,
            element,
            soul_match_message,
            privacy_setting,
            avatar,
            journey_visibility
          ''')
          .eq('id', widget.userId)
          .maybeSingle();


      if (response == null) {
        _showMessage('⚠️ Profile not found.');
        return;
      }


      setState(() {
        userProfile = response;
      });
    } catch (error) {
      print("📝 Loaded userProfile: $userProfile");

      print('❌ Error loading profile: $error');
      _showMessage('❌ Failed to load profile.');
    }
  }

  Future<void> _checkFriendStatus() async {
    try {
      final sentRequest = await supabaseService.checkSentFriendRequest(currentUserId, widget.userId);
      final receivedRequest = await supabaseService.checkReceivedFriendRequest(currentUserId, widget.userId);
      final isFriend = await supabaseService.checkIfFriends(currentUserId, widget.userId);

      setState(() {
        if (isFriend) {
          friendStatus = 'friends';
        } else if (sentRequest) {
          friendStatus = 'sent';
        } else if (receivedRequest) {
          friendStatus = 'received';
        } else {
          friendStatus = 'not_friends';
        }
      });
    } catch (error) {
      print('⚠️ Error checking friend status: $error');
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements = await supabaseService.fetchUserAchievements(widget.userId);
      userProfile ??= {};
      userProfile!['achievements'] = achievements;
    } catch (error) {
      print('❌ Error loading achievements: $error');
    }
  }

  Future<void> _loadFriendsList() async {
    try {
      final response = await supabaseService.getFriendsList(widget.userId);
      setState(() {
        friendsList = response;
      });
    } catch (error) {
      print("❌ Error loading friends list: $error");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> sendFriendRequest() async {
    try {
      await supabaseService.sendFriendRequest(currentUserId, widget.userId);
      setState(() => friendStatus = 'sent');
      _showMessage("✅ Friend request sent!");
    } catch (error) {
      _showMessage("❌ Failed to send friend request.");
    }
  }

  Future<void> cancelFriendRequest() async {
    try {
      await supabaseService.cancelFriendRequest(currentUserId, widget.userId);
      setState(() => friendStatus = 'not_friends');
      _showMessage("✅ Friend request cancelled!");
    } catch (error) {
      _showMessage("❌ Failed to cancel friend request.");
    }
  }

  Future<void> acceptFriendRequest() async {
    try {
      await supabaseService.acceptFriendRequest(currentUserId, widget.userId);
      setState(() => friendStatus = 'friends');
      _showMessage("✅ Friend request accepted!");
    } catch (error) {
      _showMessage("❌ Failed to accept friend request.");
    }
  }

  Future<void> removeFriend() async {
    try {
      await supabaseService.removeFriend(currentUserId, widget.userId);
      setState(() => friendStatus = 'not_friends');
      _showMessage("✅ Friend removed.");
    } catch (error) {
      _showMessage("❌ Failed to remove friend.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: isLoading ? _buildLoading() : _buildProfileBody(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: [Colors.amber, Colors.purpleAccent, Colors.cyanAccent],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Soul Aura'),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white),
          onPressed: _confirmLogout,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildProfileBody() {
    if (userProfile == null) return _buildLoading();

    // Privacy Logic
    String privacy = userProfile?['privacy_setting'] ?? 'public';

    if (privacy == 'private' && widget.userId != currentUserId) {
      return _buildPrivacyLocked('🔒 This profile is private.');
    }

    if (privacy == 'friends_only' && friendStatus != 'friends' && widget.userId != currentUserId) {
      return _buildPrivacyLocked('🔒 Only friends can view this profile.');
    }

    final bool isOnline = userProfile?['is_online'] ?? false;
    final bool isMyProfile = widget.userId == currentUserId;

    DateTime? dob = userProfile?['dob'] != null ? DateTime.tryParse(userProfile!['dob']) : null;
    int age = dob != null ? calculateAge(dob) : 0;
    String zodiac = dob != null ? getZodiacSign(dob) : "Not set";
    String zodiacIcon = 'assets/zodiac/${zodiac.toLowerCase()}.png';

    String displayName = (userProfile!['display_name_choice'] == 'username')
        ? userProfile!['username'] ?? 'Unknown'
        : userProfile!['name'] ?? 'Unknown';

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        _buildHeader(isOnline, isMyProfile, displayName, zodiac, age, zodiacIcon),
        SizedBox(height: 16),
        _buildXPBar(),
        _buildAchievements(),
        _buildProfileDetails(zodiac, age, zodiacIcon),
        _buildFriendsListDisplay(),
        if (!isMyProfile) _buildFriendActions(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrivacyLocked(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildHeader(bool isOnline, bool isMyProfile, String displayName, String zodiac, int age, String zodiacIcon) {
    final lastSeen = userProfile?['last_seen'];
    String lastSeenText = lastSeen != null ? 'Last seen: ${DateTime.tryParse(lastSeen)?.toLocal().toString() ?? ""}' : '';

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: userProfile?['avatar'] != null
                    ? NetworkImage(userProfile!['avatar'])
                    : AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  isOnline ? Icons.star : Icons.star_border,
                  color: isOnline ? Colors.yellow : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            displayName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text('$zodiac, $age years old', style: TextStyle(color: Colors.white70)),
          if (userProfile?['bio'] != null && userProfile!['bio'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                userProfile!['bio'],
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          if (!isOnline && lastSeenText.isNotEmpty)
            Text(lastSeenText, style: TextStyle(color: Colors.white60, fontSize: 12)),
          if (isMyProfile)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        userId: widget.userId,
                        forceComplete: false,
                      ),
                    ),
                  );
                  _initializeProfile();
                },
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildXPBar() {
    int level = userProfile?['spiritual_level'] ?? 1;
    int xp = userProfile?['spiritual_xp'] ?? 0;
    int xpForNext = level * 100;
    double progress = xp / xpForNext;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text("Level $level - XP: $xp / $xpForNext", style: TextStyle(color: Colors.white)),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            color: Colors.amberAccent,
            backgroundColor: Colors.white12,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    bool achievementsLoaded = userProfile?['achievements'] != null;
    List<dynamic> achievements = userProfile?['achievements'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Achievements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        achievementsLoaded && achievements.isNotEmpty
            ? SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Container(
                width: 120,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    achievement['icon_url'] != null
                        ? Image.network(
                      achievement['icon_url'],
                      width: 60,
                      height: 60,
                    )
                        : Icon(Icons.star, color: Colors.yellowAccent, size: 40),
                    SizedBox(height: 8),
                    Text(
                      achievement['title'] ?? '',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        )
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('No Achievements Yet!', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildProfileDetails(String zodiac, int age, String zodiacIcon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Gender', userProfile?['gender']),
          _buildDetailRow('City', userProfile?['city']),
          _buildDetailRow('Country', userProfile?['country']),
          _buildDetailRow('Spiritual Path', userProfile?['spiritual_path']),
          _buildDetailRow('Element', userProfile?['element']),
          _buildDetailRow('Soul Match Message', userProfile?['soul_match_message']),
          _buildDetailRow('Privacy', _privacyDescription(userProfile?['privacy_setting'] ?? 'Not set')),
        ],
      ),
    );
  }

  Widget _buildFriendsListDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.group, color: Colors.white70),
          SizedBox(width: 8),
          Text('${friendsList.length} Friends', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _privacyDescription(String privacySetting) {
    switch (privacySetting.toLowerCase()) {
      case 'public':
        return 'Public: Anyone can view your profile and posts';
      case 'friends_only':
        return 'Friends Only: Only your friends can view your profile and posts';
      case 'private':
        return 'Private: Only you can view your profile';
      default:
        return 'Not set';
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Expanded(child: Text(value ?? 'Not set', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildFriendActions() {
    List<Widget> buttons = [];

    switch (friendStatus) {
      case 'not_friends':
        buttons.add(_buildActionButton('Add Friend', Icons.person_add, Colors.deepPurple, sendFriendRequest));
        break;
      case 'sent':
        buttons.add(_buildActionButton('Cancel Request', Icons.cancel, Colors.grey, cancelFriendRequest));
        break;
      case 'received':
        buttons.add(_buildActionButton('Accept Request', Icons.check_circle, Colors.green, acceptFriendRequest));
        break;
      case 'friends':
        buttons.add(_buildActionButton('Message', Icons.message, Colors.indigo, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                receiverId: widget.userId,
                receiverName: userProfile?['name'] ?? 'User',
              ),
            ),
          );
        }));
        buttons.add(_buildActionButton('Remove Friend', Icons.person_remove, Colors.redAccent, removeFriend));
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: buttons.map((btn) => Padding(padding: EdgeInsets.symmetric(vertical: 4), child: btn)).toList(),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Log out?'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: Text('Log Out'),
          ),
        ],
      ),
    );
  }

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  String getZodiacSign(DateTime dob) {
    int day = dob.day;
    int month = dob.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
    return "Pisces";
  }
}
