import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'soul_match_page.dart';
import '../widgets/banner_ad_widget.dart';
import 'message_screen.dart';

final SupabaseClient supabase = Supabase.instance.client;

class SoulConnectionsScreen extends StatefulWidget {
  @override
  _SoulConnectionsScreenState createState() => _SoulConnectionsScreenState();
}

class _SoulConnectionsScreenState extends State<SoulConnectionsScreen> {
  final SupabaseService supabaseService = SupabaseService();
  List<UserModel> users = [];
  bool _isLoading = true;
  String? selectedZodiac = "All";
  String? selectedElement = "All";
  String? selectedSpiritualPath = "All";
  String? currentUserId;
  Map<String, String> friendshipStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    currentUserId = supabase.auth.currentUser?.id;

    final fetchedUsers = await supabaseService.getAllUsers();
    List<UserModel> loadedUsers =
    fetchedUsers.map((data) => UserModel.fromJson(data)).toList();

    for (var user in loadedUsers) {
      String status = await _checkFriendshipStatus(user.id);
      friendshipStatuses[user.id] = status;
    }

    setState(() {
      users = loadedUsers;
      _isLoading = false;
    });
  }

  Future<void> _handleFriendButton(String userId) async {
    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null) return;

    String currentStatus = friendshipStatuses[userId] ?? "not_friends";

    try {
      if (currentStatus == "not_friends") {
        await supabaseService.sendFriendRequest(senderId, userId);
        friendshipStatuses[userId] = "request_sent";
        _showMessage("✅ Friend request sent!");
      } else if (currentStatus == "request_sent") {
        await supabaseService.cancelFriendRequest(senderId, userId);
        friendshipStatuses[userId] = "not_friends";
        _showMessage("❌ Friend request canceled.");
      } else if (currentStatus == "request_received") {
        await supabaseService.acceptFriendRequest(senderId, userId);
        friendshipStatuses[userId] = "friends";
        _showMessage("🤝 Friend request accepted!");
      }
    } catch (error) {
      _showMessage("❌ Error. Try again.");
    }

    setState(() {});
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String> _checkFriendshipStatus(String userId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return "not_friends";

    try {
      return await supabaseService.checkFriendshipStatus(user.id, userId);
    } catch (error) {
      return "not_friends";
    }
  }

  List<UserModel> _filterUsers() {
    return users.where((user) {
      if (selectedZodiac != 'All' && user.zodiacSign != selectedZodiac)
        return false;
      if (selectedElement != 'All' && user.element != selectedElement)
        return false;
      if (selectedSpiritualPath != 'All' &&
          user.spiritualPath != selectedSpiritualPath) return false;
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
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.purple, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  BannerAdWidget(),
                  SizedBox(height: 10),
                  Text(
                    "Soul Connections",
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Find kindred souls 🌌 Grow your spiritual tribe 🌿",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.popUntil(context, (route) => route.isFirst),
                        icon: Icon(Icons.home, color: Colors.white),
                        label: Text("Home"),
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
                        label: Text("Soul Match"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final status =
                          friendshipStatuses[user.id] ?? "not_friends";
                      return _buildUserCard(user, status);
                    },
                  ),
                  SizedBox(height: 30),
                  _dropdown("Filter by Zodiac", selectedZodiac, [
                    "All",
                    "Aries",
                    "Taurus",
                    "Gemini",
                    "Cancer",
                    "Leo",
                    "Virgo",
                    "Libra",
                    "Scorpio",
                    "Sagittarius",
                    "Capricorn",
                    "Aquarius",
                    "Pisces"
                  ], (val) => setState(() => selectedZodiac = val)),
                  _dropdown("Filter by Element", selectedElement, [
                    "All",
                    "Fire 🔥",
                    "Water 💧",
                    "Earth 🌿",
                    "Air 🌬️",
                    "Spirit 🌌"
                  ], (val) => setState(() => selectedElement = val)),
                  _dropdown("Filter by Path", selectedSpiritualPath, [
                    "All",
                    "Mystic",
                    "Shaman",
                    "Lightworker",
                    "Astrologer",
                    "Healer",
                    "Diviner"
                  ], (val) => setState(() => selectedSpiritualPath = val)),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _shareInviteLink,
                    icon: Icon(Icons.share),
                    label: Text("Invite Friends"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: StadiumBorder(),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        Container(
          margin: EdgeInsets.only(bottom: 12, top: 6),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value ?? 'All',
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
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, String status) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
        );
      },
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                  ? NetworkImage(user.avatar!)
                  : AssetImage("assets/default_avatar.png") as ImageProvider,
            ),
            SizedBox(height: 8),
            Text(user.name,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(child: _buildBlockButton(user.id)),
                Flexible(child: _buildFriendButton(status, user.id)),
                Flexible(child: _buildMessageButton(user)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendButton(String status, String userId) {
    IconData icon;
    Color color;

    switch (status) {
      case "not_friends":
        icon = FontAwesomeIcons.userPlus;
        color = Colors.greenAccent;
        break;
      case "request_sent":
        icon = FontAwesomeIcons.userClock;
        color = Colors.amber;
        break;
      case "request_received":
        icon = FontAwesomeIcons.userCheck;
        color = Colors.green;
        break;
      case "friends":
        icon = FontAwesomeIcons.solidCheckCircle;
        color = Colors.blueAccent;
        break;
      default:
        icon = FontAwesomeIcons.userPlus;
        color = Colors.greenAccent;
    }

    return IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: Icon(icon, color: color),
      onPressed: () async {
        await _handleFriendButton(userId);
      },
    );
  }

  Widget _buildMessageButton(UserModel user) {
    return IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: Icon(FontAwesomeIcons.solidCommentDots,
          color: Colors.amberAccent),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MessageScreen(
                receiverId: user.id,
                receiverName: user.name,
              )),
        );
      },
    );
  }

  Widget _buildBlockButton(String userId) {
    return IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: Icon(FontAwesomeIcons.userSlash, color: Colors.redAccent),
      onPressed: () async {
        await supabaseService.blockUser(
            supabase.auth.currentUser!.id, userId);
        _showMessage("🚫 User blocked");
        setState(() {});
      },
    );
  }
}
