import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/posts_service.dart';
import '../services/likes_service.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart'; // ✅ New screen for creating posts

class SocialFeedScreen extends StatefulWidget {
  @override
  _SocialFeedScreenState createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final PostsService postsService = PostsService();
  final LikesService likesService = LikesService();
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // 🔥 Load Posts from Supabase
  Future<void> _loadPosts() async {
    currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      print("⚠ User not logged in");
      return;
    }

    List<Map<String, dynamic>> fetchedPosts = await postsService.getPosts();

    print("📌 Loaded posts: $fetchedPosts"); // Debugging log

    setState(() {
      posts = fetchedPosts;
      isLoading = false;
    });
  }

  // 🔥 Like or Unlike Post
  Future<void> _likePost(String postId) async {
    if (currentUserId != null) {
      await likesService.toggleLike(postId, currentUserId!);
      _loadPosts(); // Refresh feed
    }
  }

  // 🔥 Delete Post (Only for the Owner)
  Future<void> _deletePost(String postId) async {
    if (currentUserId != null) {
      await postsService.deletePost(postId, currentUserId!);
      _loadPosts();
    }
  }

  // 🔥 Report Post
  void _reportPost(String postId) {
    print("Reported post: $postId");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Post reported successfully.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // ✅ Lowered header height for ad space
        child: AppBar(
          title: const Text("Social Feed", style: TextStyle(color: Colors.white, fontSize: 22)),
          backgroundColor: Colors.deepPurpleAccent.shade200,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
          _loadPosts(); // Refresh feed after post is created
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8E44AD), // Soft purple
              Color(0xFF3498DB), // Light blue
              Color(0xFFF1C40F), // Gentle golden yellow
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : posts.isEmpty
            ? Center(
          child: Text(
            "No posts available.",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            bool isOwner = post['user_id'] == currentUserId;

            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Profile Picture & Name
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: post['profile_pic'] != null
                            ? NetworkImage(post['profile_pic'])
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      title: Text(
                        post['name'],
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        post['created_at'],
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔥 Delete Button (Only for Owner)
                          if (isOwner)
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deletePost(post['id']),
                            ),
                          // 🚨 Report Button
                          IconButton(
                            icon: Icon(Icons.report, color: Colors.orange),
                            onPressed: () => _reportPost(post['id']),
                          ),
                        ],
                      ),
                    ),
                    // 🔹 Post Content
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        post['content'],
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                    // 🔹 Post Image (Fixed Broken Image Issue)
                    Column(
                      children: [
                        Text(
                          "URL: ${post['image_url'] ?? 'No Image URL'}",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        post['image_url'] != null
                            ? Image.network(
                          "${post['image_url']}?cachebuster=${DateTime.now().millisecondsSinceEpoch}",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                            );
                          },
                        )
                            : Container(
                          width: double.infinity,
                          height: 200,
                          alignment: Alignment.center,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // 🔹 Like & Comment Buttons (Fixed Overflow)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ✨ Spiritual Like Button
                          GestureDetector(
                            onTap: () => _likePost(post['id']),
                            child: Row(
                              children: [
                                Icon(
                                  post['is_liked']
                                      ? Icons.auto_awesome // Spiritual glowing star
                                      : Icons.auto_awesome_outlined,
                                  color: post['is_liked'] ? Colors.amber : Colors.black54,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '${post['like_count']} Spiritual Likes',
                                  style: TextStyle(color: Colors.black87, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          // 🌙 Comments Button (Icon-based, Smaller)
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommentsScreen(postId: post['id']),
                                ),
                              );
                            },
                            icon: Icon(Icons.comment, color: Colors.blue, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}