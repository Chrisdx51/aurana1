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
  String _visibility = "everyone"; // Visibility selector
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
      final String filePath = 'posts/${user.id}/$fileName'; // ✅ Correct file path

      await Supabase.instance.client.storage
          .from('post_media')
          .upload(filePath, _selectedMedia!, fileOptions: FileOptions(upsert: true));

      return filePath; // ✅ Returning filePath (not URL) to be used in `_postContent`
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

    String? filePath;
    if (_selectedMedia != null) {
      filePath = await _uploadMedia();
    }

    await Supabase.instance.client.from('posts').insert({
      'user_id': user.id,
      'content': _textController.text,
      'image_url': filePath != null
          ? 'https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/post_media/$filePath'
          : null,
      'visibility': _visibility,
      'created_at': DateTime.now().toIso8601String(),
    });

    setState(() {
      _isUploading = false;
      _textController.clear();
      _selectedMedia = null;
    });

    // ✅ Show Success Message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Post successfully uploaded!")),
    );

    // ✅ Navigate back to the feed
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.black, // ✅ Status bar area is now black
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // ✅ Prevents overflow
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50), // ✅ Lowered for ad banner space

                    // 🌟 Visibility Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Visibility: ", style: TextStyle(color: Colors.black87, fontSize: 16)),
                        DropdownButton<String>(
                          dropdownColor: Colors.white,
                          value: _visibility,
                          items: [
                            DropdownMenuItem(value: "everyone", child: Text("Everyone")),
                            DropdownMenuItem(value: "friends", child: Text("Friends Only")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _visibility = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    // 📜 Text Input
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Write something...",
                          border: InputBorder.none,
                        ),
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 📸 Media Preview (Fixed Overflow)
                    if (_selectedMedia != null)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade700, width: 2),
                          image: DecorationImage(
                            image: FileImage(_selectedMedia!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    // 📂 Upload Buttons (Icons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _pickMedia(ImageSource.gallery),
                          icon: Icon(Icons.image, size: 35, color: Colors.blue),
                          tooltip: "Upload Image",
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
                          icon: Icon(Icons.video_library, size: 35, color: Colors.teal),
                          tooltip: "Upload Video",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 🚀 Post Button (Fixed Overflow)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20), // ✅ Ensures it never gets cut off
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _postContent,
                        icon: Icon(Icons.send, size: 24, color: Colors.white),
                        label: Text(
                          _isUploading ? "Posting..." : "Post",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900, // ✅ Kept same color
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
