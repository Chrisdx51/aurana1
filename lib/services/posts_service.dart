import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ✅ Fetch all posts with user info
  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await supabase
        .from('posts')
        .select('id, content, image_url, created_at, user_id, profiles(name, profile_pic)')
        .order('created_at', ascending: false);

    final likesResponse = await supabase.from('likes').select('post_id, user_id');

    return response.map((post) {
      final isLiked = likesResponse.any((like) => like['post_id'] == post['id']);

      return {
        'id': post['id'],
        'content': post['content'],
        'image_url': post['image_url'],
        'created_at': post['created_at'],
        'name': post['profiles']['name'],
        'profile_pic': post['profiles']['profile_pic'],
        'is_liked': isLiked,
      };
    }).toList();
  }
}
