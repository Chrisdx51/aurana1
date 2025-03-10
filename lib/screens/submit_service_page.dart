import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'payment_page.dart';
import 'package:aurana/screens/all_ads_page.dart';

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

  Map<String, dynamic>? _existingAd; // ✅ Check for existing ad

  @override
  void initState() {
    super.initState();
    _checkExistingAd(); // ✅ Check for ad on load
  }

  Future<void> _checkExistingAd() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final ad = await _supabase
        .from('service_ads')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    setState(() {
      _existingAd = ad;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    String? imageUrl;
    if (_selectedImage != null) {
      final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}_${name}.png';
      await _supabase.storage.from('ads').upload(
        fileName,
        _selectedImage!,
        fileOptions: FileOptions(upsert: true),
      );
      imageUrl = _supabase.storage.from('ads').getPublicUrl(fileName);
    }

    final userId = _supabase.auth.currentUser?.id;

    // Set expiry date 3 months from now
    final expiryDate = DateTime.now().add(Duration(days: 90)).toIso8601String();

    // Insert or update ad depending on existence
    if (_existingAd == null) {
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
      await _supabase.from('service_ads').update({
        'name': name,
        'business_name': businessName,
        'service_type': serviceType,
        'tagline': tagline,
        'description': description,
        'price': offersFreeService ? 'Free' : price,
        'phone_number': phoneNumber,
        'profile_image_url': imageUrl ?? _existingAd!['profile_image_url'],
        'show_profile': showProfile,
        'expiry_date': expiryDate,
      }).eq('id', _existingAd!['id']);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Your ad was submitted successfully! All ads are free until further notice!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PaymentPage()),
    );
  }

  Future<void> _deleteAd() async {
    if (_existingAd == null) return;

    await _supabase
        .from('service_ads')
        .delete()
        .eq('id', _existingAd!['id']);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ Your ad has been deleted.'),
        backgroundColor: Colors.red,
      ),
    );

    setState(() {
      _existingAd = null;
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
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _existingAd == null ? _buildSubmitForm() : _buildAdManagement(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),
          Text(
            'Advertise Your Spiritual Service',
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
                      : AssetImage('assets/images/serv1.png') as ImageProvider,
                ),
                if (_selectedImage == null)
                  Icon(Icons.add_a_photo, color: Colors.white70, size: 30),
              ],
            ),
          ),

          SizedBox(height: 20),

          _buildTextField('Your Name', (val) => name = val, requiredField: true),
          _buildTextField('Business Name (Optional)', (val) => businessName = val),
          _buildDropdown(),
          _buildTextField('Tagline (Short & Catchy)', (val) => tagline = val, requiredField: true),
          _buildTextField('Describe Your Services', (val) => description = val, requiredField: true, maxLines: 4),
          _buildPriceFields(),
          _buildTextField('Optional Phone Number', (val) => phoneNumber = val),

          SwitchListTile(
            title: Text('Let other users find and add me as a friend?', style: TextStyle(color: Colors.white)),
            value: showProfile,
            onChanged: (val) => setState(() => showProfile = val),
            activeColor: Colors.greenAccent,
          ),

          SizedBox(height: 20),

          GestureDetector(
            onTap: _submitService,
            child: Container(
              width: 160,
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Center(
                child: Text('Submit',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAdManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 40),
        Text(
          'You already have an ad!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 20),

        Card(
          color: Colors.white.withOpacity(0.2),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: _existingAd!['profile_image_url'] != null &&
                  _existingAd!['profile_image_url'].isNotEmpty
                  ? NetworkImage(_existingAd!['profile_image_url'])
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            title: Text(_existingAd!['name'] ?? '', style: TextStyle(color: Colors.white)),
            subtitle: Text(_existingAd!['service_type'] ?? '', style: TextStyle(color: Colors.white70)),
          ),
        ),

        SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () {
            // Prefill form to edit
            setState(() {
              name = _existingAd!['name'] ?? '';
              businessName = _existingAd!['business_name'] ?? '';
              serviceType = _existingAd!['service_type'] ?? 'Psychic';
              tagline = _existingAd!['tagline'] ?? '';
              description = _existingAd!['description'] ?? '';
              price = _existingAd!['price'] ?? '';
              phoneNumber = _existingAd!['phone_number'] ?? '';
              showProfile = _existingAd!['show_profile'] ?? true;
            });
            _existingAd = null;
          },
          icon: Icon(Icons.edit),
          label: Text('Edit Ad'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),

        SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: _deleteAd,
          icon: Icon(Icons.delete_forever),
          label: Text('Delete Ad'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String) onSaved,
      {bool requiredField = false, int maxLines = 1}) {
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
        maxLines: maxLines,
        validator: requiredField
            ? (val) => val == null || val.isEmpty ? 'This field is required' : null
            : null,
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
          _buildTextField('Price (What You Charge Clients)', (val) => price = val, requiredField: true),
      ],
    );
  }
}
