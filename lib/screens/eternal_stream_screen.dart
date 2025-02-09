import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment_model.dart';
import 'dart:io';

class EternalStreamScreen extends StatefulWidget {
  @override
  _EternalStreamScreenState createState() => _EternalStreamScreenState();
}

class _EternalStreamScreenState extends State<EternalStreamScreen> {
  List<Post> posts = [];
  File? _selectedImage;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _createPost() {
    if (_textController.text.isNotEmpty || _selectedImage != null) {
      setState(() {
        posts.insert(
          0,
          Post(
            user: "You",
            content: _textController.text,
            image: _selectedImage,
            comments: [],
            timestamp: DateTime.now(),
          ),
        );
      });
      _textController.clear();
      _selectedImage = null;
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _openCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Create a Post",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                _selectedImage != null
                    ? Column(
                        children: [
                          Image.file(_selectedImage!,
                              height: 100, fit: BoxFit.cover),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Text("Remove Image"),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.image),
                        label: Text("Add Image"),
                      ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _createPost,
                  child: Text("Post"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Eternal Stream')),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            margin: EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.user,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "${post.timestamp.hour}:${post.timestamp.minute}, ${post.timestamp.day}/${post.timestamp.month}/${post.timestamp.year}",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 10),
                  if (post.content.isNotEmpty)
                    Text(
                      post.content,
                      style: TextStyle(fontSize: 14),
                    ),
                  if (post.image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Image.file(post.image!,
                          height: 150, fit: BoxFit.cover),
                    ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.thumb_up_alt_outlined, size: 18),
                        label: Text("Like"),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.comment_outlined, size: 18),
                        label: Text("Comment"),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.share_outlined, size: 18),
                        label: Text("Share"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePostDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

class Post {
  final String user;
  final String content;
  final File? image;
  final List<Comment> comments;
  final DateTime timestamp;

  Post({
    required this.user,
    required this.content,
    this.image,
    required this.comments,
    required this.timestamp,
  });
}
