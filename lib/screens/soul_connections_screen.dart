import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import 'friends_page.dart';
import 'soul_match_page.dart'; // for navigation

// ✅ Import your Banner Ad Widget here
import '../widgets/banner_ad_widget.dart';

final SupabaseClient supabase = Supabase.instance.client;

class SoulConnectionsScreen extends StatefulWidget {
  @override
  _SoulConnectionsScreenState createState() => _SoulConnectionsScreenState();
}

class _SoulConnectionsScreenState extends State<SoulConnectionsScreen> {
  final SupabaseService supabaseService = SupabaseService();
  List<UserModel> users = [];
  bool _isLoading = true;
  String? selectedZodiac;
  String? selectedElement;
  String? selectedSpiritualPath;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    currentUserId = supabase.auth.currentUser?.id;

    final fetchedUsers = await supabaseService.getAllUsers();
    setState(() {
      users = fetchedUsers.map((data) => UserModel.fromJson(data)).toList();
      _isLoading = false;
    });
  }

  Future<void> _sendFriendRequest(String userId) async {
    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null) return;

    try {
      await supabase.from('friend_requests').insert({
        'sender_id': senderId,
        'receiver_id': userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Friend request sent!"))
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error sending request."))
      );
    }
  }

  Future<String> _checkFriendshipStatus(String userId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return "not_friends";

    try {
      final friendsCheck = await supabase
          .from('relations')
          .select()
          .or('and(user_id.eq.${user.id},friend_id.eq.$userId),and(user_id.eq.$userId,friend_id.eq.${user.id})')
          .eq('status', 'accepted')
          .limit(1)
          .maybeSingle();

      if (friendsCheck != null) return "friends";

      final sentRequests = await supabase
          .from('friend_requests')
          .select()
          .eq('sender_id', user.id)
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      if (sentRequests.isNotEmpty) return "request_sent";

      final receivedRequests = await supabase
          .from('friend_requests')
          .select()
          .eq('receiver_id', user.id)
          .eq('sender_id', userId)
          .eq('status', 'pending');

      if (receivedRequests.isNotEmpty) return "request_received";

      return "not_friends";
    } catch (error) {
      return "not_friends";
    }
  }

  List<UserModel> _filterUsers() {
    return users.where((user) {
      if (selectedZodiac != null && user.zodiacSign != selectedZodiac) return false;
      if (selectedElement != null && user.element != selectedElement) return false;
      if (selectedSpiritualPath != null && user.spiritualPath != selectedSpiritualPath) return false;
      return true;
    }).toList();
  }

  void _shareInviteLink() {
    final inviteLink = "https://aurana.app/invite";
    Share.share("🌟 Join me on Aurana! 🌌 Click to download: $inviteLink");
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filterUsers();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/misc2.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ✅ Banner Ad at the top
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: BannerAdWidget(),
              ),
              SizedBox(height: 10),

              // 🌟 Title and Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      "Soul Connections",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Here you will find kindred souls from across the cosmic sea. Reach out, connect, and grow your spiritual tribe. 🌿",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 🔹 Navigation Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      icon: Icon(Icons.home, color: Colors.white),
                      label: Text("Home", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: StadiumBorder(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SoulMatchPage()),
                        );
                      },
                      icon: Icon(Icons.favorite, color: Colors.white),
                      label: Text("Soul Match", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _dropdown("Filter by Zodiac", selectedZodiac, [
                      "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                      "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
                    ], (val) => setState(() => selectedZodiac = val)),
                    _dropdown("Filter by Element", selectedElement, [
                      "Fire 🔥", "Water 💧", "Earth 🌿", "Air 🌬️", "Spirit 🌌"
                    ], (val) => setState(() => selectedElement = val)),
                    _dropdown("Filter by Path", selectedSpiritualPath, [
                      "Mystic", "Shaman", "Lightworker", "Astrologer", "Healer", "Diviner"
                    ], (val) => setState(() => selectedSpiritualPath = val)),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // 🔹 User Grid
              _isLoading
                  ? CircularProgressIndicator()
                  : Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
              ),

              SizedBox(height: 10),

              // 🔹 Invite Button
              ElevatedButton.icon(
                onPressed: _shareInviteLink,
                icon: Icon(Icons.share, color: Colors.white),
                label: Text("Invite Friends", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: StadiumBorder(),
                ),
              ),

              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String hint, String? value, List<String> options, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(hint, style: TextStyle(color: Colors.white)),
        dropdownColor: Colors.black87,
        iconEnabledColor: Colors.white,
        underline: SizedBox(),
        onChanged: onChanged,
        items: options.map((opt) {
          return DropdownMenuItem(
            value: opt,
            child: Text(opt, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return FutureBuilder<String>(
      future: _checkFriendshipStatus(user.id),
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'not_friends';

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.5), blurRadius: 10)],
            ),
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                      ? NetworkImage(user.avatar!)
                      : AssetImage("assets/default_avatar.png") as ImageProvider,
                ),
                SizedBox(height: 8),
                Text(user.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                SizedBox(height: 8),
                _buildFriendButton(status, user.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendButton(String status, String userId) {
    if (status == "not_friends") {
      return IconButton(
        icon: Icon(FontAwesomeIcons.userPlus, color: Colors.greenAccent),
        onPressed: () async {
          await _sendFriendRequest(userId);
          setState(() {});
        },
      );
    } else if (status == "request_sent") {
      return Icon(FontAwesomeIcons.hourglassHalf, color: Colors.amber);
    } else if (status == "request_received") {
      return IconButton(
        icon: Icon(FontAwesomeIcons.userCheck, color: Colors.green),
        onPressed: () async {
          await _acceptFriendRequest(userId);
          setState(() {});
        },
      );
    } else if (status == "friends") {
      return Icon(FontAwesomeIcons.solidCheckCircle, color: Colors.blueAccent);
    } else {
      return SizedBox();
    }
  }

  Future<void> _acceptFriendRequest(String userId) async {
    final receiverId = supabase.auth.currentUser?.id;
    if (receiverId == null) return;

    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('sender_id', userId)
          .eq('receiver_id', receiverId);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Friend request accepted!"),
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Error accepting request."),
      ));
    }
  }
}
