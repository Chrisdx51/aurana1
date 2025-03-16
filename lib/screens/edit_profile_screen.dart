import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart'; // Your main screen

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final bool forceComplete;

  const EditProfileScreen({
    required this.userId,
    this.forceComplete = false,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  File? _imageFile;
  String? _existingAvatarUrl;

  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _soulMatchMessageController = TextEditingController();

  String? _gender;
  String? _spiritualPath;
  String? _element;
  String _privacySetting = 'public';
  String _displayNameChoice = 'real_name';
  String _journeyVisibility = 'public'; // Soul Journey visibility
  DateTime? _dob;
  String? _zodiacSign;
  bool _isLoading = true;

  final genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final spiritualPaths = ['Mystic', 'Shaman', 'Lightworker', 'Astrologer', 'Healer'];
  final elements = ['Fire', 'Water', 'Earth', 'Air', 'Spirit'];
  final privacyOptions = ['public', 'friends_only', 'private'];
  final displayNameOptions = ['real_name', 'username'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      print("🔄 Loading profile for user: ${widget.userId}");
      final userProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (userProfile == null) {
        print("⚠️ Profile not found in Supabase.");
        _showMessage('⚠️ Profile not found.');
        setState(() => _isLoading = false);
        return;
      }

      print("✅ Profile loaded: $userProfile");

      setState(() {
        _nameController.text = userProfile['name'] ?? '';
        _usernameController.text = userProfile['username'] ?? '';
        _bioController.text = userProfile['bio'] ?? '';
        _cityController.text = userProfile['city'] ?? '';
        _countryController.text = userProfile['country'] ?? '';
        _soulMatchMessageController.text = userProfile['soul_match_message'] ?? '';

        _gender = userProfile['gender'];
        _spiritualPath = userProfile['spiritual_path'];
        _element = userProfile['element'];
        _privacySetting = userProfile['privacy_setting'] ?? 'public';
        _displayNameChoice = userProfile['display_name_choice'] ?? 'real_name';
        _journeyVisibility = userProfile['journey_visibility'] ?? 'public';

        _dob = userProfile['dob'] != null ? DateTime.tryParse(userProfile['dob']) : null;
        _zodiacSign = _dob != null ? _getZodiacSign(_dob!) : null;

        _existingAvatarUrl = userProfile['avatar'];

        _isLoading = false;
      });
    } catch (e) {
      print('❌ Exception loading profile: $e');
      _showMessage('❌ Failed to load profile.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      print("🖼️ Picking new image...");
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print("✅ Image picked: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Failed to pick image: $e");
    }
  }

  Future<void> _saveProfile() async {
    print("🔨 Saving profile...");

    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _dob == null ||
        _cityController.text.trim().isEmpty ||
        _countryController.text.trim().isEmpty ||
        _gender == null) {
      _showMessage('⚠️ Please fill all required fields.');
      print("⚠️ Missing required fields. Cannot save.");
      return;
    }

    _showMessage('Saving profile...');
    String? avatarUrl = _existingAvatarUrl;

    if (_imageFile != null) {
      print("🔄 Uploading new avatar...");
      final fileName = '${widget.userId}-${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = await _imageFile!.readAsBytes();

      try {
        final response = await supabase.storage.from('avatar').uploadBinary(fileName, bytes);
        avatarUrl = supabase.storage.from('avatar').getPublicUrl(fileName);
        print("✅ Avatar uploaded successfully: $avatarUrl");
      } catch (e) {
        print("❌ Failed to upload avatar: $e");
        _showMessage('❌ Avatar upload failed.');
      }
    }

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'display_name_choice': _displayNameChoice,
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'gender': _gender,
        'privacy_setting': _privacySetting,
        'journey_visibility': _journeyVisibility,
        'dob': _dob!.toIso8601String(),
        'spiritual_path': _spiritualPath,
        'element': _element,
        'soul_match_message': _soulMatchMessageController.text.trim(),
        'avatar': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print("📦 Updates payload: $updates");

      final response = await supabase
          .from('profiles')
          .update(updates)
          .eq('id', widget.userId)
          .select();

      print("✅ Profile update response: $response");

      if (response == null || response.isEmpty) {
        print("❌ Update returned empty response.");
        _showMessage('❌ Failed to save profile.');
        return;
      }

      _showMessage('✅ Profile saved!');

      if (widget.forceComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(userId: widget.userId)),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Exception saving profile: $e");
      _showMessage('❌ Failed to save profile.');
    }
  }

  Future<void> _detectLocation() async {
    print("📍 Detecting location...");
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('⚠️ Enable location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('⚠️ Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      print("✅ Location detected: ${position.latitude}, ${position.longitude}");

      await supabase.from('profiles').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }).eq('id', widget.userId);

      _showMessage('📍 Location updated!');
    } catch (e) {
      print("❌ Failed to detect/update location: $e");
      _showMessage('❌ Failed to update location.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
      ),
    );
  }

  String _getZodiacSign(DateTime dob) {
    int day = dob.day;
    int month = dob.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
    return "Pisces";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.forceComplete) {
          _showMessage('⚠️ Please complete your profile.');
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade200, Colors.white],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover),
            ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_existingAvatarUrl != null
                              ? NetworkImage(_existingAvatarUrl!)
                              : AssetImage('assets/images/default_avatar.png'))
                          as ImageProvider,
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField('Username*', _usernameController),
                  _buildTextField('Name*', _nameController),
                  _buildTextField('Bio', _bioController, maxLines: 3),
                  _buildDropdownField('Gender*', _gender, genders, (val) => setState(() => _gender = val)),
                  _buildDropdownField('Spiritual Path', _spiritualPath, spiritualPaths, (val) => setState(() => _spiritualPath = val)),
                  _buildDropdownField('Element', _element, elements, (val) => setState(() => _element = val)),
                  _buildDatePickerField(),
                  _buildTextField('City*', _cityController),
                  _buildTextField('Country*', _countryController),
                  _buildTextField('Soul Match Message', _soulMatchMessageController),
                  _buildDropdownField('Privacy', _privacySetting, privacyOptions, (val) => setState(() => _privacySetting = val!)),
                  _buildDropdownField('Journey Visibility', _journeyVisibility, privacyOptions, (val) => setState(() => _journeyVisibility = val!)),
                  _buildDropdownField('Display Name', _displayNameChoice, displayNameOptions, (val) => setState(() => _displayNameChoice = val!)),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _detectLocation,
                    icon: Icon(Icons.location_on),
                    label: Text('Auto-detect Location'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save Changes'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        tileColor: Colors.white.withOpacity(0.8),
        title: Text(
          _dob != null ? 'DOB: ${_dob!.toLocal().toIso8601String().substring(0, 10)}' : 'Select Date of Birth',
        ),
        trailing: Icon(Icons.calendar_today),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _dob ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _dob = picked;
              _zodiacSign = _getZodiacSign(picked);
            });
          }
        },
      ),
    );
  }
}
