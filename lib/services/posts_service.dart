import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ✅ Fetch posts with user info, likes & comments count
  Future<List<Map<String, dynamic>>> getPosts() async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print("⚠ User is not logged in!");
      return [];
    }

    try {
      // 🔹 Fetch posts from Supabase (Fixing 'posts' typo)
      final List<dynamic> response = await supabase
          .from('posts')
          .select('id, content, image_url, created_at, visibility, user_id, likes(id), comments(id)')
          .order('created_at', ascending: false);

      print("✅ Raw Supabase Response: $response"); // Debugging log

      List<Map<String, dynamic>> postsWithProfiles = [];

      for (var post in response) {
        bool canSeePost = post['visibility'] == 'everyone';

        if (!canSeePost) {
          // Check if the current user is friends with the post owner
          final friendCheck = await supabase
              .from('friends')
              .select('id')
              .eq('user_id', post['user_id'])
              .eq('friend_id', userId)
              .maybeSingle();

          canSeePost = friendCheck != null; // If they are friends, show the post
        }

        if (canSeePost) {
          // Fetch profile data manually (Fixing missing user data issue)
          final profileResponse = await supabase
              .from('profiles')
              .select('name, icon')
              .eq('id', post['user_id'])
              .maybeSingle();

          postsWithProfiles.add({
            'id': post['id'],
            'content': post['content'] ?? '',
            'image_url': post['image_url'] != null
                ? Supabase.instance.client.storage.from('post_media').getPublicUrl(post['image_url'])
                : '',
            'created_at': post['created_at'] ?? '',
            'name': profileResponse?['name'] ?? 'Unknown User',
            'profile_pic': profileResponse?['icon'] ?? 'https://via.placeholder.com/150',
            'is_liked': (post['likes'] as List<dynamic>?)?.isNotEmpty ?? false,
            'like_count': (post['likes'] as List<dynamic>?)?.length ?? 0,
            'comment_count': (post['comments'] as List<dynamic>?)?.length ?? 0,
          });
        }
      }

      print("✅ Supabase response: $postsWithProfiles"); // Debugging log
      return postsWithProfiles;
    } catch (error) {
      print("❌ Error fetching posts: $error");
      return [];
    }
  }

  // 🔥 Create a Post (With Visibility Option)
  Future<void> createPost(String userId, String content, String visibility, {String? imageUrl}) async {
    final response = await supabase
        .from('posts')
        .insert({
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'visibility': visibility,
      'created_at': DateTime.now().toIso8601String(),
    })
        .select(); // ✅ Ensures we receive a response

    if (response.isEmpty) {
      print("❌ Error creating post: No response received.");
    } else {
      print("✅ Post created successfully");
    }
  }

  // ❌🔥 Delete Post (Only for the Owner)
  Future<void> deletePost(String postId, String userId) async {
    final response = await supabase
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', userId); // Ensures only the post owner can delete it

    if (response.isEmpty) {
      print("❌ Error deleting post: Post may not exist.");
    } else {
      print("✅ Post deleted successfully");
    }
  }
}
