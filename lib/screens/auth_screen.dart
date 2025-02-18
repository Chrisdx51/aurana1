import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Correct Import Path for MainScreen

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = true; // Toggle between Sign Up & Login
  bool _isLoading = false; // Track loading state

  // Function to validate email format
  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Function to handle authentication with validation
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
        // 🟢 Try signing up
        response = await supabase.auth.signUp(email: email, password: password);

        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Account Created! You can now log in.")),
          );
          setState(() => _isSignUp = false); // Switch to login mode
        }
      } else {
        // 🟢 Try logging in
        response = await supabase.auth.signInWithPassword(email: email, password: password);

        if (response.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                userName: response.user!.email ?? "Guest",
              ),
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
        setState(() => _isSignUp = false); // Switch to login mode
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
      appBar: AppBar(title: Text(_isSignUp ? "Sign Up" : "Log In")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator() // Show loading when authenticating
                : ElevatedButton(
                    onPressed: _authenticate,
                    child: Text(_isSignUp ? "Sign Up" : "Log In"),
                  ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
