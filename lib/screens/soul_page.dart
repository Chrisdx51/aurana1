import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurana/screens/create_post_screen.dart';
import 'package:aurana/screens/comments_page.dart';

class SocialFeedScreen extends StatefulWidget {
  @override
  _SocialFeedScreenState createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('uuid, caption, user_id, image_url, created_at, profiles(name, profile_pic)')
        .order('created_at', ascending: false);

    setState(() {
      posts = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _likePost(String postId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('likes').insert({
      'post_id': postId,
      'user_id': user.id,
    });

    _loadPosts(); // Refresh posts after like
  }

  bool _hasUserLikedPost(String postId) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    return posts.any((post) =>
        post['likes'] != null &&
        (post['likes'] as List).any((like) => like['user_id'] == user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Eternal Stream", style: TextStyle(fontFamily: "MysticFont", fontSize: 24)),
        backgroundColor: Colors.black87,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.blueGrey.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: posts.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(post);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          ).then((_) => _loadPosts()); // Reload after posting
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      color: Colors.blueGrey.shade800,
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            ListTile(
              leading: CircleAvatar(
                backgroundImage: post['profiles']['profile_pic'] != null
                    ? NetworkImage(post['profiles']['profile_pic'])
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              title: Text(
                post['profiles']['name'] ?? "Unknown User",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _formatTimestamp(post['created_at']),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),

            // Post Content (Image, Video, or Text)
            if (post['image_url'] != null)
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(post['image_url']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            Text(
              post['caption'] ?? '',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Like & Comment Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like Button
                IconButton(
                  icon: Icon(
                    _hasUserLikedPost(post['uuid']) ? Icons.favorite : Icons.favorite_border,
                    color: _hasUserLikedPost(post['uuid']) ? Colors.red : Colors.white,
                  ),
                  onPressed: () => _likePost(post['uuid']),
                ),

                // Comment Button
                IconButton(
                  icon: Icon(Icons.comment, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsPage(
                          postId: post['uuid'],
                          postUser: post['profiles']['name'] ?? "Unknown User",
                          postContent: post['caption'] ?? '',
                          comments: [], // Initially empty, will load from Supabase
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}