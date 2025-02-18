import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Ensure correct import path for MainScreen

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false; // Toggle between Sign-Up & Login
  bool _isLoading = false; // Loading indicator

  // Function to validate email format
  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Function to handle authentication
  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Check for empty fields
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter both email and password.")),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter a valid email address.")),
      );
      return;
    }

    // Check password length (Min 6 characters)
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Password must be at least 6 characters long.")),
      );
      return;
    }

    setState(() => _isLoading = true); // Show loading indicator

    try {
      final AuthResponse response;
      if (_isSignUp) {
        // Sign-Up Logic
        response = await supabase.auth.signUp(email: email, password: password);

        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Account Created! Please log in.")),
          );
          setState(() => _isSignUp = false); // Switch to login mode
        }
      } else {
        // Log-In Logic
        response = await supabase.auth.signInWithPassword(email: email, password: password);

        if (response.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(userName: response.user!.email ?? "Guest"),
            ),
          );
        }
      }
    } catch (error) {
      // Check if error is "user already exists"
      if (error.toString().contains("user_already_exists")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Account already exists. Switching to login mode.")),
        );
        setState(() => _isSignUp = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Authentication Error: ${error.toString()}")),
        );
      }
    }

    setState(() => _isLoading = false); // Hide loading indicator
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isSignUp ? "Sign Up" : "Log In"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInputField(_emailController, "Email Address", Icons.email),
            const SizedBox(height: 10),
            _buildInputField(_passwordController, "Password", Icons.lock, obscureText: true),
            const SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A45D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_isSignUp ? "Sign Up" : "Log In"),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 10),

            // Social Logins
            const Divider(),
            const SizedBox(height: 10),
            _buildSocialButton(
              text: "Continue with Google",
              icon: Icons.g_mobiledata,
              color: Colors.redAccent,
              onTap: () {
                print("Google Login");
              },
            ),
            const SizedBox(height: 10),
            _buildSocialButton(
              text: "Continue with Facebook",
              icon: Icons.facebook,
              color: Colors.blue,
              onTap: () {
                print("Facebook Login");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          border: InputBorder.none,
          labelText: label,
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String text, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
