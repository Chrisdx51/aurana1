import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ✅ Fetch all friends
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final response = await supabase
        .from('friends')
        .select('friend_id, profiles(name, status, profile_pic)')
        .eq('user_id', userId);

    return response.map((friend) {
      return {
        'id': friend['friend_id'],
        'name': friend['profiles']['name'],
        'status': friend['profiles']['status'],
        'profile_pic': friend['profiles']['profile_pic'],
      };
    }).toList();
  }

  // ✅ Remove a friend
  Future<void> removeFriend(String userId, String friendId) async {
    await supabase
        .from('friends')
        .delete()
        .eq('user_id', userId)
        .eq('friend_id', friendId);
  }
}
