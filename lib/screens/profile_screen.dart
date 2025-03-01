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

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService supabaseService = SupabaseService();
  UserModel? user;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isProfileComplete = false;
  bool _friendRequestSent = false; // ✅ Track if a friend request is sent
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _spiritualPathController = TextEditingController();
  DateTime? _selectedDOB;
  String? _zodiacSign;
  String? _selectedElement;
  String? _selectedSpiritualPath;
  int _spiritualXP = 0;
  int _spiritualLevel = 1;
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAchievements();
    _checkFriendshipStatus(); // ✅ Ensure button state is set when page loads
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final profile = await supabaseService.getUserProfile(widget.userId);
      if (profile != null) {
        final achievements = await supabaseService.fetchUserAchievements(widget.userId);

        setState(() {
          user = profile;
          _achievements = achievements;
          _nameController.text = profile.name ?? "";
          _bioController.text = profile.bio ?? "";
          if (profile.dob != null) {
            _selectedDOB = DateTime.tryParse(profile.dob!);
            _zodiacSign = _selectedDOB != null ? _getZodiacSign(_selectedDOB!) : null;
          }
          if (profile.spiritualPath != null) {
            _spiritualPathController.text = profile.spiritualPath!;
          }
          if (profile.element != null) {
            _selectedElement = profile.element!;
          }
          _spiritualXP = profile.spiritualXP ?? 0;
          _spiritualLevel = profile.spiritualLevel ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }


  Future<void> _loadAchievements() async {
    if (user == null) return;

    final achievements = await supabaseService.fetchUserAchievements(widget.userId);

    setState(() {
      _achievements = achievements;
    });

    print("✅ Achievements loaded: ${_achievements.length}");
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

  Future<void> _pickDate() async {
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
        DateFormat('yyyy-MM-dd').format(pickedDate),
        user?.icon ?? '',
        _spiritualPathController.text,
        _selectedElement,
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

  Future<bool> _updateProfile() async {
    if (user == null) return false;
    bool success = await supabaseService.updateUserProfile(
      widget.userId,
      _nameController.text,
      _bioController.text,
      _selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : null,
      user?.icon ?? '',
      _spiritualPathController.text,
      _selectedElement,
      _spiritualXP,
      _spiritualLevel,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Profile updated successfully!"),
            duration: Duration(seconds: 0), // ⏳ Show message for only 1 second
          )
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update profile. Try again!")),
      );
      return false;
    }
  }

  Future<void> _checkProfileCompletion() async {
    bool complete = await supabaseService.isProfileComplete(widget.userId);
    setState(() {
      _isProfileComplete = complete;
    });

    if (complete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userId: widget.userId)),
      );
    }
  }

  Future<void> _saveProfileAndUnlockNav() async {
    bool success = await _updateProfile();
    if (success) {
      await _checkProfileCompletion();

      // ✅ Corrected: Pass the userId when navigating
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userId: widget.userId)),
      );
    }
  }

  void_checkLevelUp() {
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
            ? Text("No achievements unlocked yet. Keep growing! 🌟", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic))
            : Column(
          children: _achievements.map((achievement) {
            return Card(
              color: Colors.white.withOpacity(0.8), // ✅ Transparent background
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    // 🏆 GIF Icon at the Top
                    achievement['icon_url'] != null
                        ? Image.network(
                      achievement['icon_url'],
                      width: 80, // ✅ Adjust size
                      height: 80,
                      fit: BoxFit.contain, // ✅ Proper scaling
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        return child; // ✅ Ensures GIF is animated
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, size: 50, color: Colors.red);
                      },
                    )
                        : Icon(Icons.emoji_events, color: Colors.amber, size: 50),

                    SizedBox(height: 10), // Space between image and text

                    // 📝 Title
                    Text(
                      achievement['title'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 5),

                    // 📜 Description
                    Text(
                      achievement['description'],
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8),

                    // 📆 Date Earned
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.parse(achievement['earned_at'])),
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
            child: Expanded(  // ✅ Fix: Wrap Column in Expanded
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.userId == Supabase.instance.client.auth.currentUser?.id
                      ? _changeProfilePicture  // ✅ Only allow profile owner to change
                      : null,  // ❌ Disable clicking for visitors
                  child: Stack(
                  alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: widget.userId == Supabase.instance.client.auth.currentUser?.id
                            ? Colors.white // ✅ No border for own profile
                            : Colors.blueAccent, // ✅ Blue border for friends' profiles
                        child: CircleAvatar(
                          radius: 60, // ✅ Inner Avatar (smaller to allow border effect)
                          backgroundImage: (user?.icon != null && user!.icon!.isNotEmpty && user!.icon!.startsWith('http'))
                              ? NetworkImage(user!.icon!)
                              : AssetImage('assets/default_avatar.png') as ImageProvider,
                        ),
                      ),

                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Icon(Icons.camera_alt, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),
                Column(
                  children: [
                    // 🔹 Friend Request Button
                    FutureBuilder<String>(
                      future: _checkFriendshipStatus(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return CircularProgressIndicator();
                        final status = snapshot.data!;
                        final currentUserId = Supabase.instance.client.auth.currentUser?.id;

                        if (widget.userId == currentUserId) {
                          return SizedBox();  // ✅ Don't show friend buttons on own profile
                        }

                        print("🛠 Friendship Status in UI: $status"); // Debugging log

                        return Column(
                          children: [
                            if (status == "not_friends") // ✅ Show Add Friend Button
                              ElevatedButton(
                                onPressed: () async {
                                  await _sendFriendRequest();
                                  setState(() {}); // ✅ Refresh UI
                                },
                                child: Text("Add Friend"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),

                            if (status == "sent") // ✅ Show Cancel Friend Request Button
                              ElevatedButton(
                                onPressed: () async {
                                  await _cancelFriendRequest();
                                  setState(() {}); // ✅ Refresh UI
                                },
                                child: Text("Cancel Request ❌"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),

                            if (status == "received") // ✅ Show Accept Friend Request Button
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
                                      setState(() {}); // ✅ Refresh UI
                                    },
                                    child: Text("Accept Friend Request ✅"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                            if (status == "friends") // ✅ Show Remove Friend Button
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
                                      setState(() {}); // ✅ Refresh UI after removing friend
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

                        // 🚫 Hide friends list for visitors
                        if (widget.userId != currentUserId) {
                          return SizedBox(); // Hide friends for visitors
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
                              height: 120, // ✅ Adjusted height
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: friends.length,
                                itemBuilder: (context, index) {
                                  final friend = friends[index];
                                  return GestureDetector(
                                    onTap: () {
                                      // ✅ Navigate to friend's profile when tapped
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
                                            radius: 40, // ✅ Larger profile image
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
                // ✅ Only allow editing if the logged-in user is viewing their own profile
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
                  SizedBox(height: 20),

                  // ✅ Only show Save Button to profile owner
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("⚠️ Please enter your name before saving."))
                        );
                        return;
                      }

                      bool success = await _updateProfile();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ Profile updated successfully!"))
                        );
                        setState(() {}); // ✅ Stay on the profile page instead of redirecting
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
                ], // ✅ End of check for profile owner

// ✅ Show information for visitors (only viewable, not editable)
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
                ],

               // ✅ Show achievements for everyone
                Column(
                  children: [
                    SizedBox(height: 20),
                    _buildAchievementsSection(),
                  ],
                ),
              ],
            ),
          ),
        ),

      ),
    )
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
              'icon': friendProfile.icon, // ✅ Get profile picture
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
//✅ Check if a friend request is already sent or accepted
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
        return 'sent'; // ✅ Mark as request sent
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

      setState(() {}); // ✅ Refresh UI after canceling
    } catch (error) {
      print("❌ Error canceling friend request: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Error canceling request."),
      ));
    }
  }

  // ✅ Send Friend Request
  // ✅ FIXED: Send Friend Request
  Future<void> _sendFriendRequest() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      print("🔄 Checking for existing friend requests...");

      // ✅ FIXED: Ensure no duplicate requests
      final existingRequest = await Supabase.instance.client
          .from('friend_requests')
          .select('id')
          .or('and(sender_id.eq.$userId,receiver_id.eq.${widget.userId}),and(sender_id.eq.${widget.userId},receiver_id.eq.$userId))')
          .limit(1)
          .maybeSingle(); // ✅ Prevents crashes if no rows are found

      if (existingRequest != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Friend request already exists!")),
        );
        return;
      }

      print("✅ No existing request found. Sending new friend request...");

      // ✅ FIXED: Insert Friend Request
      await Supabase.instance.client.from('friend_requests').insert({
        'sender_id': userId,
        'receiver_id': widget.userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ Friend request sent successfully!");

      // ✅ Refresh UI
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

  // ✅ Remove Friend
  Future<void> _removeFriend() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // ✅ Remove friendship from relations table
      await Supabase.instance.client
          .from('relations')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.${widget.userId}),and(user_id.eq.${widget.userId},friend_id.eq.$userId))');

      if (mounted) {
        setState(() {}); // ✅ Refresh UI
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Friend removed.")),
      );
    } catch (error) {
      print("❌ Error removing friend: $error");
    }
  }

  // ✅ Accept Friend Request
  Future<void> _acceptFriendRequest() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // ✅ Delete the friend request
      await Supabase.instance.client
          .from('friend_requests')
          .delete()
          .eq('sender_id', widget.userId)
          .eq('receiver_id', userId);

      // ✅ Insert into relations table (make both users friends)
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

      // ✅ Refresh UI
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
