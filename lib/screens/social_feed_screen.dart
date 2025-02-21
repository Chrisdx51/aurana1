import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/posts_service.dart';
import '../services/likes_service.dart';
import 'comments_screen.dart';

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

  // 🔥 Load Posts
  Future<void> _loadPosts() async {
    currentUserId = Supabase.instance.client.auth.currentUser?.id;
    List<Map<String, dynamic>> fetchedPosts = await postsService.getPosts();
    setState(() {
      posts = fetchedPosts;
      isLoading = false;
    });
  }

  // 🔥 Like Post
  Future<void> _likePost(String postId) async {
    if (currentUserId != null) {
      await likesService.toggleLike(postId, currentUserId!);
      _loadPosts(); // Refresh feed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Social Feed")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? Center(child: Text("No posts available."))
          : ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          return Card(
            margin: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: post['profile_pic'] != null
                        ? NetworkImage(post['profile_pic'])
                        : AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  title: Text(post['name']),
                  subtitle: Text(post['created_at']),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(post['content']),
                ),
                if (post['image_url'] != null)
                  Image.network(post['image_url']),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        post['is_liked'] ? Icons.favorite : Icons.favorite_border,
                        color: post['is_liked'] ? Colors.red : null,
                      ),
                      onPressed: () => _likePost(post['id']),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(postId: post['id']),
                          ),
                        );
                      },
                      child: Text("View Comments"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
