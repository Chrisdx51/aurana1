import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsService {
  final supabase = Supabase.instance.client;

  // ✅ Fetch comments for a milestone post
  Future<List<Map<String, dynamic>>> fetchComments(String milestoneId) async {
    final response = await supabase
        .from('comments')
        .select('id, content, created_at, user_id, profiles (id, name, avatar)')
        .eq('milestone_id', milestoneId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ✅ Add a new comment
  Future<void> addComment(String milestoneId, String userId, String content) async {
    await supabase.from('comments').insert({
      'milestone_id': milestoneId,
      'user_id': userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ✅ Delete a comment (only if it's yours)
  Future<void> deleteComment(String commentId, String userId) async {
    await supabase.from('comments')
        .delete()
        .match({'id': commentId, 'user_id': userId});
  }
}
