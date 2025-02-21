import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ✅ Fetch comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await supabase
        .from('comments')
        .select('id, content, created_at, user_id, profiles(name, profile_pic)')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    return response.map((comment) {
      return {
        'id': comment['id'],
        'content': comment['content'],
        'created_at': comment['created_at'],
        'name': comment['profiles']['name'],
        'profile_pic': comment['profiles']['profile_pic'],
      };
    }).toList();
  }

  // ✅ Add a new comment
  Future<void> addComment(String postId, String userId, String content) async {
    await supabase.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
