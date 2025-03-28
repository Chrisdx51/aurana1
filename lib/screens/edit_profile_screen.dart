import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart'; // Your main screen
import 'package:profanity_filter/profanity_filter.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  DateTime? _dob;
  String? _zodiacSign;
  bool _isLoading = true;
  String userRole = 'user'; // default, will update during profile load

  final genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final spiritualPaths = [
    'Mystic',
    'Shaman',
    'Lightworker',
    'Astrologer',
    'Healer'
  ];
  final elements = ['Fire', 'Water', 'Earth', 'Air', 'Spirit'];
  final privacyOptions = ['public', 'friends_only', 'private'];
  final displayNameOptions = ['real_name', 'username'];

  final List<String> countries = [
    'United Kingdom',
    'United States',
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Argentina',
    'Australia',
    'Austria',
    'Bangladesh',
    'Belgium',
    'Brazil',
    'Canada',
    'China',
    'Colombia',
    'Croatia',
    'Denmark',
    'Egypt',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'Hungary',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Kenya',
    'Malaysia',
    'Mexico',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Pakistan',
    'Philippines',
    'Poland',
    'Portugal',
    'Russia',
    'Saudi Arabia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Sweden',
    'Switzerland',
    'Thailand',
    'Turkey',
    'Ukraine',
    'United Arab Emirates',
    'Vietnam',
    'Zimbabwe',
  ];

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

      userRole = userProfile['role'] ?? 'user';

      print("✅ Profile loaded: $userProfile");

      setState(() {
        _nameController.text = userProfile['name'] ?? '';
        _usernameController.text = userProfile['username'] ?? '';
        _bioController.text = userProfile['bio'] ?? '';
        _cityController.text = userProfile['city'] ?? '';
        _countryController.text = userProfile['country'] ?? '';
        _soulMatchMessageController.text =
            userProfile['soul_match_message'] ?? '';

        _gender = userProfile['gender'];
        _spiritualPath = userProfile['spiritual_path'];
        _element = userProfile['element'];
        _privacySetting = userProfile['privacy_setting'] ?? 'public';
        _displayNameChoice = userProfile['display_name_choice'] ?? 'real_name';

        _dob = userProfile['dob'] != null
            ? DateTime.tryParse(userProfile['dob'])
            : null;
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
    final filter = ProfanityFilter();

    String name = _nameController.text.trim().toLowerCase();
    String username = _usernameController.text.trim().toLowerCase();
    String bio = _bioController.text.trim().toLowerCase();

    final blockedWords = [
      'admin',
      'mod',
      'aurana',
      'staff',
      'team',
      'fuck',
      'shit',
      'bitch',
      'ass',
      'dick',
      'piss',
      'cunt',
      'bastard',
      'damn',
      'slut',
      'fag',
      'nigger',
      'whore',
      // add more if needed
    ];

// Custom word check
    bool containsBlockedWord(String input) {
      input = input.toLowerCase();
      return blockedWords.any((word) =>
      input == word || input.contains(word));
    }

// Block profanity or restricted words
    bool isAdminUser = userRole == 'admin' || userRole == 'superadmin';

    if (!isAdminUser) {
      if (filter.hasProfanity(name) ||
          filter.hasProfanity(username) ||
          filter.hasProfanity(bio) ||
          containsBlockedWord(name) ||
          containsBlockedWord(username)) {
        _showMessage(
            '⚠️ Please choose a name and username without bad or restricted words.');
        return;
      }
    }


    if (_nameController.text
        .trim()
        .isEmpty ||
        _usernameController.text
            .trim()
            .isEmpty ||

        _dob == null ||
        _cityController.text
            .trim()
            .isEmpty ||
        _countryController.text
            .trim()
            .isEmpty ||
        _gender == null) {
      _showMessage('⚠️ Please fill all required fields.');
      print("⚠️ Missing required fields. Cannot save.");
      return;
    }

    _showMessage('Saving profile...');
    String? avatarUrl = _existingAvatarUrl;

    if (_imageFile != null) {
      print("🔄 Uploading new avatar...");
      final fileName = '${widget.userId}-${DateTime
          .now()
          .millisecondsSinceEpoch}.png';
      final bytes = await _imageFile!.readAsBytes();

      try {
        final response = await supabase.storage.from('avatar').uploadBinary(
            fileName, bytes);
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
      final latitude = position.latitude;
      final longitude = position.longitude;
      print("✅ Location: $latitude, $longitude");

      // 🔄 Save to Supabase
      await supabase.from('profiles').update({
        'latitude': latitude,
        'longitude': longitude,
      }).eq('id', widget.userId);

      // 🌍 Reverse geocode to get city + country
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json');

      final response = await http.get(url, headers: {
        'User-Agent': 'AuranaApp/1.0' // required by Nominatim
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];

        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            '';
        final country = address['country'] ?? '';

        if (city.isNotEmpty) _cityController.text = city;
        if (country.isNotEmpty) _countryController.text = country;

        _showMessage('📍 Detected: $city, $country');
        print("🎯 Reverse geocoded: $city, $country");
      } else {
        _showMessage('⚠️ Could not detect city/country.');
        print('❌ Failed to reverse geocode. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error detecting location: $e");
      _showMessage('❌ Failed to detect location.');
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
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21))
      return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21))
      return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19))
      return "Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18))
      return "Aquarius";
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
          title: Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            // ✨ Background Image
            Positioned.fill(
              child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover),
            ),

            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BannerAdWidget(),
                  SizedBox(height: 16),
                  // Avatar Picker with Glow
                  GestureDetector(
                    onTap: _pickImage,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_existingAvatarUrl != null
                                  ? NetworkImage(_existingAvatarUrl!)
                                  : AssetImage(
                                  'assets/images/default_avatar.png')) as ImageProvider,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.camera_alt, color: Colors.white,
                                  size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Username Field
                  _buildTextField('Username*', _usernameController),
                  _buildTextField('Name*', _nameController),
                  _buildTextField('Bio', _bioController, maxLines: 3),

                  _buildDropdownField('Gender*', _gender, genders, (val) =>
                      setState(() => _gender = val)),
                  _buildDropdownField(
                      'Spiritual Path', _spiritualPath, spiritualPaths, (val) =>
                      setState(() => _spiritualPath = val)),
                  _buildDropdownField('Element', _element, elements, (val) =>
                      setState(() => _element = val)),

                  _buildDatePickerField(),

                  _buildTextField('City*', _cityController),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 12),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap the Auto-detect button below to automatically fill in your city and country.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),



                  _buildDropdownField(
                    'Country*',
                    countries.contains(_countryController.text)
                        ? _countryController.text
                        : null,
                    countries,
                        (val) =>
                        setState(() => _countryController.text = val ?? ''),
                  ),
                  _buildTextField(
                      'Soul Match Message', _soulMatchMessageController),

                  _buildDropdownField(
                      'Soul Privacy', _privacySetting, privacyOptions, (val) =>
                      setState(() => _privacySetting = val!)),
                  _buildDropdownField(
                      'Display Name', _displayNameChoice, displayNameOptions, (
                      val) => setState(() => _displayNameChoice = val!)),

                  SizedBox(height: 20),

                  // Detect Location Button
                  ElevatedButton.icon(
                    onPressed: _detectLocation,
                    icon: Icon(Icons.location_on),
                    label: Text('Auto-detect Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Save Button with Glow
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save Changes', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      shadowColor: Colors.tealAccent,
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),

      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (label.toLowerCase().contains('bio'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Write a little about yourself...',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildDropdownField(String label,
      String? value,
      List<String> options,
      ValueChanged<String?> onChanged, {
        String? helperText,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: options.contains(value) ? value : null,
              icon: Icon(Icons.expand_more, color: Colors.white),
              dropdownColor: Colors.deepPurple.shade900,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                helperText,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date of Birth*',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
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
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dob != null
                        ? '${_dob!.year}-${_dob!.month.toString().padLeft(
                        2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
                        : 'Select Date of Birth',
                    style: TextStyle(color: Colors.white),
                  ),
                  Icon(Icons.calendar_today, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

