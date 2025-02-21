import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../main.dart';
import 'auth_screen.dart';
import 'package:intl/intl.dart';

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
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  DateTime? _selectedDOB;
  String? _zodiacSign;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 🔥 Fetch User Profile
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final profile = await supabaseService.getUserProfile(widget.userId);
      if (profile != null) {
        setState(() {
          user = profile;
          _nameController.text = profile.name ?? "";
          _bioController.text = profile.bio ?? "";
          if (profile.dob != null) {
            _selectedDOB = DateTime.tryParse(profile.dob!);
            _zodiacSign = _selectedDOB != null ? _getZodiacSign(_selectedDOB!) : null;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      print("❌ Error fetching profile: $error");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // 🔥 Pick and Upload Profile Picture (Auto-Save)
  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    File imageFile = File(image.path);
    final imageUrl = await supabaseService.uploadProfilePicture(widget.userId, imageFile);

    if (imageUrl != null) {
      await supabaseService.updateUserProfilePicture(widget.userId, imageUrl);
      setState(() {
        user = user?.copyWith(icon: imageUrl);
      });
    }
  }

  // 🔥 Log Out Function
  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
  }

  // 🔥 Date Picker for DOB
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
    }
  }

  // 🔥 Get Zodiac Sign from DOB
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20), // ✅ Added space for ad banner
                GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.icon != null && user!.icon!.isNotEmpty
                            ? NetworkImage(user!.icon!)
                            : AssetImage('assets/spiritual_avatar.png') as ImageProvider, // ✅ Spiritual-style default image
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildBubbleField("Name", _nameController, Icons.person),
                SizedBox(height: 10),
                _buildBubbleField("Bio", _bioController, Icons.book),
                SizedBox(height: 10),
                _buildBubbleField(
                  "Date of Birth",
                  TextEditingController(text: _selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : "Not Set"),
                  Icons.calendar_today,
                  isReadOnly: true,
                  onTap: _pickDate,
                ),
                SizedBox(height: 10),
                _buildBubbleText(_zodiacSign ?? "Not Set", Icons.star),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleField(String label, TextEditingController controller, IconData icon,
      {bool isReadOnly = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                readOnly: isReadOnly,
                decoration: InputDecoration(border: InputBorder.none),
                controller: controller,
              ),
            ),
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
}
