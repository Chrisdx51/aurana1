import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'auth_screen.dart';
import '../main.dart';
import 'friends_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool forceComplete; // ✅ Add this to force profile completion

  ProfileScreen({required this.userId, this.forceComplete = false});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final SupabaseService supabaseService = SupabaseService();
  UserModel? user;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isProfileComplete = false;
  bool _friendRequestSent = false;
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _spiritualPathController = TextEditingController();
  DateTime? _selectedDOB;
  String? _zodiacSign;
  String? _selectedElement;
  String? _selectedSpiritualPath;
  String? _selectedPrivacy = "public"; // ✅ Default privacy setting
  int _spiritualXP = 0;
  int _spiritualLevel = 1;
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this); // ✅ FIX: Add null check

    _loadUserProfile();
    _checkProfileCompletion(); // ✅ Ensures users complete profiles before proceeding
    _loadAchievements();
    _checkFriendshipStatus();

  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this); // ✅ FIXED: Prevents errors
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // ✅ App is back in focus → Set user as online
      await Supabase.instance.client.from('profiles').update({
        'is_online': true,
        'last_seen': null, // ✅ Reset last seen when user is active
      }).eq('id', widget.userId);
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return; // ✅ Prevent calling setState() after dispose

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final profile = await supabaseService.getUserProfile(widget.userId);

      if (!mounted) return; // ✅ Stop execution if widget is gone

      if (profile != null) {
        setState(() {
          user = profile;
          _nameController.text = profile.name ?? "";
          _bioController.text = profile.bio ?? "";
          _spiritualPathController.text = profile.spiritualPath ?? "";
          _selectedElement = profile.element;
          _spiritualXP = profile.spiritualXP ?? 0;
          _spiritualLevel = profile.spiritualLevel ?? 1;
          _isLoading = false;

          // ✅ Fix: Initialize _selectedDOB properly
          if (profile.dob != null && profile.dob!.isNotEmpty) {
            _selectedDOB = DateTime.tryParse(profile.dob!);
            _zodiacSign = _selectedDOB != null ? _getZodiacSign(_selectedDOB!) : null;
          }
        });


        // ✅ Load achievements AFTER user is loaded
        _loadAchievements();
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }


  Widget buildOnlineStatus(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox.shrink();

        final user = snapshot.data![0];
        bool isOnline = user['is_online'] ?? false;

        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? Colors.green : Colors.grey, // 🟢 Online | ⚪ Offline
            border: Border.all(color: Colors.white, width: 2),
          ),
        );
      },
    );
  }
  Future<void> _loadAchievements() async {
    if (widget.userId.isEmpty) {
      print("⚠️ Cannot load achievements: User ID is empty.");
      return;
    }

    try {
      print("🔄 Fetching latest achievement for: ${widget.userId}");

      // Fetch ONLY the latest unlocked achievement (ORDER BY earned_at DESC, LIMIT 1)
      final achievements = await supabaseService.fetchUserAchievements(widget.userId);

      if (achievements == null || achievements.isEmpty) {
        print("❌ No achievements found.");
        if (mounted) {
          setState(() {
            _achievements = []; // ✅ Clear previous achievements
          });
        }
        return;
      }

      // ✅ Keep only the latest achievement (first item in the list)
      final latestAchievement = achievements.first;

      if (mounted) {
        setState(() {
          _achievements = [latestAchievement]; // ✅ Replace with only the latest
        });
      }

      print("✅ Latest achievement loaded: ${latestAchievement['title']}");
    } catch (error) {
      print("❌ Error loading achievements: $error");

      if (mounted) {
        setState(() {
          _achievements = []; // ✅ Prevent crash
        });
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    File imageFile = File(image.path);
    final imageUrl = await supabaseService.uploadProfilePicture(widget.userId, imageFile);

    if (imageUrl != null) {
      bool success = await supabaseService.updateUserProfile(
        widget.userId,
        _nameController.text,
        _bioController.text,
        _selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : null,
        imageUrl,
        _spiritualPathController.text,
        _selectedElement,
        user?.privacy ?? "public", // ✅ Added privacy as String
        _spiritualXP,
        _spiritualLevel,
      );

      if (success) {
        setState(() {
          user = user?.copyWith(icon: imageUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Profile picture updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to save profile picture in database.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to upload image to Supabase storage.")),
      );
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDOB = pickedDate;
        _zodiacSign = _getZodiacSign(pickedDate);
      });

      await supabaseService.updateUserProfile(
        widget.userId,
        _nameController.text,
        _bioController.text,
        DateFormat('yyyy-MM-dd').format(pickedDate), // ✅ Fix: Save formatted DOB
        user?.icon ?? '',
        _spiritualPathController.text,
        _selectedElement,
        _selectedPrivacy ?? "public",
        _spiritualXP,
        _spiritualLevel,
      );
    }
  }


  String _getZodiacSign(DateTime dob) {
    int day = dob.day;
    int month = dob.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "♈ Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "♉ Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "♊ Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "♋ Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "♌ Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "♍ Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "♎ Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "♏ Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "♐ Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "♑ Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "♒ Aquarius";
    return "♓ Pisces";
  }

  Future<void> _saveProfileAndUnlockNav() async {
    print("🔄 Attempting to save profile...");

    bool success = await _updateProfile();

    if (success) {
      print("✅ Profile successfully updated! Reloading UI...");

      // ✅ Reload profile immediately after saving
      await _loadUserProfile();

      if (!mounted) return; // ✅ Prevents crash if screen was closed

      // ✅ Refresh the whole screen after saving
      setState(() {});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userId: widget.userId)),
      );
    } else {
      print("❌ Profile update failed!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update profile. Try again!")),
      );
    }
  }

  Future<bool> _checkIfFriends() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    final friendsResponse = await Supabase.instance.client
        .from('relations')
        .select()
        .or('and(user_id.eq.$userId,friend_id.eq.${widget.userId}),and(user_id.eq.${widget.userId},friend_id.eq.$userId))')
        .limit(1)
        .maybeSingle();

    return friendsResponse != null;
  }

  Future<bool> _updateProfile() async {
    print("🔄 Attempting to update profile...");

    if (_nameController.text.trim().isEmpty || _bioController.text.trim().isEmpty || _selectedDOB == null) {
      print("❌ Profile is incomplete! Blocking update.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Name, Bio, and DOB are required before saving!")),
      );
      return false;
    }

    print("✅ Profile fields entered: Name = ${_nameController.text}, Bio = ${_bioController.text}, DOB = ${_selectedDOB.toString()}");

    bool success = await supabaseService.updateUserProfile(
      widget.userId,
      _nameController.text,
      _bioController.text,
      _selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : null,
      user?.icon ?? '',
      _spiritualPathController.text,
      _selectedElement,
      user?.privacy ?? "public",
      _spiritualXP,
      _spiritualLevel,
    );

    if (success) {
      print("✅ Profile updated successfully!");

      // ✅ Immediately reload profile after saving
      await _loadUserProfile();

      if (!mounted) return false;

      setState(() {});

      return true;
    } else {
      print("❌ Failed to update profile.");
      return false;
    }
  }


  Future<void> _checkProfileCompletion() async {
    if (user == null) {
      print("❌ User is null. Cannot check profile completion.");
      return;
    }

    bool isComplete = await supabaseService.isProfileComplete(widget.userId);
    print("🔍 Profile completion check: $isComplete");

    if (isComplete) {
      print("✅ Profile is complete! Allowing navigation.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userId: widget.userId)),
      );
    } else {
      print("❌ Profile is incomplete! Blocking navigation.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ You must complete your profile before leaving this page!")),
      );
    }
  }

  void _checkLevelUp() {
    int xpNeeded = _spiritualLevel * 100;

    if (_spiritualXP >= xpNeeded) {
      setState(() {
        _spiritualXP = 0;
        _spiritualLevel += 1;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("🎉 Level Up!"),
          content: Text("Congratulations! You've reached Level $_spiritualLevel!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Awesome!"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPrivacyDropdown() {
    return _buildDropdownField(
      "Profile Privacy",
      user?.privacy ?? "public",
      ["public", "friends_only", "private"],
          (newValue) async {
        setState(() {
          user = user?.copyWith(privacy: newValue);
        });

        await supabaseService.updateUserProfile(
          widget.userId,
          _nameController.text,
          _bioController.text,
          _selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : null,
          user?.icon ?? '',
          _spiritualPathController.text,
          _selectedElement,
          _selectedPrivacy ?? "public", // ✅ Ensures a valid string
          _spiritualXP,
          _spiritualLevel,
        );
      },
    );
  }


  Widget _buildBubbleField(String label, TextEditingController controller, IconData icon, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purpleAccent),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: hint,
                errorText: controller.text.isEmpty ? "$label is required" : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleDateField(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.green, blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  date != null ? DateFormat('yyyy-MM-dd').format(date) : label,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleText(String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.blueAccent),
        SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          hint: Text(label, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          isExpanded: true,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option, style: TextStyle(fontSize: 16)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    int xpNeeded = (_spiritualLevel * 100);
    double progress = _spiritualXP / xpNeeded;

    return Column(
      children: [
        Text(
          'Level $_spiritualLevel • XP: $_spiritualXP / $xpNeeded',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress > 1 ? 1 : progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🏆 Achievements",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        SizedBox(height: 10),

        _achievements.isEmpty
            ? Text("No achievements unlocked yet. Keep growing! 🌟",
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic))
            : Column(
          children: _achievements.map((achievement) {
            return Card(
              color: Colors.white.withOpacity(0.8),
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (achievement['icon_url'] != null && achievement['icon_url'].isNotEmpty)
                      Image.network(
                        achievement['icon_url'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported, size: 50, color: Colors.red);
                        },
                      ),

                    SizedBox(height: 10),

                    Text(
                      achievement['title'] ?? "Unknown Title",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 5),

                    Text(
                      achievement['description'] ?? "No description available.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8),

                    Text(
                      achievement['earned_at'] != null
                          ? DateFormat('MMM dd, yyyy').format(DateTime.parse(achievement['earned_at']))
                          : "Unknown Date",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.black)),
    backgroundColor: Colors.white,
    elevation: 0,
    actions: [
    IconButton(icon: Icon(Icons.logout, color: Colors.red), onPressed: _logout),
    ],
    ),
    body: Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Colors.blue.shade300, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    ),
    ),
    child: SafeArea(
    child: SingleChildScrollView(
    padding: EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    SizedBox(height: 20),
      GestureDetector(
        onTap: widget.userId == Supabase.instance.client.auth.currentUser?.id
            ? _changeProfilePicture
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 65,
              backgroundColor: widget.userId == Supabase.instance.client.auth.currentUser?.id
                  ? Colors.white
                  : Colors.blueAccent,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: (user?.icon != null && user!.icon!.isNotEmpty && user!.icon!.startsWith('http'))
                    ? NetworkImage(user!.icon!)
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
            ),
            // ✅ Online Indicator Positioned at Bottom Right
            Positioned(
              bottom: 8,
              right: 8,
              child: buildOnlineStatus(widget.userId),
            ),
          ],
        ),
      ),

      SizedBox(height: 30),
      Column(
        children: [
          FutureBuilder<String>(
            future: _checkFriendshipStatus(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final status = snapshot.data!;
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;

              if (widget.userId == currentUserId) {
                return SizedBox();
              }

              print("🛠 Friendship Status in UI: $status");

              return Column(
                children: [
                  if (status == "not_friends")
                    ElevatedButton(
                      onPressed: () async {
                        await _sendFriendRequest();
                        setState(() {});
                      },
                      child: Text("Add Friend"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (status == "sent")
                    ElevatedButton(
                      onPressed: () async {
                        await _cancelFriendRequest();
                        setState(() {});
                      },
                      child: Text("Cancel Request ❌"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (status == "received")
                    Column(
                      children: [
                        Text(
                          "✅ Friend Request Received!",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () async {
                            await _acceptFriendRequest();
                            setState(() {});
                          },
                          child: Text("Accept Friend Request ✅"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  if (status == "friends")
                    Column(
                      children: [
                        Text(
                          "✅ You are friends!",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () async {
                            await _removeFriend();
                            setState(() {});
                          },
                          child: Text("Remove Friend ❌"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFriendsList(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final friends = snapshot.data!;
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;

              if (widget.userId != currentUserId) {
                return SizedBox();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👥 Friends",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 10),
                  friends.isEmpty
                      ? Text("No friends yet. Add some!", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic))
                      : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(userId: friend['id']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: friend['icon'] != null && friend['icon'].startsWith('http')
                                      ? NetworkImage(friend['icon'])
                                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                                ),
                                SizedBox(height: 5),
                                Text(friend['name'], style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      if (widget.userId == Supabase.instance.client.auth.currentUser?.id) ...[
        _buildBubbleField("Your Spiritual Name", _nameController, FontAwesomeIcons.sun, "Enter your sacred name"),
        SizedBox(height: 5),
        _buildBubbleField("Tell us about you", _bioController, FontAwesomeIcons.moon, "What brings you here?"),
        SizedBox(height: 5),
        _buildDropdownField(
          "Choose your Spiritual Path",
          _selectedSpiritualPath ?? spiritualPaths.first,
          spiritualPaths,
              (newValue) {
            setState(() {
              _selectedSpiritualPath = newValue;
            });
          },
        ),
        SizedBox(height: 10),
        _buildDropdownField(
          "Select Your Element",
          _selectedElement ?? elements.first,
          elements,
              (newValue) {
            setState(() {
              _selectedElement = newValue;
            });
          },
        ),
        SizedBox(height: 5),
        _buildBubbleDateField("Your Birth Date", _selectedDOB, _pickDate),
        SizedBox(height: 5),
        _buildBubbleText(_zodiacSign ?? "Not Set", FontAwesomeIcons.galacticRepublic),
        SizedBox(height: 20),
        _buildProgressBar(),
        _buildAchievementsSection(),  // ✅ Added back achievements for your profile
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.trim().isEmpty || _bioController.text.trim().isEmpty || _selectedDOB == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("⚠️ Please fill out Name, Bio, and DOB before saving."))
              );
              return;
            }

            bool success = await _updateProfile();
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ Profile updated successfully!"))
              );

              // ✅ Reload profile immediately after saving
              await _loadUserProfile();

              // ✅ Ensure the UI refreshes
              if (mounted) {
                setState(() {});
              }

              // ✅ Delay navigation slightly to prevent UI glitches
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted && _isProfileComplete) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen(userId: widget.userId)),
                  );
                }
              });
            }
          },
          child: Text("Save Changes"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],

        if (widget.userId != Supabase.instance.client.auth.currentUser?.id) ...[
        _buildBubbleText(_nameController.text, FontAwesomeIcons.sun),
        SizedBox(height: 5),
        _buildBubbleText(_bioController.text, FontAwesomeIcons.moon),
        SizedBox(height: 5),
        _buildBubbleText(_selectedSpiritualPath ?? "Not Set", FontAwesomeIcons.seedling),
        SizedBox(height: 10),
        _buildBubbleText(_selectedElement ?? "Not Set", FontAwesomeIcons.leaf),
        SizedBox(height: 5),
        _buildBubbleText(_selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : "Not Set", FontAwesomeIcons.calendar),
        SizedBox(height: 5),
        _buildBubbleText(_zodiacSign ?? "Not Set", FontAwesomeIcons.galacticRepublic),
        SizedBox(height: 20),
        _buildProgressBar(),
        _buildAchievementsSection(),
      ],
      Column(
        children: [
          SizedBox(height: 20),

        ],
      ),
    ],
    ),
    ),
    ),
    ),
    );
  }

  Future<List<Map<String, dynamic>>> _getFriendsList() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('relations')
          .select('friend_id')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      List<Map<String, dynamic>> friends = [];
      for (var entry in response) {
        final friendId = entry['friend_id'];
        if (friendId != userId) {
          final friendProfile = await supabaseService.getUserProfile(friendId);
          if (friendProfile != null) {
            friends.add({
              'id': friendId,
              'name': friendProfile.name,
              'icon': friendProfile.icon,
            });
          }
        }
      }

      return friends;
    } catch (error) {
      print("❌ Error getting friend list: $error");
      return [];
    }
  }

  Future<String> _checkFriendshipStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 'not_friends';

    try {
      final friendsResponse = await Supabase.instance.client
          .from('relations')
          .select()
          .or('and(user_id.eq.$userId,friend_id.eq.${widget.userId}),and(user_id.eq.${widget.userId},friend_id.eq.$userId))')
          .limit(1)
          .maybeSingle();

      if (friendsResponse != null) {
        print("✅ Friendship Status: friends");
        return 'friends';
      }
    } catch (error) {
      print("⚠️ No friendship found in relations table: $error");
    }

    try {
      final sentRequestResponse = await Supabase.instance.client
          .from('friend_requests')
          .select()
          .eq('sender_id', userId)
          .eq('receiver_id', widget.userId)
          .eq('status', 'pending')
          .limit(1)
          .maybeSingle();

      if (sentRequestResponse != null) {
        print("✅ Friendship Status: sent");
        return 'sent';
      }
    } catch (error) {
      print("⚠️ No sent friend request found: $error");
    }

    try {
      final receivedRequestResponse = await Supabase.instance.client
          .from('friend_requests')
          .select()
          .eq('sender_id', widget.userId)
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .limit(1)
          .maybeSingle();

      if (receivedRequestResponse != null) {
        print("✅ Friendship Status: received");
        return 'received';
      }
    } catch (error) {
      print("⚠️ No received friend request found: $error");
    }

    print("✅ Friendship Status: not_friends");
    return 'not_friends';
  }

  Future<void> _cancelFriendRequest() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('friend_requests')
          .delete()
          .eq('sender_id', userId)
          .eq('receiver_id', widget.userId)
          .eq('status', 'pending');

      print("✅ Friend request canceled successfully!");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Friend request canceled!"),
      ));

      setState(() {});
    } catch (error) {
      print("❌ Error canceling friend request: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Error canceling request."),
      ));
    }
  }

  Future<void> _sendFriendRequest() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      print("🔄 Checking for existing friend requests...");

      final existingRequest = await Supabase.instance.client
          .from('friend_requests')
          .select('id')
          .or('and(sender_id.eq.$userId,receiver_id.eq.${widget.userId}),and(sender_id.eq.${widget.userId},receiver_id.eq.$userId))')
          .limit(1)
          .maybeSingle();

      if (existingRequest != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Friend request already exists!")),
        );
        return;
      }

      print("✅ No existing request found. Sending new friend request...");

      await Supabase.instance.client.from('friend_requests').insert({
        'sender_id': userId,
        'receiver_id': widget.userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ Friend request sent successfully!");

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Friend request sent!")),
      );
    } catch (error) {
      print("❌ Error sending friend request: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error sending friend request. Try again!")),
      );
    }
  }

  Future<void> _removeFriend() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('relations')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.${widget.userId}),and(user_id.eq.${widget.userId},friend_id.eq.$userId))');

      if (mounted) {
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Friend removed.")),
      );
    } catch (error) {
      print("❌ Error removing friend: $error");
    }
  }

  Future<void> _acceptFriendRequest() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('friend_requests')
          .delete()
          .eq('sender_id', widget.userId)
          .eq('receiver_id', userId);

      await Supabase.instance.client.from('relations').insert([
        {
          'user_id': userId,
          'friend_id': widget.userId,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'user_id': widget.userId,
          'friend_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎉 You are now friends!")),
      );
    } catch (error) {
      print("❌ Error accepting friend request: $error");
    }
  }

  final List<String> spiritualPaths = [
    "Mystic", "Shaman", "Lightworker", "Astrologer", "Healer", "Diviner"
  ];

  final List<String> elements = [
    "Fire 🔥", "Water 💧", "Earth 🌿", "Air 🌬️", "Spirit 🌌"
  ];
}