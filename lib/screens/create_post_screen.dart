import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'social_feed_screen.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedMedia;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  // 🔥 Pick Image or Video
  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final XFile? pickedFile = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
      });
    }
  }

  // 🔥 Upload Image/Video to Supabase Storage
  Future<String?> _uploadMedia() async {
    if (_selectedMedia == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to post!")),
        );
        return null;
      }

      final fileName = _selectedMedia!.path.split('/').last;
      final filePath = 'posts/${user.id}/$fileName';

      await Supabase.instance.client.storage
          .from('post_media')
          .upload(filePath, _selectedMedia!, fileOptions: FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('post_media')
          .getPublicUrl(filePath);

      setState(() {
        _isUploading = false;
      });

      return publicUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload media: $e")),
      );
      return null;
    }
  }

  // 🔥 Submit Post to Supabase
  Future<void> _postContent() async {
    if (_textController.text.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write something or add media before posting!")),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    String? mediaUrl;
    if (_selectedMedia != null) {
      mediaUrl = await _uploadMedia();
    }

    await Supabase.instance.client.from('posts').insert({
      'user_id': user.id,
      'content': _textController.text,
      'image_url': mediaUrl,
      'created_at': DateTime.now().toIso8601String(),
    });

    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post successfully uploaded!")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SocialFeedScreen()), // ✅ Redirect to Feed
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF3A2F7A)], // Smooth mystical theme
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 90), // Space for AppBar

                // Text Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write something...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 15),

                // Media Preview
                if (_selectedMedia != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade700, width: 2),
                      image: _selectedMedia!.path.endsWith('.mp4')
                          ? null
                          : DecorationImage(
                        image: FileImage(_selectedMedia!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: _selectedMedia!.path.endsWith('.mp4')
                        ? const Center(child: Icon(Icons.video_collection, size: 50, color: Colors.white))
                        : null,
                  ),

                // Upload Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMysticalButton(
                      label: "Image",
                      icon: Icons.image,
                      color1: Colors.blue,
                      color2: Colors.purple,
                      onPressed: () => _pickMedia(ImageSource.gallery),
                      size: 50,
                    ),
                    const SizedBox(width: 12),
                    _buildMysticalButton(
                      label: "Video",
                      icon: Icons.video_library,
                      color1: Colors.green,
                      color2: Colors.teal,
                      onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
                      size: 50,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Post Button
                _buildMysticalButton(
                  label: _isUploading ? "Posting..." : "Post",
                  icon: Icons.send,
                  color1: Colors.orange,
                  color2: Colors.red,
                  onPressed: _isUploading ? null : _postContent,
                  size: 60,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysticalButton({
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback? onPressed,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: size * 0.4),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
