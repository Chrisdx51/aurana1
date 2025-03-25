import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'payment_page.dart';

class SubmitYourServicePage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? existingAdData;

  const SubmitYourServicePage({
    Key? key,
    this.isEditing = false,
    this.existingAdData,
  }) : super(key: key);

  @override
  _SubmitYourServicePageState createState() => _SubmitYourServicePageState();
}

class _SubmitYourServicePageState extends State<SubmitYourServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final businessNameController = TextEditingController();
  final taglineController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final phoneNumberController = TextEditingController();

  bool offersFreeService = false;
  bool showProfile = true;

  File? _selectedImage;
  String? _existingImageUrl;

  List<Map<String, dynamic>> _serviceCategories = [];
  List<String> selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _fetchCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    businessNameController.dispose();
    taglineController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.isEditing && widget.existingAdData != null) {
      final ad = widget.existingAdData!;
      nameController.text = ad['name'] ?? '';
      businessNameController.text = ad['business_name'] ?? '';
      taglineController.text = ad['tagline'] ?? '';
      descriptionController.text = ad['description'] ?? '';
      priceController.text = ad['price'] == 'Free' ? '' : ad['price'] ?? '';
      phoneNumberController.text = ad['phone_number'] ?? '';
      offersFreeService = ad['price'] == 'Free';
      showProfile = ad['show_profile'] ?? true;
      _existingImageUrl = ad['profile_image_url'] ?? '';

      _fetchAdCategories(ad['id']);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _supabase
          .from('service_categories')
          .select('id, name');

      setState(() {
        _serviceCategories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('❌ Failed to fetch categories: $e');
    }
  }

  Future<void> _fetchAdCategories(String adId) async {
    try {
      final response = await _supabase
          .from('service_ads_categories')
          .select('category_id')
          .eq('ad_id', adId);

      final categoryIds = response
          .map<String>((row) => row['category_id'] as String)
          .toList();

      setState(() {
        selectedCategoryIds = categoryIds;
      });
    } catch (e) {
      print('❌ Failed to fetch ad categories: $e');
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

    if (selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one category.')),
      );
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to continue.')),
      );
      return;
    }

    String? imageUrl = _existingImageUrl;

    try {
      if (_selectedImage != null) {
        final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}_$userId.png';
        await _supabase.storage.from('ads').upload(
          fileName,
          _selectedImage!,
          fileOptions: FileOptions(upsert: true),
        );
        imageUrl = _supabase.storage.from('ads').getPublicUrl(fileName);
      }

      final expiryDate = DateTime.now().add(Duration(days: 90)).toIso8601String();

      final adData = {
        'user_id': userId,
        'name': nameController.text.trim(),
        'business_name': businessNameController.text.trim(),
        'tagline': taglineController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': offersFreeService ? 'Free' : priceController.text.trim(),
        'phone_number': phoneNumberController.text.trim(),
        'profile_image_url': imageUrl ?? '',
        'show_profile': showProfile,
        'expiry_date': expiryDate,
      };

      String adId;

      if (widget.isEditing && widget.existingAdData != null) {
        adId = widget.existingAdData!['id'];
        await _supabase.from('service_ads').update(adData).eq('id', adId);
        await _supabase.from('service_ads_categories').delete().eq('ad_id', adId);
      } else {
        final insertResponse = await _supabase
            .from('service_ads')
            .insert(adData)
            .select()
            .single();

        adId = insertResponse['id'];
      }

      final categoryRows = selectedCategoryIds
          .map((categoryId) => {
        'ad_id': adId,
        'category_id': categoryId,
      })
          .toList();

      if (categoryRows.isNotEmpty) {
        await _supabase.from('service_ads_categories').insert(categoryRows);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Your ad has been successfully submitted!'),
          backgroundColor: Colors.greenAccent,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(adId: adId),
        ),
      );

    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit your ad.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteAd() async {
    if (!widget.isEditing || widget.existingAdData == null) return;

    try {
      final adId = widget.existingAdData!['id'];

      await _supabase.from('service_ads_categories').delete().eq('ad_id', adId);
      await _supabase.from('service_ads').delete().eq('id', adId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Your ad has been deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Delete Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to delete ad.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Your Service Ad' : 'Submit Your Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/misc2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _introSection(),
                    _trustMessage(),
                    _imagePickerWidget(),
                    _buildTextField('Your Name', nameController, requiredField: true),
                    _buildTextField('Business Name (Optional)', businessNameController),
                    _buildCategoryMultiSelect(),
                    _buildTextField('Tagline (Short & Catchy)', taglineController, requiredField: true),
                    _buildTextField('Describe Your Services', descriptionController, requiredField: true, maxLines: 4),
                    _buildPriceFields(),
                    _buildTextField('Optional Phone Number', phoneNumberController),
                    _showProfileToggle(),
                    SizedBox(height: 30),
                    _submitButton(),
                    if (widget.isEditing) ...[
                      SizedBox(height: 10),
                      _deleteButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _introSection() {
    return Column(
      children: [
        Text(
          widget.isEditing ? 'Edit Your Sacred Service Ad' : 'Advertise Your Sacred Service',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Share your spiritual gifts with our community.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _trustMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, color: Colors.greenAccent, size: 30),
          SizedBox(height: 10),
          Text("Your submission is secure and sacred.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text("Our team reviews each ad within 24-48 hours.", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _imagePickerWidget() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white24,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                ? NetworkImage(_existingImageUrl!)
                : AssetImage('assets/images/serv1.png') as ImageProvider,
          ),
          if (_selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
            Icon(Icons.add_a_photo, color: Colors.white70, size: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text('Select Categories', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _serviceCategories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.5,
          ),
          itemBuilder: (context, index) {
            final category = _serviceCategories[index];
            final categoryId = category['id'];
            final categoryName = category['name'];
            final isSelected = selectedCategoryIds.contains(categoryId);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedCategoryIds.remove(categoryId);
                  } else {
                    selectedCategoryIds.add(categoryId);
                  }
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.9) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.amberAccent : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool requiredField = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.black.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurpleAccent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurpleAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.amberAccent, width: 2),
          ),
        ),
        maxLines: maxLines,
        validator: requiredField
            ? (val) => val == null || val.trim().isEmpty ? 'This field is required' : null
            : null,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Price (e.g. £50)', priceController, requiredField: true),
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text('Enter the price your clients will pay for your service.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _showProfileToggle() {
    return SwitchListTile(
      title: Text('Allow users to find and add me?', style: TextStyle(color: Colors.white)),
      value: showProfile,
      onChanged: (val) => setState(() => showProfile = val),
      activeColor: Colors.greenAccent,
    );
  }

  Widget _submitButton() {
    return ElevatedButton.icon(
      onPressed: _saveAd,
      icon: Icon(Icons.cloud_upload),
      label: Text(widget.isEditing ? 'Update Ad' : 'Submit Ad'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _deleteButton() {
    return ElevatedButton.icon(
      onPressed: _deleteAd,
      icon: Icon(Icons.delete_forever),
      label: Text('Delete Ad'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
