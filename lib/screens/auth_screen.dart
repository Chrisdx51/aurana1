import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../services/supabase_service.dart'; // Import SupabaseService
import '../widgets/animated_background.dart'; // ✅ Import the Animated Background
import 'package:aurana/main.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  final SupabaseService supabaseService = SupabaseService(); // Initialize SupabaseService here

  // 🔥 Validate email format
  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // 🔍 Check if the profile is fully completed
  Future<bool> _isProfileComplete(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('name, bio, dob')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return false;

    // ✅ Force users to complete Name, Bio, and DOB before proceeding
    bool isComplete = response['name'] != null && response['name'].toString().trim().isNotEmpty &&
        response['bio'] != null && response['bio'].toString().trim().isNotEmpty &&
        response['dob'] != null && response['dob'].toString().trim().isNotEmpty;

    print("🔍 Profile Completion Check: $isComplete");
    return isComplete;
  }

  // 🔥 Handle authentication
  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("⚠️ Please enter both email and password.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage("⚠️ Please enter a valid email address.");
      return;
    }

    if (password.length < 6) {
      _showMessage("⚠️ Password must be at least 6 characters long.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response;
      if (_isSignUp) {
        response = await supabase.auth.signUp(email: email, password: password);

        if (response.user != null) {
          final String userId = response.user!.id;

          // ✅ Create an empty profile but force completion later
          await supabase.from('profiles').insert({
            'id': userId,
            'email': email,
            'bio': '',
            'dob': null,
            'name': '', // ✅ Ensure name is empty so they are forced to complete it
          });

          _showMessage("✅ Account Created! Redirecting to Profile Setup...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId, forceComplete: true)),
          );
          return;
        } else {
          _showMessage("⚠️ Failed to create account.");
        }
      } else {
        response = await supabase.auth.signInWithPassword(email: email, password: password);

        if (response.user != null) {
          final String userId = response.user!.id;

          // ✅ Check if profile is complete
          bool profileComplete = await _isProfileComplete(userId);

          // ✅ Save FCM Token
          await saveFCMToken();

          if (profileComplete) {
            // ✅ Redirect to Main Screen (with Navigation Bar)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen(userId: userId)), // ✅ Correct destination
            );
          }
          else {
            // ✅ Redirect to Profile Setup if incomplete
            _showMessage("⚠️ Profile incomplete! Redirecting to Profile Setup...");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId, forceComplete: true)),
            );
          }
        } else {
          _showMessage("⚠️ Invalid login credentials.");
        }
      }
    } catch (error) {
      _showMessage("⚠️ Authentication Error: ${error.toString()}");
    }

    setState(() => _isLoading = false);
  }

  // 🔥 Save FCM Token
  Future<void> saveFCMToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    if (token != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);

      print("✅ FCM Token saved to Supabase: $token");
    }
  }

  // 🔥 Show messages
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📌 Use Optimized Animated Background
          Positioned.fill(child: AnimatedBackground()),

          // 📌 Login Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Typing Effect for "Aurana"
                  _typingEffect(),
                  const SizedBox(height: 20),

                  _buildInputField(_emailController, "Email Address", Icons.email),
                  const SizedBox(height: 10),
                  _buildInputField(_passwordController, "Password", Icons.lock, obscureText: true),
                  const SizedBox(height: 20),

                  // 📌 Gradient Login/Sign-up Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                    width: 200, // ✅ Smaller button width
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.white], // ✅ Blue-to-white gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isSignUp ? "Sign Up" : "Log In",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 📌 Transparent Box for Sign In/Sign Up Toggle
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5), // ✅ Semi-transparent black
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? "Already a user? Log In" : "Don't have an account? Sign Up",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ✅ Typing Effect for "Aurana"
  Widget _typingEffect() {
    return Text(
      "Aurana",
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [Shadow(blurRadius: 10, color: Colors.white)],
      ),
    );
  }

  // ✅ Fixed: Restored missing _buildInputField method
  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

