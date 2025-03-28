import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../screens/home_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../../main.dart'; // ✅ Links to MainScreen & NavBar

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

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // ✅ Checks if profile is complete using the right fields
  Future<bool> _isProfileComplete(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('name, bio, dob, city, country, gender, privacy_setting')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return false;

    bool isComplete =
        response['name'] != null && response['name']
            .toString()
            .trim()
            .isNotEmpty &&
            response['bio'] != null && response['bio']
            .toString()
            .trim()
            .isNotEmpty &&
            response['dob'] != null &&
            response['city'] != null && response['city']
            .toString()
            .trim()
            .isNotEmpty &&
            response['country'] != null && response['country']
            .toString()
            .trim()
            .isNotEmpty &&
            response['gender'] != null && response['gender']
            .toString()
            .trim()
            .isNotEmpty &&
            response['privacy_setting'] != null && response['privacy_setting']
            .toString()
            .trim()
            .isNotEmpty;

    return isComplete;
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter both email and password.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage("That doesn't look like a valid email!");
      return;
    }

    if (password.length < 6) {
      _showMessage("Your password needs at least 6 characters.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response;

      if (_isSignUp) {
        response = await supabase.auth.signUp(email: email, password: password);

        if (response.user != null) {
          final String userId = response.user!.id;

          await supabase.from('profiles').insert({
            'id': userId,
            'email': email,
            'name': '',
            'bio': '',
            'dob': null,
            'city': '',
            'country': '',
            'gender': '',
            'privacy_setting': 'public',
            'spiritual_path': '',
            'element': '',
            'soul_match_message': '',
          });

          // ✅ Save FCM token & Subscribe after signup
          await saveFCMToken();
          subscribeToTopics();

          // ✅ Mark user as online & update last_seen after signup
          await supabase.from('profiles').update({
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
          }).eq('id', userId);


          _showMessage("Welcome! Let's complete your profile...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditProfileScreen(
                    userId: userId,
                    forceComplete: true,
                  ),
            ),
          );
        }
      } else {
        response = await supabase.auth.signInWithPassword(
            email: email, password: password);

        if (response.user != null) {
          final String userId = response.user!.id;

          bool profileComplete = await _isProfileComplete(userId);

          // ✅ Save FCM token & Subscribe after login
          await saveFCMToken();
          subscribeToTopics();

          // ✅ Mark user as online & update last_seen after login
          await supabase.from('profiles').update({
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
          }).eq('id', userId);


          if (profileComplete) {
            _showMessage("Welcome back!");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(userId: userId),
              ),
            );
          } else {
            _showMessage("Please finish your profile setup.");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditProfileScreen(
                      userId: userId,
                      forceComplete: true,
                    ),
              ),
            );
          }
        } else {
          _showMessage("Couldn't log you in. Please check your credentials.");
        }
      }
    } on AuthException catch (e) {
      if (e.statusCode == 422 && e.message.contains('user_already_exists')) {
        _showMessage("This email is already registered. Try logging in.");
      } else {
        _showMessage("Oops! ${e.message}");
      }
    } catch (error) {
      _showMessage("Something went wrong. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> saveFCMToken() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    if (token != null) {
      await supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);

      print("✅ FCM Token saved: $token");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/aura.png',
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _typingEffect(),
                  const SizedBox(height: 20),

                  _buildInputField(
                      _emailController, "Email Address", Icons.email),
                  const SizedBox(height: 10),

                  _buildInputField(_passwordController, "Password", Icons.lock,
                      obscureText: true),
                  const SizedBox(height: 20),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.deepPurple.withOpacity(0.8),
                          Colors.white.withOpacity(0.85),
                        ],
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

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? "Already a user? Log In"
                            : "Don't have an account? Sign Up",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildInputField(TextEditingController controller,
      String label,
      IconData icon, {
        bool obscureText = false,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.amberAccent),
        filled: true,
        fillColor: Colors.black.withOpacity(0.4),
        // 👈 transparent black
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}


// ✅ Subscribing to notification topics
void subscribeToTopics() {
  FirebaseMessaging.instance.subscribeToTopic('affirmations');
  FirebaseMessaging.instance.subscribeToTopic('horoscopes');
  FirebaseMessaging.instance.subscribeToTopic('spiritual_gifts');
}
