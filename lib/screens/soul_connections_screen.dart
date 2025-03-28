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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    currentUserId = supabase.auth.currentUser?.id;

    final fetchedUsers = await supabaseService.getAllUsers();
    List<UserModel> loadedUsers = fetchedUsers.map((data) => UserModel.fromJson(data)).toList();

    setState(() {
      users = loadedUsers;
      _isLoading = false;
    });
  }

  List<UserModel> _filterUsers() {
    return users.where((user) {
      if (selectedZodiac != 'All' && user.zodiacSign != selectedZodiac) return false;
      if (selectedElement != 'All' && user.element != selectedElement) return false;
      if (selectedSpiritualPath != 'All' && user.spiritualPath != selectedSpiritualPath) return false;
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),

                  // 🔸 Banner Ad
                  BannerAdWidget(),
                  const SizedBox(height: 12),

                  // 🔸 Soul Connections Title (Smaller + Clean)
                  const Text(
                    "Soul Connections",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    "Find kindred souls 🌌 Grow your spiritual tribe 🌿",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // 🔸 Navigation Buttons under Banner
                  _topNavButtons(context),

                  const SizedBox(height: 20),

                  // 🔸 User Grid or Loading
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _buildUserGrid(filteredUsers),

                  const SizedBox(height: 30),

                  // 🔸 Filters
                  _dropdown("Filter by Zodiac", selectedZodiac, [
                    "All",
                    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
                  ], (val) => setState(() => selectedZodiac = val)),

                  _dropdown("Filter by Element", selectedElement, [
                    "All", "Fire 🔥", "Water 💧", "Earth 🌿", "Air 🌬️", "Spirit 🌌"
                  ], (val) => setState(() => selectedElement = val)),

                  _dropdown("Filter by Path", selectedSpiritualPath, [
                    "All", "Mystic", "Shaman", "Lightworker", "Astrologer", "Healer", "Diviner"
                  ], (val) => setState(() => selectedSpiritualPath = val)),

                  const SizedBox(height: 20),

                  // 🔸 Invite Friends
                  ElevatedButton.icon(
                    onPressed: _shareInviteLink,
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text("Invite Friends"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: const StadiumBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Center(
            child: Text(
              "Aurana",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            final userId = supabase.auth.currentUser?.id;
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
              );
            }
          },
        ),
      ],
    );
  }


  Widget _topNavButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          icon: const Icon(Icons.home, color: Colors.white, size: 16),
          label: const Text("Home"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SoulMatchPage()),
          ),
          icon: const Icon(Icons.favorite, color: Colors.white, size: 16),
          label: const Text("Soul Match"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildUserGrid(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: Text(
            'No connections found 🌙',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                  ? NetworkImage(user.avatar!)
                  : const AssetImage("assets/default_avatar.png") as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              user.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddFriendButton(user.id),
                _buildMessageButton(user),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildAddFriendButton(String userId) {
    return IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(Icons.person_add_alt_1, color: Colors.lightGreenAccent),
      onPressed: () async {
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          final success = await supabaseService.sendFriendRequest(currentUser.id, userId);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Friend request sent")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Already sent or you're already friends")),
            );
          }
        }
      },
    );
  }

  Widget _buildMessageButton(UserModel user) {
    return IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(FontAwesomeIcons.solidCommentDots, color: Colors.amberAccent),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              receiverId: user.id,
              receiverName: user.name,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockButton(String userId) {
    return IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(FontAwesomeIcons.userSlash, color: Colors.redAccent),
      onPressed: () async {
        await supabaseService.blockUser(supabase.auth.currentUser!.id, userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚫 User blocked")),
        );
        setState(() {});
      },
    );
  }

  Widget _dropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value ?? 'All',
            dropdownColor: Colors.black87,
            iconEnabledColor: Colors.white,
            underline: const SizedBox(),
            onChanged: onChanged,
            items: options.map((opt) {
              return DropdownMenuItem(
                value: opt,
                child: Text(opt, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
