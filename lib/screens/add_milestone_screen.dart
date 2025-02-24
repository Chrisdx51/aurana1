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

    // ✅ Now correctly calls `addMilestone`
    bool success = await _supabaseService.addMilestone(
      userId,
      _milestoneController.text,
      _selectedMilestoneType,
      mediaUrl, // ✅ Fix applied here
    );

    if (success) {
      await _supabaseService.updateSpiritualXP(userId, 10); // ✅ Reward XP for posting
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Journey recorded & XP earned!")),
      );

      // ✅ Auto-Boost the Milestone (if it's a meaningful action)
      final milestoneId = await _supabaseService.getLastMilestoneId(userId);
      if (milestoneId != null) {
        bool boostSuccess = await _supabaseService.addEnergyBoost(milestoneId);
        if (boostSuccess) {
          await _supabaseService.updateSpiritualXP(userId, 5); // ✅ Reward XP for getting boosted
        }
      }

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
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            Row(
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
            ),
            SizedBox(height: 10),
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
            SizedBox(height: 20),
            Center(
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
            ),
          ],
        ),
      ),
    );
  }
}
