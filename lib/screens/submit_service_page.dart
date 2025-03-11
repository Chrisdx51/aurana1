import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'payment_page.dart';

class SubmitYourServicePage extends StatefulWidget {
  @override
  _SubmitYourServicePageState createState() => _SubmitYourServicePageState();
}

class _SubmitYourServicePageState extends State<SubmitYourServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  String name = '';
  String businessName = '';
  String serviceType = 'Psychic';
  String tagline = '';
  String description = '';
  String price = '';
  String phoneNumber = '';
  bool offersFreeService = false;
  bool showProfile = true;

  File? _selectedImage;
  Map<String, dynamic>? _existingAd;

  @override
  void initState() {
    super.initState();
    _loadExistingAd();
  }

  Future<void> _loadExistingAd() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final ad = await _supabase
        .from('service_ads')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (ad != null) {
      setState(() {
        _existingAd = ad;
        // Pre-fill the form with existing ad data
        name = ad['name'] ?? '';
        businessName = ad['business_name'] ?? '';
        serviceType = ad['service_type'] ?? 'Psychic';
        tagline = ad['tagline'] ?? '';
        description = ad['description'] ?? '';
        price = ad['price'] ?? '';
        phoneNumber = ad['phone_number'] ?? '';
        showProfile = ad['show_profile'] ?? true;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must be logged in!')));
      return;
    }

    String? imageUrl = _existingAd != null ? _existingAd!['profile_image_url'] : null;

    // Upload new image if selected
    if (_selectedImage != null) {
      final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}_${name}.png';
      await _supabase.storage.from('ads').upload(
        fileName,
        _selectedImage!,
        fileOptions: FileOptions(upsert: true),
      );
      imageUrl = _supabase.storage.from('ads').getPublicUrl(fileName);
    }

    final expiryDate = DateTime.now().add(Duration(days: 90)).toIso8601String();

    if (_existingAd == null) {
      // Create new ad
      await _supabase.from('service_ads').insert({
        'user_id': userId,
        'name': name,
        'business_name': businessName,
        'service_type': serviceType,
        'tagline': tagline,
        'description': description,
        'price': offersFreeService ? 'Free' : price,
        'phone_number': phoneNumber,
        'profile_image_url': imageUrl ?? '',
        'show_profile': showProfile,
        'expiry_date': expiryDate,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing ad
      await _supabase.from('service_ads').update({
        'name': name,
        'business_name': businessName,
        'service_type': serviceType,
        'tagline': tagline,
        'description': description,
        'price': offersFreeService ? 'Free' : price,
        'phone_number': phoneNumber,
        'profile_image_url': imageUrl ?? '',
        'show_profile': showProfile,
        'expiry_date': expiryDate,
      }).eq('id', _existingAd!['id']);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎉 Your ad was successfully saved!'),
      backgroundColor: Colors.green,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaymentPage()));
  }

  Future<void> _deleteAd() async {
    if (_existingAd == null) return;

    await _supabase.from('service_ads').delete().eq('id', _existingAd!['id']);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🗑️ Your ad has been deleted.'),
      backgroundColor: Colors.red,
    ));

    setState(() {
      _existingAd = null;
      name = '';
      businessName = '';
      serviceType = 'Psychic';
      tagline = '';
      description = '';
      price = '';
      phoneNumber = '';
      showProfile = true;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Your Service'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  _existingAd == null
                      ? 'Advertise Your Spiritual Service'
                      : 'Edit Your Service Ad',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),

                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white24,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_existingAd != null &&
                            _existingAd!['profile_image_url'] != null &&
                            _existingAd!['profile_image_url'].isNotEmpty)
                            ? NetworkImage(_existingAd!['profile_image_url'])
                            : AssetImage('assets/images/serv1.png') as ImageProvider,
                      ),
                      if (_selectedImage == null &&
                          (_existingAd == null ||
                              _existingAd!['profile_image_url'] == null ||
                              _existingAd!['profile_image_url'].isEmpty))
                        Icon(Icons.add_a_photo, color: Colors.white70, size: 30),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                _buildTextField('Your Name', (val) => name = val, initialValue: name, requiredField: true),
                _buildTextField('Business Name (Optional)', (val) => businessName = val, initialValue: businessName),
                _buildDropdown(),
                _buildTextField('Tagline (Short & Catchy)', (val) => tagline = val, initialValue: tagline, requiredField: true),
                _buildTextField('Describe Your Services', (val) => description = val, initialValue: description, requiredField: true, maxLines: 4),
                _buildPriceFields(),
                _buildTextField('Optional Phone Number', (val) => phoneNumber = val, initialValue: phoneNumber),

                SwitchListTile(
                  title: Text('Let other users find and add me as a friend?', style: TextStyle(color: Colors.white)),
                  value: showProfile,
                  onChanged: (val) => setState(() => showProfile = val),
                  activeColor: Colors.greenAccent,
                ),

                SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _saveAd,
                  icon: Icon(Icons.save),
                  label: Text('Submit Ad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                if (_existingAd != null) ...[
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _deleteAd,
                    icon: Icon(Icons.delete_forever),
                    label: Text('Delete Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onSaved,
      {String? initialValue, bool requiredField = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        initialValue: initialValue,
        maxLines: maxLines,
        validator: requiredField ? (val) => val == null || val.isEmpty ? 'This field is required' : null : null,
        onSaved: (val) => onSaved(val!),
      ),
    );
  }

  Widget _buildDropdown() {
    final serviceTypes = ['Psychic', 'Tarot Reader', 'Healer', 'Medium', 'Astrologer', 'Energy Worker'];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurpleAccent),
        ),
        child: DropdownButtonFormField<String>(
          value: serviceType,
          dropdownColor: Colors.deepPurpleAccent,
          decoration: InputDecoration(
            labelText: 'Service Type',
            labelStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          items: serviceTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) => setState(() => serviceType = val!),
          validator: (val) => val == null ? 'Please select a service type' : null,
        ),
      ),
    );
  }

  Widget _buildPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text('I offer my services for free', style: TextStyle(color: Colors.white)),
          value: offersFreeService,
          onChanged: (val) => setState(() => offersFreeService = val!),
          activeColor: Colors.greenAccent,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (!offersFreeService)
          _buildTextField('Price (What You Charge Clients)', (val) => price = val, initialValue: price, requiredField: true),
      ],
    );
  }
}
