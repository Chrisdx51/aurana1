import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/banner_ad_widget.dart';
import 'help_and_features_screen.dart';
import 'blocked_users_screen.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';
import 'soul_messages_screen.dart';
import 'message_screen.dart';
import 'admin_panel_screen.dart';
import 'about_us_screen.dart';
import 'privacy_policy_screen.dart';

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
    await _checkIfBlocked();
    setState(() => isLoading = false);
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


  Future<void> _checkIfBlocked() async {
    isBlocked =
    await supabaseService.isUserBlocked(currentUserId, widget.userId);
    print("✅ Is user blocked? $isBlocked");
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements =
      await supabaseService.fetchUserAchievements(widget.userId);
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
        _buildHelpButton(context),
        if (isMyProfile) _buildBlockedUsersButton(),
        _buildProfileFooter(context), // 👈 Add this line
        if (isMyProfile) _buildDeleteProfileButton(),

        SizedBox(height: 20),


      ],
    );
  }

  Widget _buildPrivacyLocked(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget _buildHeader(bool isOnline, bool isMyProfile, String displayName,
      String zodiac, int age) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: userProfile?['avatar'] != null
                ? NetworkImage(userProfile!['avatar'])
                : AssetImage('assets/images/default_avatar.png')
            as ImageProvider,
          ),
          SizedBox(height: 8),
          Text(displayName,
              style: TextStyle(fontSize: 24, color: Colors.white)),
          SizedBox(height: 4),
          Text('$zodiac, $age years old',
              style: TextStyle(color: Colors.white70)),
          SizedBox(height: 4),
          Text(isOnline ? '🟢 Online' : '🔴 Offline',
              style: TextStyle(color: Colors.white60)),
          if (userProfile?['bio'] != null &&
              userProfile!['bio'].toString().isNotEmpty)
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
    double progress = xp / xpForNext;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text("Level $level - XP: $xp / $xpForNext",
              style: TextStyle(color: Colors.white)),
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
            style:
            TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                        : Icon(Icons.star,
                        color: Colors.yellowAccent, size: 40),
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
          child: Text('No Achievements Yet!',
              style: TextStyle(color: Colors.white70)),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.group, color: Colors.white70),
          SizedBox(width: 8),
          Text('${friendsList.length} Friends',
              style: TextStyle(color: Colors.white)),
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
              _showMessage("✅ Friend request cancelled!");
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
              _showMessage("✅ Friend request sent!");
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
                builder: (_) => ChatScreen(
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
        SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutUsScreen()),
              );
            },
            icon: Icon(Icons.info_outline, color: Colors.white),
            label: Text('About Aurana', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()),
              );
            },
            icon: Icon(Icons.privacy_tip_outlined, color: Colors.white),
            label: Text('Privacy Policy & Terms', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade800,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        SizedBox(height: 16),

        Text(
          'Aurana © 2025',
          style: TextStyle(color: Colors.white24, fontSize: 12),
        ),

        SizedBox(height: 16),
      ],
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
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = supabase.auth.currentUser;

              if (user != null) {
                // ✅ Update status to offline & set last seen
                await supabase.from('profiles').update({
                  'is_online': false,
                  'last_seen': DateTime.now().toIso8601String(),
                }).eq('id', user.id);

                print("✅ User set to offline before logout");
              }

              // ✅ Now sign out
              await supabase.auth.signOut();

              // ✅ Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: Text('Log Out'),
          ),
        ],
      ),
    );
  }


  Widget _buildHelpButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HelpAndFeaturesScreen()));
        },
        icon: Icon(Icons.help_outline, color: Colors.white),
        label: Text('Help & Features', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade600,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBlockedUsersButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => BlockedUsersScreen()));
        },
        icon: Icon(Icons.block, color: Colors.white),
        label: Text('Blocked Users'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDeleteProfileButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _deleteMyProfile,
        icon: Icon(Icons.delete_forever, color: Colors.white),
        label: Text('Delete My Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
