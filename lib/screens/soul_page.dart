import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SoulPage extends StatefulWidget {
  final String userId; // User's unique ID
  const SoulPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SoulPageState createState() => _SoulPageState();
}

class _SoulPageState extends State<SoulPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  Color? headerColor;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      print("Fetching profile for user ID: ${widget.userId}"); // Debugging: Print User ID

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      print("Supabase Response: $response"); // Debugging: Print Raw Supabase Response

      if (response != null) {
        setState(() {
          userProfile = response;
          headerColor = Color(int.parse(userProfile?['background_color'] ?? '0xFF673AB7')); // Default purple
          isLoading = false;
        });
      } else {
        print("⚠️ No profile data found for this user.");
        setState(() {
          isLoading = false; // Stop loading, show an error
        });
      }
    } catch (error) {
      print("❌ Supabase Error: $error"); // Debugging: Print error if any
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark spiritual theme
      body: Column(
        children: [
          // Profile Header with Background Color
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: headerColor ?? Colors.purple,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userProfile?['profile_pic'] ?? ''),
                ),
              ),
            ],
          ),

          const SizedBox(height: 50), // Push content below profile picture

          // User Details
          Text(
            userProfile?['real_name'] ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "@${userProfile?['nickname'] ?? ''}",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),

          // Bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              userProfile?['bio'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons (Like & Friend Request)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton("🌟 Like"),
              const SizedBox(width: 10),
              _actionButton("🔮 Friend Request"),
            ],
          ),

          const SizedBox(height: 30),

          // Profile Info (DOB, Followers)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoCard("Born", userProfile?['dob'] ?? ''),
              _infoCard("Soulmates", userProfile?['soulmate_count'].toString() ?? '0'),
              _infoCard("Following", userProfile?['following_count'].toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  // Custom Button
  Widget _actionButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
    );
  }

  // Profile Info Card
  Widget _infoCard(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}