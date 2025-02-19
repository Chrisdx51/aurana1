import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SoulPage extends StatefulWidget {
  final String userId;
  const SoulPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SoulPageState createState() => _SoulPageState();
}

class _SoulPageState extends State<SoulPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isCurrentUser = false;
  Color? headerColor;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      final currentUserId = supabase.auth.currentUser?.id;

      if (response != null) {
        setState(() {
          userProfile = response;
          headerColor = Color(int.parse(userProfile?['background_color'] ?? '0xFF673AB7'));
          isCurrentUser = widget.userId == currentUserId; // Check if it's the current user's profile
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (error) {
      print("❌ Supabase Error: $error");
      setState(() => isLoading = false);
    }
  }

  Future<void> uploadProfilePicture() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final file = File(pickedFile.path);
      final fileName = "profile_pics/${widget.userId}.jpg";

      await supabase.storage.from('avatars').upload(fileName, file);
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase.from('profiles').update({'profile_pic': imageUrl}).eq('id', widget.userId);

      setState(() {
        userProfile?['profile_pic'] = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Profile picture updated!")));
    } catch (error) {
      print("❌ Error uploading profile picture: $error");
    }
  }

  Future<void> editProfile() async {
    final TextEditingController nameController = TextEditingController(text: userProfile?['real_name'] ?? '');
    final TextEditingController nicknameController = TextEditingController(text: userProfile?['nickname'] ?? '');
    final TextEditingController bioController = TextEditingController(text: userProfile?['bio'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Real Name")),
            TextField(controller: nicknameController, decoration: const InputDecoration(labelText: "Nickname")),
            TextField(controller: bioController, decoration: const InputDecoration(labelText: "Bio")),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await supabase.from('profiles').update({
                  'real_name': nameController.text,
                  'nickname': nicknameController.text,
                  'bio': bioController.text,
                }).eq('id', widget.userId);

                setState(() {
                  userProfile?['real_name'] = nameController.text;
                  userProfile?['nickname'] = nicknameController.text;
                  userProfile?['bio'] = bioController.text;
                });

                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [headerColor ?? Colors.purple, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -45,
                  child: GestureDetector(
                    onTap: isCurrentUser ? uploadProfilePicture : null,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.black,
                      backgroundImage: userProfile?['profile_pic'] != null && userProfile?['profile_pic'].isNotEmpty
                          ? NetworkImage(userProfile?['profile_pic']!)
                          : null,
                      child: userProfile?['profile_pic'] == null || userProfile?['profile_pic'].isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            Text(userProfile?['real_name'] ?? 'No Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(userProfile?['nickname'] ?? 'No Nickname', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(userProfile?['bio'] ?? 'No bio available.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => print("✅ Profile Liked!"),
              child: const Text("🌟 Like"),
            ),

            if (!isCurrentUser)
              ElevatedButton(
                onPressed: () => print("✅ Friend Request Sent!"),
                child: const Text("🔮 Send Friend Request"),
              ),

            if (isCurrentUser)
              ElevatedButton(
                onPressed: editProfile,
                child: const Text("✏️ Edit Profile"),
              ),
          ],
        ),
      ),
    );
  }
}
