import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AddMilestoneScreen extends StatefulWidget {
  @override
  _AddMilestoneScreenState createState() => _AddMilestoneScreenState();
}

class _AddMilestoneScreenState extends State<AddMilestoneScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _milestoneController = TextEditingController();
  String _selectedMilestoneType = "meditation";
  bool _isSubmitting = false;
  File? _selectedImage;
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();
  bool _isPrivate = true; // ✅ Default to Sacred

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedVideo = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _selectedImage = null;
      });
    }
  }

  Future<void> _addMilestone() async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: User not logged in")),
      );
      return;
    }

    if (_milestoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter your spiritual experience")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? mediaUrl;
    if (_selectedImage != null) {
      mediaUrl = await _supabaseService.uploadMedia(_selectedImage!);
    } else if (_selectedVideo != null) {
      mediaUrl = await _supabaseService.uploadMedia(_selectedVideo!);
    }

    // ✅ Save "sacred" (private) or "open" (public)
    String visibility = _isPrivate ? "sacred" : "open";

    bool success = await _supabaseService.addMilestone(
      userId,
      _milestoneController.text,
      _selectedMilestoneType,
      mediaUrl,
      visibility, // ✅ Save visibility setting
    );

    if (success) {
      await _supabaseService.updateSpiritualXP(userId, 10);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Journey saved & XP earned!")),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to add milestone")),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text("Record Your Journey", style: TextStyle(fontSize: 18)),
        backgroundColor: Color(0xFFBBDEFB),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(),
            SizedBox(height: 20),
            _buildDropdown(),
            SizedBox(height: 20),
            _buildVisibilityToggle(), // ✅ Added Visibility Toggle
            SizedBox(height: 20),
            _buildMediaButtons(),
            SizedBox(height: 10),
            _buildMediaPreview(),
            SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _milestoneController,
      maxLines: 3,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: "Describe your spiritual journey...",
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Journey Type:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: _selectedMilestoneType,
          isExpanded: true,
          items: ["meditation", "tarot_reading", "healing", "energy_work"]
              .map((type) => DropdownMenuItem<String>(
            value: type,
            child: Text(type.replaceAll("_", " ").toUpperCase()),
          ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMilestoneType = value;
              });
            }
          },
        ),
      ],
    );
  }

  // ✅ New Visibility Toggle
  Widget _buildVisibilityToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("✨ Visibility:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text(_isPrivate ? "Sacred" : "Open",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
            Switch(
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text("Image"),
        ),
        SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _pickVideo,
          icon: Icon(Icons.video_camera_back),
          label: Text("Video"),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      children: [
        if (_selectedImage != null)
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Image.file(_selectedImage!, height: 150),
          ),
        if (_selectedVideo != null)
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.videocam, size: 100),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: _isSubmitting
          ? CircularProgressIndicator()
          : ElevatedButton(
        onPressed: _addMilestone,
        child: Text("Record Journey"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
