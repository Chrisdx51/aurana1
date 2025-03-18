import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'friends_page.dart';
import '../widgets/custom_nav_bar.dart'; // ✅ Bottom nav
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ For Ads

final SupabaseClient supabase = Supabase.instance.client;

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

  // ✅ Banner Ad variables
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _initBannerAd();
  }

  @override
  void dispose() {
    _bannerAd.dispose(); // ✅ Dispose banner ad when not needed
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ✅ Your real Ad Unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner Ad Loaded');
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Failed to load a banner ad: $error');
          ad.dispose();
        },
      ),
    );
    await _bannerAd.load();
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

  Future<void> _sendFriendRequest(String userId) async {
    final senderId = Supabase.instance.client.auth.currentUser?.id;
    if (senderId == null) return;

    try {
      await Supabase.instance.client.from('friend_requests').insert({
        'sender_id': senderId,
        'receiver_id': userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Friend request sent!"),
      ));
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "not_friends";

    try {
      final friendsCheck = await Supabase.instance.client
          .from('relations')
          .select()
          .or('and(user_id.eq.${user.id},friend_id.eq.$userId),and(user_id.eq.$userId,friend_id.eq.${user.id})')
          .eq('status', 'accepted')
          .limit(1)
          .maybeSingle();

      if (friendsCheck != null) return "friends";

      final sentRequests = await Supabase.instance.client
          .from('friend_requests')
          .select()
          .eq('sender_id', user.id)
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      if (sentRequests.isNotEmpty) return "request_sent";

      final receivedRequests = await Supabase.instance.client
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

  Future<void> _acceptFriendRequest(String userId) async {
    final receiverId = Supabase.instance.client.auth.currentUser?.id;
    if (receiverId == null) return;

    try {
      await Supabase.instance.client
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
      body: Column(
        children: [
          if (_isAdLoaded)
            Container(
              margin: EdgeInsets.only(top: 16, bottom: 8), // ✅ Clean gap
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg8.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 20),
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
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(userId: currentUserId!),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.person, color: Colors.white),
                          label: Text("Profile", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    FutureBuilder<int>(
                      future: SupabaseService().getPendingFriendRequestsCount(
                        Supabase.instance.client.auth.currentUser?.id ?? "",
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == 0) return SizedBox();
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "You have ${snapshot.data} friend request(s)!",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          DropdownButton<String>(
                            hint: Text("Filter by Zodiac Sign"),
                            value: selectedZodiac,
                            items: [
                              "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                              "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
                            ].map((sign) => DropdownMenuItem(value: sign, child: Text(sign))).toList(),
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
                            childAspectRatio: 0.4,
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
                                            builder: (context) => ProfileScreen(userId: user.id),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                            ? NetworkImage(user.avatar!)
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
                                        onPressed: () async {
                                          await _sendFriendRequest(user.id);
                                          setState(() {});
                                        },
                                      ),
                                    if (status == "request_sent")
                                      IconButton(
                                        icon: Icon(FontAwesomeIcons.userClock, color: Colors.grey),
                                        onPressed: null,
                                      ),
                                    if (status == "request_received")
                                      IconButton(
                                        icon: Icon(FontAwesomeIcons.userCheck, color: Colors.green),
                                        onPressed: () async {
                                          await _acceptFriendRequest(user.id);
                                          setState(() {});
                                        },
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

                    ElevatedButton.icon(
                      onPressed: _shareInviteLink,
                      icon: Icon(Icons.share, color: Colors.white),
                      label: Text("Invite Friends"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),

                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: 5,
        onItemTapped: (int index) {
          _handleNavTap(context, index);
        },
      ),
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/soulmatch');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/aura');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/souljourney');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/friends');
        break;
      case 5:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 6:
        Navigator.pushReplacementNamed(context, '/more');
        break;
    }
  }
}
