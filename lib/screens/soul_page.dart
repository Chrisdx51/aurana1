import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SoulPage extends StatefulWidget {
  @override
  _SoulPageState createState() => _SoulPageState();
}

class _SoulPageState extends State<SoulPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _realNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _zodiacController = TextEditingController();

  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response != null && response is Map<String, dynamic>) {
      setState(() {
        _realNameController.text = response['real_name'] ?? '';
        _nicknameController.text = response['nickname'] ?? '';
        _bioController.text = response['bio'] ?? '';
        _dobController.text = response['dob'] ?? '';
        _zodiacController.text = response['zodiac'] ?? '';
        _profileImageUrl = response['profile_pic'];
      });
    }
  }

  Future<void> _updateProfileImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final filePath = 'profile_pictures/${user.id}.$fileExt';

      await supabase.storage.from('profile_pictures').upload(
        filePath, file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(filePath);

      setState(() {
        _profileImageUrl = imageUrl;
        _profileImage = file;
      });

      await supabase.from('profiles').update({'profile_pic': imageUrl}).eq('id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Profile Image Updated Successfully!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Image Upload Error: $error")),
      );
    }
  }

  Future<void> _saveUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'real_name': _realNameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(),
        'dob': _dobController.text.trim(),
        'zodiac': _zodiacController.text.trim(),
        'profile_pic': _profileImageUrl ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Profile Saved Successfully!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error Saving: $error")),
      );
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Soul Form",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 20), // ✅ Adds space between image & first input box
                  _buildInputField(_realNameController, "Real Name", Icons.person),
                  _buildInputField(_nicknameController, "Soul Name", Icons.star),
                  _buildInputField(_bioController, "Spiritual Bio", Icons.book),
                  _buildInputField(_dobController, "Date of Birth", Icons.cake),
                  _buildInputField(_zodiacController, "Zodiac Sign", Icons.wb_sunny),
                  const SizedBox(height: 15),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900,
            Colors.blue.shade800,
            Colors.teal.shade700,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: GestureDetector(
        onTap: _updateProfileImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60, // ✅ Bigger profile picture
              backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
              backgroundColor: Colors.grey.shade200,
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.shade400,
              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 6), // ✅ Smaller fields
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6), // ✅ Smaller form box
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple.shade700, size: 18), // ✅ Smaller icon
          SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 13), // ✅ Smaller text inside field
              decoration: InputDecoration(labelText: label, border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: 120, // ✅ Smaller button
          height: 34,
          child: ElevatedButton.icon(
            onPressed: _saveUserProfile,
            icon: Icon(Icons.save, size: 14),
            label: Text("Save", style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120, // ✅ Smaller button
          height: 34,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout, size: 14),
            label: Text("Log Out", style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }
}
