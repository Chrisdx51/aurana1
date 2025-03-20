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
  bool _isSubmitting = false;
  File? _selectedMedia;
  bool _isPrivate = true;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia({required bool isVideo}) async {
    final pickedFile = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _selectedMedia = File(pickedFile.path));
    }
  }

  Future<void> _submitMilestone() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null || _milestoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please describe your Soul Journey.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? mediaUrl;
    if (_selectedMedia != null) {
      mediaUrl = await _supabaseService.uploadMedia(_selectedMedia!);
    }

    bool success = await _supabaseService.addMilestone(
      userId,
      _milestoneController.text.trim(),
      "soul_journey",
      mediaUrl,
      _isPrivate ? "sacred" : "open",
    );

    if (success) {
      await _supabaseService.updateSpiritualXP(userId, 10);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✨ Journey recorded! +10 XP!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Something went wrong. Try again.")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Aurana Share", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _visibilitySelector(),
            SizedBox(height: 20),
            _journeyDescriptionInput(),
            SizedBox(height: 8),
            Text(
              "🌟 Share your soul journey with the world or keep it sacred just for you.",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _mediaPickerButtons(),
            _mediaPreview(),
            SizedBox(height: 30),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _visibilitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("✨ Visibility:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Row(
          children: [
            Text(_isPrivate ? "Sacred" : "Open", style: TextStyle(fontWeight: FontWeight.bold)),
            Switch(
              activeColor: Colors.indigo,
              value: _isPrivate,
              onChanged: (val) => setState(() => _isPrivate = val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _journeyDescriptionInput() {
    return TextField(
      controller: _milestoneController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Describe your soul journey...",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  Widget _mediaPickerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.photo, color: Colors.white),
            label: Text("Image"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _pickMedia(isVideo: false),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.videocam, color: Colors.white),
            label: Text("Video"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _pickMedia(isVideo: true),
          ),
        ),
      ],
    );
  }

  Widget _mediaPreview() {
    if (_selectedMedia == null) return SizedBox(height: 0);

    return Container(
      margin: EdgeInsets.only(top: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.black12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _selectedMedia!.path.endsWith('.mp4')
            ? Center(
          child: Icon(Icons.videocam, size: 80, color: Colors.blueAccent),
        )
            : Image.file(_selectedMedia!, fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? CircularProgressIndicator(color: Colors.white)
            : Text("✨ Share Journey", style: TextStyle(fontSize: 18)),
        onPressed: _submitMilestone,
      ),
    );
  }
}
