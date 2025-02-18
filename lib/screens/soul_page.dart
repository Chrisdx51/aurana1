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

  File? _profileImage;
  String? _profileImageUrl;
  List<String> selectedInterests = [];

  final List<String> interests = [
    'Meditation', 'Tarot', 'Astrology', 'Energy Healing',
    'Mindfulness', 'Law of Attraction', 'Reading', 'Music',
    'Fitness', 'Cooking', 'Traveling', 'Technology', 'Gaming',
  ];

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
        _profileImageUrl = response['profile_pic'];
        selectedInterests = (response['interests'] as List<dynamic>?)
                ?.map((i) => i.toString())
                .toList() ??
            [];
      });
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
        'profile_pic': _profileImageUrl ?? '',
        'interests': selectedInterests,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Soul Page Saved!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error Saving: $error")),
      );
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

      await _saveUserProfile();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Image Upload Error: $error")),
      );
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
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
                  _buildProfileHeader(),
                  _buildBoxedTextField(_realNameController, "Real Name"),
                  _buildBoxedTextField(_nicknameController, "Soul Name"),
                  _buildBoxedTextField(_bioController, "Spiritual Bio"),
                  _buildDatePicker(),
                  _buildInterestSelector(),
                  const SizedBox(height: 20),
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
          colors: [Colors.deepPurple.shade700, Colors.black],
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
        child: CircleAvatar(
          radius: 70,
          backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
          backgroundColor: Colors.deepPurple.shade200,
          child: _profileImageUrl == null ? Icon(Icons.person, size: 50, color: Colors.white) : null,
        ),
      ),
    );
  }

  Widget _buildBoxedTextField(TextEditingController controller, String label) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  Widget _buildDatePicker() {
    return _buildBoxedTextField(_dobController, "Date of Birth");
  }

  Widget _buildInterestSelector() {
    return Wrap(
      spacing: 8,
      children: interests.map((interest) {
        final bool isSelected = selectedInterests.contains(interest);
        return ChoiceChip(
          label: Text(interest),
          selected: isSelected,
          selectedColor: Colors.deepPurpleAccent,
          onSelected: (selected) {
            setState(() {
              selected ? selectedInterests.add(interest) : selectedInterests.remove(interest);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _saveUserProfile,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("Save Your Soul Page", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Log Out", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
