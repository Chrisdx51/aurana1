import 'package:supabase_flutter/supabase_flutter.dart';

class LikesService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ✅ Check if user has already liked the post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final response = await supabase
          .from('likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle(); // ✅ FIX: Prevents errors when no result found

      return response != null;
    } catch (error) {
      print("❌ Error checking like status: $error");
      return false;
    }
  }

  // ✅ Get total likes for a post
  Future<int> getLikesCount(String postId) async {
    try {
      final response = await supabase
          .from('likes')
          .select('id')
          .eq('post_id', postId);

      return response.length;
    } catch (error) {
      print("❌ Error fetching likes count: $error");
      return 0;
    }
  }

  // ✅ Add a like to the post
  Future<void> addLike(String postId, String userId) async {
    try {
      await supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(), // ✅ Added timestamp
      });
    } catch (error) {
      print("❌ Error adding like: $error");
    }
  }

  // ✅ Remove a like from the post
  Future<void> removeLike(String postId, String userId) async {
    try {
      await supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } catch (error) {
      print("❌ Error removing like: $error");
    }
  }

  // ✅ Toggle Like (New Function)
  Future<void> toggleLike(String postId, String userId) async {
    bool liked = await hasUserLikedPost(postId, userId);
    if (liked) {
      await removeLike(postId, userId);
    } else {
      await addLike(postId, userId);
    }
  }
}
