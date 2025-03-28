import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

// ✅ Widgets
import '../widgets/banner_ad_widget.dart';

// ✅ Screens
import 'help_and_features_screen.dart';
import 'blocked_users_screen.dart';
import 'edit_profile_screen.dart';
import 'message_screen.dart';
import 'admin_panel_screen.dart';
import 'about_us_screen.dart';
import 'privacy_policy_screen.dart';

// ✅ Services
import '../services/supabase_service.dart';


class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService supabaseService = SupabaseService();
  final ConfettiController _confettiController =
  ConfettiController(duration: Duration(seconds: 3));
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> friendsList = [];
  String currentUserId = "";
  String friendStatus = "not_friends";
  bool isLoading = true;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfile();
    });
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

    await _checkIfBlocked();

    // 🚫 Stop right here if viewer is blocked
    if (isBlocked) {
      setState(() => isLoading = false);
      return;
    }

    await _loadUserProfile();
    await _checkFriendStatus();
    await _loadAchievements();
    await _loadFriendsList();
    setState(() => isLoading = false);
  }


  Future<void> _checkIfBlocked() async {
    try {
      // 👇 I blocked this user?
      isBlocked = await supabaseService.isUserBlocked(currentUserId, widget.userId);

      print("🧱 Blocking status: I blocked them? $isBlocked");
    } catch (error) {
      print("❌ Error checking block status: $error");
      isBlocked = false;
    }
  }





  Future<void> _loadUserProfile() async {
    try {
      final profileId = widget.userId.isNotEmpty ? widget.userId : currentUserId;

      final response = await supabase.from('profiles').select('''
            id, name, username, display_name_choice, bio, city, country, gender, dob,
            is_online, last_seen, spiritual_path, spiritual_level, spiritual_xp,
            element, soul_match_message, privacy_setting, avatar, journey_visibility, role
          ''').eq('id', profileId).maybeSingle();

      if (response == null) {
        _showMessage('⚠️ Profile not found.');
        return;
      }

      setState(() {
        userProfile = response;
      });

      print("✅ Loaded userProfile: $userProfile");
    } catch (error) {
      print('❌ Error loading profile: $error');
      _showMessage('❌ Failed to load profile.');
    }
  }

  Future<void> _deleteMyProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Your Profile?'),
        content: Text(
            'This will permanently delete your profile and all your data. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await supabaseService.deleteUserAndRelatedData(currentUserId);
      if (success) {
        await supabase.auth.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        _showMessage('❌ Failed to delete your profile.');
      }
    }
  }

  Future<void> _checkFriendStatus() async {
    try {
      print("🟡 Checking friendship status...");

      final sentRequest = await supabaseService
          .checkSentFriendRequest(currentUserId, widget.userId);
      print("📤 Sent request: $sentRequest");

      final receivedRequest = await supabaseService
          .checkReceivedFriendRequest(currentUserId, widget.userId);
      print("📥 Received request: $receivedRequest");

      final isFriend = await supabaseService.checkIfFriends(currentUserId, widget.userId);
      print("🫂 Is friend: $isFriend");

      setState(() {
        if (isFriend) friendStatus = 'friends';
        else if (sentRequest) friendStatus = 'sent';
        else if (receivedRequest) friendStatus = 'received';
        else friendStatus = 'not_friends';
      });

      print("✅ friendStatus set to: $friendStatus");
    } catch (error) {
      print('⚠️ Error checking friend status: $error');
    }
  }


  Future<void> _loadAchievements() async {
    try {
      final achievements = await supabaseService.fetchUserAchievements(widget.userId);

      setState(() {
        userProfile ??= {};
        userProfile!['achievements'] = achievements;
      });

      print("🏆 Achievements loaded: $achievements");
    } catch (error) {
      print('❌ Error loading achievements: $error');
    }
  }


  Future<void> _loadFriendsList() async {
    try {
      final response = await supabaseService.getRecentFriends(widget.userId);
      print("👥 Recent friends loaded: $response");
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
            child: Column(
              children: [
                BannerAdWidget(),
                Expanded(
                  child: isLoading ? _buildLoading() : _buildProfileBody(),
                ),
              ],
            ),
          ),
          if (userProfile != null &&
              (userProfile!['role'] == 'admin' || userProfile!['role'] == 'superadmin'))

            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'adminBtn',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminPanelScreen()),
                  );
                },
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900.withOpacity(0.9),
              Colors.purple.shade600.withOpacity(0.9),
              Colors.amber.shade500.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text('Soul Aura', style: TextStyle(color: Colors.white)),
      centerTitle: true,
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
    if (isBlocked) {
      return Center(
        child: Text(
          '🚫 You are blocked or have blocked this user.',
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (userProfile == null) return _buildLoading();

    if (userProfile == null) return _buildLoading();

    String privacy = userProfile?['privacy_setting'] ?? 'public';
    if (privacy == 'private' && widget.userId != currentUserId)
      return _buildPrivacyLocked('🔒 This profile is private.');
    if (privacy == 'friends_only' &&
        friendStatus != 'friends' &&
        widget.userId != currentUserId)
      return _buildPrivacyLocked('🔒 Friends only.');

    final bool isOnline = userProfile?['is_online'] ?? false;
    final bool isMyProfile = widget.userId == currentUserId;

    DateTime? dob = userProfile?['dob'] != null
        ? DateTime.tryParse(userProfile!['dob'])
        : null;
    int age = dob != null ? calculateAge(dob) : 0;
    String zodiac = dob != null ? getZodiacSign(dob) : "Not set";

    String displayName =
    (userProfile!['display_name_choice'] == 'username')
        ? userProfile!['username'] ?? 'Unknown'
        : userProfile!['name'] ?? 'Unknown';

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        _buildHeader(isOnline, isMyProfile, displayName, zodiac, age),
        SizedBox(height: 14),
        _buildXPBar(),
        _buildAchievements(),
        _buildProfileDetails(zodiac, age),
        _buildFriendsListDisplay(),
        if (!isMyProfile) _buildFriendActions(),
        if (isMyProfile) _buildOrbButtonsGrid(),
        _buildProfileFooter(context), // 👈 Add this line
        if (isMyProfile) _buildDeleteProfileButton(),
        if (!isMyProfile) _buildBlockPlaceholder()

        ,SizedBox(height: 20),


      ],
    );
  }
  Widget _buildBlockPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Colors.redAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Block feature coming soon",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "We're working on this feature — you'll soon be able to block users from viewing your profile.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyLocked(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget _buildHeader(bool isOnline, bool isMyProfile, String displayName, String zodiac, int age) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
                  : [],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: userProfile?['avatar'] != null
                  ? NetworkImage(userProfile!['avatar'])
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
          ),
          SizedBox(height: 8),
          Text(displayName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('$zodiac • $age years',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(isOnline ? '🟢 Online' : '🔴 Offline',
              style: TextStyle(color: Colors.white60)),
          if (userProfile?['bio'] != null && userProfile!['bio'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                userProfile!['bio'],
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
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
    double progress = (xp / xpForNext).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Level $level - XP: $xp / $xpForNext",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Achievements',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        achievementsLoaded && achievements.isNotEmpty
            ? SizedBox(
          height: 160, // Increased height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Container(
                width: 140, // Increased width
                margin: EdgeInsets.symmetric(horizontal: 14),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.deepPurple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    achievement['icon_url'] != null
                        ? Image.network(
                      achievement['icon_url'],
                      width: 70,
                      height: 70,
                    )
                        : Icon(Icons.star, color: Colors.yellowAccent, size: 50),
                    SizedBox(height: 10),
                    Text(
                      achievement['title'] ?? '',
                      style: TextStyle(color: Colors.white, fontSize: 13),
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
          child: Text(
            'No Achievements Yet!',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }



  Widget _buildProfileDetails(String zodiac, int age) {
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
          SizedBox(height: 16),
          _buildGlowingBox(),
          ],
      ),
    );
  }
  Widget _buildGlowingBox() {
    final isMyProfile = widget.userId == currentUserId;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soul Match Message Section
          Text(
            'Soul Match Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            userProfile?['soul_match_message'] ?? 'No message set.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),

          SizedBox(height: 24),

          // Privacy Section with logic
          Text(
            'Privacy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isMyProfile
                ? _privacyDescription(userProfile?['privacy_setting'] ?? 'Not set')
                : 'This information is private.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFriendsListDisplay() {
    if (friendsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Friends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 12),
            Text('You have no recent friends yet.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Friends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: friendsList.length,
              itemBuilder: (context, index) {
                final friend = friendsList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: friend['id']),
                      ),
                    );
                  },
                  child: Container(
                    width: 90,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundImage: friend['avatar'] != null
                                ? NetworkImage(friend['avatar'])
                                : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            radius: 35,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          friend['name'] ?? 'Unknown',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
          Text('$label: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Expanded(
              child: Text(value ?? 'Not set', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildFriendActions() {
    List<Widget> buttons = [];

    switch (friendStatus) {
      case 'not_friends':
        buttons.add(_buildActionButton(
          'Add Friend',
          Icons.person_add,
          Colors.deepPurple,
              () async {
            final alreadySent = await supabaseService.checkSentFriendRequest(currentUserId, widget.userId);
            final alreadyFriends = await supabaseService.checkIfFriends(currentUserId, widget.userId);

            if (alreadySent || alreadyFriends) {
              await _checkFriendStatus();
              _showMessage("⚠️ Request already sent or you're already friends.");
              return;
            }

            final success = await supabaseService.sendFriendRequest(currentUserId, widget.userId);
            if (success) {
              await _initializeProfile();
              _showMessage("✅ Friend request sent!");
            }


              },
        ));
        break;

      case 'sent':
        buttons.add(_buildActionButton(
          'Cancel Request',
          Icons.cancel,
          Colors.grey,
              () async {
            final success = await supabaseService.cancelFriendRequest(currentUserId, widget.userId);
            if (success) {
              await _initializeProfile();
              _showMessage("❌ Friend request cancelled.");
            }

              },
        ));
        break;

      case 'received':
        buttons.add(_buildActionButton(
          'Accept Request',
          Icons.check_circle,
          Colors.green,
              () async {
            final accepted = await supabaseService.acceptFriendRequest(currentUserId, widget.userId);
            if (accepted) {
              _confettiController.play();
              _audioPlayer.play(AssetSource('sounds/friend_accepted.mp3'));

              print("🔁 Re-checking friend status...");
              await _initializeProfile(); // 🔁 FULL reload instead of just _checkFriendStatus()
              _showMessage("🎉 Friend request accepted!");
            }

              },
        ));
        break;

      case 'friends':
        buttons.add(_buildActionButton(
          'Message',
          Icons.message,
          Colors.indigo,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessageScreen(
                  receiverId: widget.userId,
                  receiverName: userProfile?['name'] ?? 'User',
                ),
              ),
            );
          },
        ));
        buttons.add(_buildActionButton(
          'Remove Friend',
          Icons.person_remove,
          Colors.redAccent,
              () async {
            final removed = await supabaseService.removeFriend(currentUserId, widget.userId);
            if (removed) {
              await _initializeProfile();
              _showMessage("✅ Friend removed.");
            }

              },
        ));
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: buttons
            .map((btn) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: btn,
        ))
            .toList(),
      ),
    );
  }


  Widget _buildProfileFooter(BuildContext context) {
    return Column(
      children: [
        Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
        SizedBox(height: 10),
        Text('Aurana © 2025', style: TextStyle(color: Colors.white24, fontSize: 12)),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      builder: (_) => Dialog(
        backgroundColor: Colors.deepPurple.shade800.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: 380), // 💡 Fixed height
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app_rounded, size: 48, color: Colors.amberAccent),
              SizedBox(height: 16),
              Text(
                'Leaving the Light?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Expanded( // 💬 Only this part scrolls!
                child: SingleChildScrollView(
                  child: Text(
                    'You don’t need to log out to close the app.\n'
                        'Just exit it—it’s faster and more peaceful 🌙.\n\n'
                        'But if you really want to log out,\n'
                        'you can do that below.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.close, size: 16),
                    label: Text("Stay"),
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: TextStyle(fontSize: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.logout, size: 16),
                    label: Text("Log Out"),
                    onPressed: () async {
                      final user = supabase.auth.currentUser;
                      if (user != null) {
                        await supabase.from('profiles').update({
                          'is_online': false,
                          'last_seen': DateTime.now().toIso8601String(),
                        }).eq('id', user.id);
                      }
                      await supabase.auth.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade200.withOpacity(0.9),
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: TextStyle(fontSize: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildOrbButtonsGrid() {
    final isMyProfile = widget.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _orbButton(
                icon: Icons.help_outline,
                label: 'Help & Features',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HelpAndFeaturesScreen()));
                },
              ),
              _orbButton(
                icon: Icons.block,
                label: 'Blocked Users',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BlockedUsersScreen()),
                  );
                },
              ),
              _orbButton(
                icon: Icons.info_outline,
                label: 'About Aurana',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutUsScreen()),
                  );
                },
              ),
              _orbButton(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy & Terms',
                color: Colors.blueGrey.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PrivacyPolicyScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orbButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withOpacity(0.95), color.withOpacity(0.4)],
                center: Alignment(-0.2, -0.2),
                radius: 0.95,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.7),
                  blurRadius: 18,
                  spreadRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 32, color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }




  Widget _buildDeleteProfileButton() {
    return _buildProfileButton(
      icon: Icons.delete_forever,
      text: 'Delete My Profile',
      color: Colors.purple.shade800,
      onTap: _deleteMyProfile,
    );
  }


  Future<bool> _checkIfAdmin(String? userId) async {
    if (userId == null) return false;

    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    final role = response['role'] ?? 'user';
    return role == 'admin' || role == 'superadmin';
  }

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) age--;
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
