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

  // Pick Image Function
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedVideo = null; // Ensure only one media type is selected
      });
    }
  }

  // Pick Video Function
  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _selectedImage = null; // Ensure only one media type is selected
      });
    }
  }

  // Function to Add Milestone
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

    // Now correctly calls `addMilestone`
    bool success = await _supabaseService.addMilestone(
      userId,
      _milestoneController.text,
      _selectedMilestoneType,
      mediaUrl, // Fix applied here
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Your spiritual journey has been recorded!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to add milestone")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD), // Tranquil light blue
      appBar: AppBar(
        title: Text(
          "Record Your Journey",
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Color(0xFFBBDEFB),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _milestoneController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe your spiritual journey...",
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _pickImage, child: Text("📷 Image")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _pickVideo, child: Text("🎥 Video")),
              ],
            ),
            if (_selectedImage != null) Image.file(_selectedImage!, height: 150),
            if (_selectedVideo != null) Icon(Icons.videocam, size: 100),
            SizedBox(height: 20),
            Center(
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _addMilestone,
                child: Text("Record Journey"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}