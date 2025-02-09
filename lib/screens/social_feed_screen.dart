import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'comments_page.dart';
import '../models/comment_model.dart';

class SocialFeedScreen extends StatefulWidget {
  @override
  _SocialFeedScreenState createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  List<Post> posts = [];
  File? _selectedImage;
  final TextEditingController _textController = TextEditingController();
  final Set<int> likedPosts = {}; // Track liked posts by index

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPosts = prefs.getString('posts');
    if (savedPosts != null) {
      setState(() {
        posts = (json.decode(savedPosts) as List)
            .map((post) => Post.fromJson(post))
            .toList();
      });
    }
  }

  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'posts', json.encode(posts.map((post) => post.toJson()).toList()));
  }

  void _createPost({DateTime? scheduledTime}) {
    if (_textController.text.isNotEmpty || _selectedImage != null) {
      final newPost = Post(
        user: "You",
        content: _textController.text,
        image: _selectedImage,
        likes: 0,
        comments: [],
        timestamp: scheduledTime ?? DateTime.now(),
      );
      if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) {
        setState(() {
          posts.insert(0, newPost);
        });
      } else {
        Future.delayed(scheduledTime.difference(DateTime.now()), () {
          setState(() {
            posts.insert(0, newPost);
          });
          _savePosts();
        });
      }
      _textController.clear();
      _selectedImage = null;
      _savePosts();
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

  void _deletePost(int index) {
    setState(() {
      posts.removeAt(index);
    });
    _savePosts();
  }

  void _reportPost(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Post reported."),
      duration: Duration(seconds: 2),
    ));
  }

  void _schedulePost() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (selectedTime != null) {
        final scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        _createPost(scheduledTime: scheduledDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostLikedPost = posts.isNotEmpty
        ? posts.reduce((a, b) => a.likes > b.likes ? a : b)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Social Feed'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          if (mostLikedPost != null)
            Card(
              margin: EdgeInsets.all(10),
              color: Colors.yellow.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "🌟 Daily Highlight: ${mostLikedPost.content}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final isLiked = likedPosts.contains(index);
                return Card(
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              post.user,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePost(index),
                            ),
                          ],
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
                        Wrap(
                          spacing: 10,
                          children: [
                            TextButton.icon(
                              onPressed: isLiked
                                  ? null
                                  : () {
                                      setState(() {
                                        post.likes++;
                                        likedPosts.add(index);
                                      });
                                      _savePosts();
                                    },
                              icon: Icon(Icons.favorite,
                                  color: isLiked
                                      ? Colors.teal.shade300
                                      : Colors.grey),
                              label: Text("${post.likes} Likes"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommentsPage(
                                      postUser: post.user,
                                      postContent: post.content,
                                      postImage:
                                          post.image, // Pass the image here
                                      comments: post.comments,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.comment_outlined,
                                  color: Colors.teal.shade300, size: 18),
                              label: Text("Comment"),
                            ),
                            TextButton.icon(
                              onPressed: () => _reportPost(post),
                              icon: Icon(Icons.flag, color: Colors.red),
                              label: Text("Report"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.teal.shade300),
                  onPressed: _pickImage,
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.file(
                      _selectedImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration:
                        InputDecoration(hintText: "What's on your mind?"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal.shade300),
                  onPressed: _createPost,
                ),
                IconButton(
                  icon: Icon(Icons.schedule, color: Colors.teal.shade300),
                  onPressed: _schedulePost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
