import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../main.dart';
import 'auth_screen.dart';

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
  final TextEditingController _spiritualPathController = TextEditingController();
  DateTime? _selectedDOB;
  String? _zodiacSign;
  String? _selectedElement;
  String? _selectedSpiritualPath;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

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
          if (profile.spiritualPath != null) {
            _spiritualPathController.text = profile.spiritualPath!;
          }
          if (profile.element != null) {
            _selectedElement = profile.element!;
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
          _selectedElement
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

  Future<void> _updateProfile() async {
    if (user == null) return;

    bool success = await supabaseService.updateUserProfile(
        widget.userId,
        _nameController.text,
        _bioController.text,
        _selectedDOB != null ? DateFormat('yyyy-MM-dd').format(_selectedDOB!) : null,
        user?.icon ?? '',
        _spiritualPathController.text,
        _selectedElement
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Profile updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update profile. Try again!")),
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
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
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
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(color: Colors.black)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.icon != null && user!.icon!.isNotEmpty
                            ? NetworkImage(user!.icon!)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Icon(Icons.camera_alt, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildBubbleField("Your Spiritual Name", _nameController, FontAwesomeIcons.sun, "Enter your sacred name"),
                SizedBox(height: 10),
                _buildBubbleField("Tell us about you", _bioController, FontAwesomeIcons.moon, "What brings you here?"),
                SizedBox(height: 10),

                // 🔥 Spiritual Path Dropdown
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

                // 🌍 Element Dropdown
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

                SizedBox(height: 10),
                _buildBubbleDateField("Your Birth Date", _selectedDOB, _pickDate),
                SizedBox(height: 10),
                _buildBubbleText(_zodiacSign ?? "Not Set", FontAwesomeIcons.galacticRepublic),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// List of spiritual paths (Modify as needed)
final List<String> spiritualPaths = [
  "Mystic", "Shaman", "Lightworker", "Astrologer", "Healer", "Diviner"
];

// List of elements (Modify as needed)
final List<String> elements = [
  "Fire 🔥", "Water 💧", "Earth 🌍", "Air 🌬️", "Spirit ✨"
];