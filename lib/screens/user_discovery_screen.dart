import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'home_screen.dart';

class UserDiscoveryScreen extends StatefulWidget {
  @override
  _UserDiscoveryScreenState createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen> {
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
    currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final fetchedUsers = await supabaseService.getAllUsers();
    setState(() {
      users = fetchedUsers.map((data) => UserModel.fromJson(data)).toList();
      _isLoading = false;
    });
  }

  void _sendFriendRequest(String userId) async {
    final senderId = Supabase.instance.client.auth.currentUser?.id;
    if (senderId == null) return;

    try {
      await supabaseService.sendFriendRequest(senderId, userId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Friend request sent!"),
      ));
      _loadUsers(); // Refresh the list
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Error sending request."),
      ));
    }
  }

  void _shareInviteLink() {
    final inviteLink = "https://aurana.app/invite";
    Share.share("🌟 Join me on Aurana! 🌌 Click to download: $inviteLink");
  }

  Future<String> _checkFriendshipStatus(String userId) async {
    if (currentUserId == null) return 'not_friends';

    try {
      final relations = await Supabase.instance.client
          .from('relations')
          .select()
          .or('and(user_id.eq.${currentUserId ?? ''},friend_id.eq.$userId),and(user_id.eq.$userId,friend_id.eq.${currentUserId ?? ''}))')
          .limit(1)
          .maybeSingle();

      if (relations != null) return 'friends';
    } catch (_) {}

    return 'not_friends';
  }

  List<UserModel> _filterUsers() {
    return users.where((user) {
      if (selectedZodiac != null && user.spiritualPath != selectedZodiac) return false;
      if (selectedElement != null && user.element != selectedElement) return false;
      if (selectedSpiritualPath != null && user.spiritualPath != selectedSpiritualPath) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filterUsers();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg8.png"), // ✅ Ensure correct path
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 50), // Space for Ad Bar

              // 🔹 Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: Icon(Icons.home, color: Colors.white),
                    label: Text("Home", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (currentUserId != null) {
                        Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: currentUserId!)));
                      }
                    },
                    icon: Icon(Icons.person, color: Colors.white),
                    label: Text("Profile", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // 🔹 Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      hint: Text("Filter by Zodiac Sign"),
                      value: selectedZodiac,
                      items: ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                        "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
                          .map((sign) => DropdownMenuItem(value: sign, child: Text(sign)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedZodiac = value),
                    ),
                    DropdownButton<String>(
                      hint: Text("Filter by Element"),
                      value: selectedElement,
                      items: ["Fire 🔥", "Water 💧", "Earth 🌿", "Air 🌬️", "Spirit 🌌"]
                          .map((element) => DropdownMenuItem(value: element, child: Text(element)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedElement = value),
                    ),
                    DropdownButton<String>(
                      hint: Text("Filter by Spiritual Path"),
                      value: selectedSpiritualPath,
                      items: ["Mystic", "Shaman", "Lightworker", "Astrologer", "Healer", "Diviner"]
                          .map((path) => DropdownMenuItem(value: path, child: Text(path)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedSpiritualPath = value),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // 🔹 User Grid (4 users per row)
              _isLoading
                  ? CircularProgressIndicator()
                  : Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.4, // ✅ Corrected aspect ratio
                    ),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];

                      return FutureBuilder<String>(
                        future: _checkFriendshipStatus(user.id),
                        builder: (context, snapshot) {
                          final status = snapshot.data ?? 'not_friends';

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfileScreen(userId: user.id)));
                                },
                                child: CircleAvatar(
                                  backgroundImage: user.icon != null && user.icon!.isNotEmpty
                                      ? NetworkImage(user.icon!)
                                      : AssetImage("assets/default_avatar.png") as ImageProvider,
                                  radius: 35,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                user.name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 5),
                              if (status == "not_friends")
                                IconButton(
                                  icon: Icon(FontAwesomeIcons.userPlus, color: Colors.green),
                                  onPressed: () => _sendFriendRequest(user.id),
                                ),
                              if (status == "friends")
                                Icon(FontAwesomeIcons.solidCheckCircle, color: Colors.blue),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 10),

              // 🔹 Share Invite Button
              ElevatedButton.icon(
                onPressed: _shareInviteLink,
                icon: Icon(Icons.share, color: Colors.white),
                label: Text("Invite Friends"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
