import 'dart:convert'; // ⬅️ Make sure this is at the top of your file
import 'package:http/http.dart' as http; // ⬅️ Add this import too
import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart'; // ✅ for PostgresChangeEvent (optional, depends on version)
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import 'push_notification_service.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch User Profile from Supabase
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('''
      id,
      name,
      username,
      display_name_choice,
      email,
      bio,
      dob,
      gender,
      avatar,
      spiritual_path,
      element,
      city,
      country,
      privacy_setting,
      journey_visibility,
      soul_match_message,
      spiritual_xp,
      spiritual_level
    ''')
          .eq('id', userId)
          .single();


      if (response != null) {
        print("✅ Fetched User Profile for $userId: ${response['dob']}");
        return UserModel.fromJson(response);
      } else {
        print("❌ No profile found for userId: $userId");
      }
    } catch (error) {
      print("❌ Error fetching user profile: $error");
    }
    return null;
  }

  Future<UserModel?> fetchUserProfileWithPrivacy(String viewerId, String targetUserId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('''
      id,
      name,
      username,
      display_name_choice,
      bio,
      dob,
      gender,
      avatar,
      spiritual_path,
      element,
      city,
      country,
      privacy_setting,
      journey_visibility,
      soul_match_message,
      spiritual_xp,
      spiritual_level
    ''')
          .eq('id', targetUserId)
          .single();


      if (response == null) return null;

      String privacy = response['privacy_setting'] ?? 'public';  // ✅ FIXED FIELD


      if (privacy == 'private' && viewerId != targetUserId) {
        print("🔒 Profile is private. Access denied.");
        return null; // Deny access for private profiles
      }

      if (privacy == 'friends_only' && viewerId != targetUserId) {
        final friendshipStatus = await checkFriendshipStatus(viewerId, targetUserId);
        if (friendshipStatus != 'friends') {
          print("🔒 Profile is restricted to friends only.");
          return null;
        }
      }

      return UserModel.fromJson(response); // ✅ Return profile if accessible
    } catch (error) {
      print("❌ Error fetching profile with privacy: $error");
      return null;
    }
  }

  // ✅ SUBMIT REPORT FUNCTION
  Future<bool> submitReport({
    required String reporterId,
    required String targetId,
    required String targetType, // e.g. 'post', 'profile', 'ad'
    required String reason,
  }) async {
    try {
      await supabase.from('reports').insert({
        'reporter_id': reporterId,
        'target_id': targetId,
        'target_type': targetType,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Report submitted: $targetType reported by $reporterId');

      // 🔔 Send notification to admin
      const adminId = '9d1411b9-d486-40d8-89a0-9d0714a7afa6'; // 🔁 Replace with your actual admin UID
      const adminName = 'Admin'; // (Optional)

      await createAndSendNotification(
        recipientId: adminId,
        title: '🚨 New Report Submitted',
        body: 'A new report was filed. Tap to review it in the Admin Panel.',
        type: 'report_alert',
      );

      print('🔔 Admin notified of the new report.');

      return true;
    } catch (error) {
      print('❌ Error submitting report: $error');
      return false;
    }
  }


  // ✅ Check if you sent a friend request
  Future<bool> checkSentFriendRequest(String currentUserId, String targetUserId) async {
    try {
      final response = await supabase
          .from('friend_requests')
          .select('id')
          .eq('sender_id', currentUserId)
          .eq('receiver_id', targetUserId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
    } catch (error) {
      print("❌ Error in checkSentFriendRequest: $error");
      return false;
    }
  }

// ✅ Check if you received a friend request
  Future<bool> checkReceivedFriendRequest(String currentUserId, String targetUserId) async {
    try {
      final response = await supabase
          .from('friend_requests')
          .select('id')
          .eq('sender_id', targetUserId)
          .eq('receiver_id', currentUserId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
    } catch (error) {
      print("❌ Error in checkReceivedFriendRequest: $error");
      return false;
    }
  }

// ✅ Cancel your sent friend request
  Future<bool> cancelFriendRequest(String currentUserId, String targetUserId) async {
    try {
      await supabase
          .from('friend_requests')
          .delete()
          .eq('sender_id', currentUserId)
          .eq('receiver_id', targetUserId)
          .eq('status', 'pending');

      print("✅ Friend request cancelled.");
      return true;
    } catch (error) {
      print("❌ Error in cancelFriendRequest: $error");
      return false;
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      print("🔍 Checking if profile is complete for user: $userId");

      final response = await supabase
          .from('profiles')
          .select('name, bio, dob, avatar')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print("❌ Profile does not exist!");
        return false;
      }

      final name = response['name'] ?? '';
      final bio = response['bio'] ?? '';
      final dob = response['dob'] ?? '';
      final avatar = response['avatar'] ?? '';

      // Profile is complete if ALL are filled properly
      bool isComplete = name.isNotEmpty && bio.isNotEmpty && dob.isNotEmpty && avatar.isNotEmpty;

      print("✅ Profile completeness result: $isComplete");
      return isComplete;
    } catch (error) {
      print("❌ Error checking profile completeness: $error");
      return false;
    }
  }

// ⬇️ DREAM JOURNAL

  Future<bool> insertDreamEntry(String text) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase.from('dream_journal').insert({
        'user_id': user.id,
        'dream_text': text,
      });
      return true;
    } catch (e) {
      print('❌ Error inserting dream: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDreamEntries() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('dream_journal')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching dreams: $e');
      return [];
    }
  }


  Future<bool> updateProfilePrivacy(String userId, String newPrivacySetting) async {
    try {
      await supabase
          .from('profiles')
          .update({'privacy_setting': newPrivacySetting})
          .eq('id', userId);
      return true;
    } catch (error) {
      print('Error updating privacy_setting: $error');
      return false;
    }
  }

  Future<bool> updateJourneyVisibility(String userId, String visibility) async {
    try {
      await supabase
          .from('profiles')
          .update({'journey_visibility': visibility})
          .eq('id', userId);

      print('✅ Journey visibility updated to $visibility');
      return true;
    } catch (error) {
      print('❌ Error updating journey visibility: $error');
      return false;
    }
  }

  Future<bool> updateUserProfile(
      String userId,
      String name,
      String username,                      // ✅ Added
      String displayNameChoice,             // ✅ Added
      String bio,
      String? dob,
      String? gender,                       // ✅ Added
      String? avatar,
      String? spiritualPath,
      String? element,
      String? privacySetting,
      String? journeyVisibility,            // ✅ Added
      String? soulMatchMessage,
      String? city,
      String? country,
      int spiritualXP,
      int spiritualLevel,
      ) async {
    try {
      print("🔄 Updating profile for userId: $userId");

      // Step 1: Check if the profile already exists
      final checkProfile = await supabase
          .from('profiles')
          .select('email') // Must get the email to avoid NULL issues
          .eq('id', userId)
          .maybeSingle();

      if (checkProfile == null) {
        print('❌ Profile does not exist. Creating a new one...');

        final user = Supabase.instance.client.auth.currentUser;

        if (user == null || user.email == null) {
          print("❌ Cannot create profile without an authenticated user.");
          return false;
        }

        // ✅ INSERT New Profile
        await supabase.from('profiles').insert({
          'id': userId,
          'email': user.email,
          'name': name,
          'username': username,                      // ✅ NEW
          'display_name_choice': displayNameChoice,  // ✅ NEW
          'bio': bio,
          'dob': dob,
          'gender': gender,                          // ✅ NEW
          'avatar': avatar,
          'spiritual_path': spiritualPath,
          'element': element,
          'privacy_setting': privacySetting,
          'journey_visibility': journeyVisibility,   // ✅ NEW
          'soul_match_message': soulMatchMessage,
          'city': city,
          'country': country,
          'spiritual_xp': spiritualXP,
          'spiritual_level': spiritualLevel,
          'created_at': DateTime.now().toIso8601String(), // Optional, but recommended
        }).select();

        print('✅ New profile inserted successfully!');
      } else {
        // ✅ UPDATE Existing Profile
        final updateResponse = await supabase
            .from('profiles')
            .update({
          'name': name,
          'username': username,                      // ✅ NEW
          'display_name_choice': displayNameChoice,  // ✅ NEW
          'bio': bio,
          'dob': dob,
          'gender': gender,                          // ✅ NEW
          'avatar': avatar,
          'spiritual_path': spiritualPath,
          'element': element,
          'privacy_setting': privacySetting,
          'journey_visibility': journeyVisibility,   // ✅ NEW
          'soul_match_message': soulMatchMessage,
          'city': city,
          'country': country,
          'spiritual_xp': spiritualXP,
          'spiritual_level': spiritualLevel,
          'updated_at': DateTime.now().toIso8601String(), // ✅ For tracking updates
        })
            .eq('id', userId)
            .select();

        if (updateResponse == null || updateResponse.isEmpty) {
          print('❌ Update failed: No rows affected.');
          return false;
        }

        print('✅ Profile updated successfully!');
      }

      return true;
    } catch (error) {
      print('❌ Error in updateUserProfile: $error');
      return false;
    }
  }
  // Upload Profile Picture to Supabase Storage
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = "avatars/$userId-${DateTime
          .now()
          .millisecondsSinceEpoch}.png";

      // Remove old profile picture if it exists
      final listResponse = await supabase.storage.from('avatars').list(
          path: "avatars/");
      if (listResponse is List && listResponse.isNotEmpty) {
        for (var file in listResponse) {
          if (file.name.startsWith("$userId-")) {
            await supabase.storage.from('profile_pictures').remove(
                ["avatars/${file.name}"]);
          }
        }
      }

      // Upload the new image
      await supabase.storage.from('profile_pictures').upload(
        fileName,
        imageFile,
        fileOptions: FileOptions(upsert: true),
      );

      // Retrieve and return the new public URL
      final String publicUrl = supabase.storage.from('profile_pictures')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (error) {
      print("Error uploading profile picture: $error");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentFriends(String userId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase.rpc('get_confirmed_friends', params: {'uid': userId});
    return (response as List).cast<Map<String, dynamic>>();
  }


  Future<List<UserModel>> getRecentUsers(int limit) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, avatar, is_online, last_seen, bio, dob, zodiac_sign, spiritual_path, element, spiritual_xp, spiritual_level, soul_match_message, privacy_setting') // Include all fields needed by UserModel
          .order('last_seen', ascending: false)
          .limit(limit);

      if (response == null || response.isEmpty) {
        print('⚠️ No recent users found.');
        return [];
      }

      // Convert response to List<UserModel>
      final users = response.map<UserModel>((userMap) => UserModel.fromJson(userMap)).toList();

      print('✅ Fetched ${users.length} recent users.');
      return users;
    } catch (error) {
      print('❌ Error fetching recent users: $error');
      return [];
    }
  }



  // ✅ Fetch All Business Ads for the Home Page or Discovery Page
  Future<List<Map<String, dynamic>>> fetchBusinessAds() async {
    try {
      final response = await Supabase.instance.client
          .from('service_ads')
          .select('''
      id,
      user_id,
      name,
      business_name,
      tagline,
      description,
      price,
      phone_number,
      profile_image_url,
      show_profile,
      created_at,
      expiry_date,
      rating,
      service_ads_categories (
        service_categories (
          id,
          name
        )
      )
    ''')
          .order('created_at', ascending: false);


      print("✅ Fetched ${response.length} ads from service_ads.");
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print("❌ Error fetching business ads: $error");
      return [];
    }
  }


  Future<List<String>> fetchFriendsIds(String userId) async {
    final response = await supabase
        .from('friends')
        .select('friend_id')
        .eq('user_id', userId)
        .eq('status', 'accepted'); // ✅ Adjust to your table's field if needed

    final friendIds = response.map<String>((item) => item['friend_id'] as String).toList();

    print('✅ Friends IDs fetched for $userId: $friendIds');

    return friendIds;
  }

  // Add Milestone to Supabase Database


  // ✅ BLOCK A USER
  Future<bool> blockUser(String blockerId, String blockedId) async {
    try {
      // 1️⃣ Check if user is already blocked
      final existingBlock = await supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId)
          .maybeSingle();

      if (existingBlock != null) {
        print("⚠️ User already blocked.");
        return false;
      }

      // 2️⃣ Insert new block record
      await supabase.from('blocked_users').insert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("🚫 User $blockedId has been blocked by $blockerId");
      return true;
    } catch (error) {
      print("❌ Error blocking user: $error");
      return false;
    }
  }

// ✅ UNBLOCK A USER
  Future<bool> unblockUser(String blockerId, String blockedId) async {
    try {
      final response = await supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);

      print("✅ Unblocked user $blockedId for $blockerId");
      return true;
    } catch (error) {
      print("❌ Error unblocking user: $error");
      return false;
    }
  }

  // ✅ CHECK IF BLOCKED
  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
    try {
      final result = await supabase
          .from('blocked_users')
          .select('id')
          .or('and(blocker_id.eq.$currentUserId,blocked_id.eq.$targetUserId),and(blocker_id.eq.$targetUserId,blocked_id.eq.$currentUserId)');

      print("🔒 Block check result: $result");

      return result.isNotEmpty;
    } catch (e) {
      print("❌ Error in isUserBlocked: $e");
      return false;
    }
  }



  // ✅ XP Scaling: Increases at a steady rate per level
  int _getXPThreshold(int level) {
    return 100 * level; // Keeps XP progression balanced
  }

  // 🏆 Unlock Achievement When XP Milestone is Reached
  Future<void> unlockAchievement(String userId, String achievementTitle,
      String description, String iconUrl) async {
    try {
      // ✅ Check if the achievement is already unlocked
      final check = await supabase
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId)
          .eq('title', achievementTitle)
          .maybeSingle();

      if (check != null) {
        print("⚠️ Achievement '$achievementTitle' already unlocked.");
        return;
      }

      // ✅ Insert the unlocked achievement
      await supabase.from('user_achievements').insert({
        'user_id': userId,
        'title': achievementTitle,
        'description': description,
        'icon_url': iconUrl,
        'earned_at': DateTime.now().toIso8601String(),
      });

      print("🏆 Achievement Unlocked: $achievementTitle");
    } catch (error) {
      print("❌ Error unlocking achievement: $error");
    }
  }

  Future<void> generateAndInsertWeeklyAffirmations() async {
    final openRouterApiKey = dotenv.env['OPENROUTER_API_KEY'];

    if (openRouterApiKey == null || openRouterApiKey.isEmpty) {
      print("❌ OpenRouter API key not found in .env");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo", // You can upgrade this model if needed
          "messages": [
            {
              "role": "system",
              "content": "You are an AI generating positive daily affirmations."
            },
            {
              "role": "user",
              "content": "Create 7 unique short daily affirmations for the week. Keep them uplifting and spiritual."
            }
          ],
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'];

        if (choices == null || choices.isEmpty) {
          print("⚠️ No affirmations returned.");
          return;
        }

        final affirmationsText = choices[0]['message']['content'] as String;

        // Split affirmations into a list
        final List<String> affirmationsList = affirmationsText
            .split(RegExp(r'\d+\.\s')) // split by number + dot + space
            .where((text) => text.trim().isNotEmpty)
            .toList();

        // Insert affirmations into Supabase
        final today = DateTime.now();
        for (int i = 0; i < affirmationsList.length; i++) {
          final date = today.add(Duration(days: i));
          await Supabase.instance.client.from('affirmations').insert({
            'text': affirmationsList[i].trim(),
            'show_date': date.toIso8601String().substring(0, 10),
            'created_at': DateTime.now().toIso8601String(),
          });
          print("✅ Inserted affirmation for ${date.toIso8601String().substring(0, 10)}");
        }

        print("🎉 Weekly affirmations inserted successfully!");
      } else {
        print("❌ Failed to fetch affirmations: ${response.body}");
      }
    } catch (error) {
      print("❌ Error generating affirmations: $error");
    }
  }

  Future<void> submitRating(int ratingValue, String businessId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print("❌ User not logged in!");
        return;
      }

      await supabase.from('ratings').upsert({
        'user_id': userId,
        'business_id': businessId,
        'rating': ratingValue,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, business_id');

      print("✅ Rating submitted!");

      await updateAverageRating(businessId); // ⬅️ Update after submit
    } catch (error) {
      print("❌ Error submitting rating: $error");
    }
  }


  Future<void> updateAverageRating(String businessId) async {
    try {
      final response = await supabase
          .from('ratings')
          .select('rating')
          .eq('business_id', businessId);

      if (response.isEmpty) {
        print("⚠️ No ratings found for business $businessId");
        return;
      }

      double total = 0;
      for (var rating in response) {
        total += rating['rating'];
      }

      final double average = total / response.length;

      await supabase.from('service_ads').update({
        'rating': average,
      }).eq('user_id', businessId);

      print("✅ Average rating updated: $average ⭐");
    } catch (error) {
      print("❌ Error updating average rating: $error");
    }
  }

  Future<void> setActiveChat(String receiverId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('active_chats').upsert({
      'user_id': userId,
      'chatting_with': receiverId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearActiveChat() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('active_chats').delete().eq('user_id', userId);
  }

  Future<bool> isUserChattingWith(String userId, String receiverId) async {
    final result = await supabase
        .from('active_chats')
        .select()
        .eq('user_id', receiverId)
        .eq('chatting_with', userId)
        .maybeSingle();

    return result != null;
  }


  Future<double> fetchAverageRating(String businessId) async {
    try {
      final response = await supabase
          .from('service_ads')
          .select('rating')
          .eq('user_id', businessId)
          .single();

      if (response == null || response['rating'] == null) {
        print("⚠️ No average rating found.");
        return 0.0;
      }

      final avgRating = response['rating'] as double;
      print("✅ Average rating fetched: $avgRating ⭐");

      return avgRating;
    } catch (error) {
      print("❌ Error fetching average rating: $error");
      return 0.0;
    }
  }

  Future<void> updateMessageStatus(String messageId, {bool seen = false, bool delivered = false}) async {
    await supabase.from('messages').update({
      if (seen) 'seen': true,
      if (delivered) 'delivered': true,
    }).eq('id', messageId);
  }

  Future<void> markFirstMessagePopupShown(String userId, String receiverId) async {
    try {
      await supabase.from('messages_first_popup').insert({
        'sender_id': userId,
        'receiver_id': receiverId,
        'shown': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ First message popup recorded.");
    } catch (error) {
      print("❌ Error marking first message popup: $error");
    }
  }

  Future<bool> hasSeenFirstMessagePopup(String userId, String receiverId) async {
    try {
      final response = await supabase
          .from('messages_first_popup')
          .select('id')
          .eq('sender_id', userId)
          .eq('receiver_id', receiverId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      print("❌ Error checking first message popup: $error");
      return false;
    }
  }

  Future<void> declineFriendRequest(String senderId, String receiverId) async {
    try {
      await Supabase.instance.client
          .from('friend_requests')
          .delete()
          .match({'sender_id': senderId, 'receiver_id': receiverId});
    } catch (error) {
      print("❌ Error declining friend request: $error");
    }
  }

  Future<bool> deleteUserAndRelatedData(String userId) async {
    try {
      // 1️⃣ Delete from soul_matches where user is involved
      await supabase
          .from('soul_matches')
          .delete()
          .or('user_id.eq.$userId,matched_user_id.eq.$userId');

      // 2️⃣ Delete friend connections
      await supabase
          .from('friends')
          .delete()
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      // 3️⃣ Delete friend requests
      await supabase
          .from('friend_requests')
          .delete()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId');

      // 4️⃣ Delete messages
      await supabase
          .from('messages')
          .delete()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId');

      // 5️⃣ Delete milestones
      await supabase
          .from('milestones')
          .delete()
          .eq('user_id', userId);

      // 6️⃣ Delete blocked users records
      await supabase
          .from('blocked_users')
          .delete()
          .or('blocker_id.eq.$userId,blocked_id.eq.$userId');

      // 7️⃣ Delete notifications
      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      // 8️⃣ Finally delete profile
      final response = await supabase
          .from('profiles')
          .delete()
          .eq('id', userId)
          .select();

      if (response != null && response.isNotEmpty) {
        print('✅ User $userId and related data deleted successfully.');
        return true;
      } else {
        print('❌ Failed to delete user profile.');
        return false;
      }
    } catch (error) {
      print('❌ Error deleting user and related data: $error');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await supabase
          .from('profiles')
          .delete()
          .eq('id', userId);

      print("✅ User profile deleted: $userId");

      // Optional: Delete milestones or other user data here
      // await supabase.from('milestones').delete().eq('user_id', userId);

      return true;
    } catch (error) {
      print("❌ Error deleting user: $error");
      return false;
    }
  }

  Future<bool> restoreSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        print("🔄 Session Restored!");
        return true;
      } else {
        print("❌ No active session found! User must log in.");
        return false;
      }
    } catch (error) {
      print("❌ Error restoring session: $error");
      return false;
    }
  }

  // 🔮 1. Save Dream Journal Entry
  Future<void> saveDream(String text) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('dream_journal').insert({
      'user_id': userId,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 🧬 2. Save Past Life Journal Entry
  Future<void> savePastLife(String text) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('past_life_journal').insert({
      'user_id': userId,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 🌕 3. Log Moon Phase & Ritual
  Future<void> logMoon(String phase, String ritual) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('moon_logs').insert({
      'user_id': userId,
      'phase': phase,
      'ritual': ritual,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 🦉 4. Save Spirit Animal
  Future<void> saveSpiritAnimal(String message) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('spirit_animals').insert({
      'user_id': userId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 📅 5. Save Calendar Event
  Future<void> saveSpiritualEvent(String title, String date) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('spiritual_events').insert({
      'user_id': userId,
      'event_title': title,
      'event_date': date,
      'created_at': DateTime.now().toIso8601String(),
    });
  }



  Future<void> deleteBusinessAd(String ownerId) async {
    try {
      await Supabase.instance.client
          .from('service_ads')
          .delete()
          .eq('owner_id', ownerId); // Or adId if you have a separate column!
    } catch (error) {
      print('❌ Failed to delete ad: $error');
      throw error;
    }
  }

  Future<void> signOutUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('profiles').update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
    await Supabase.instance.client.auth.signOut();
  }


  // ✅ Set User Online/Offline
  Future<void> updateOnlineStatus(bool isOnline) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('profiles').update({
        'is_online': isOnline,
        'last_active': DateTime.now().toIso8601String(), // ✅ Update last seen
      }).eq('id', userId);

      print("✅ User online status updated: ${isOnline ? 'Online' : 'Offline'}");
    } catch (error) {
      print("❌ Error updating online status: $error");
    }
  }
  // 🔔 Send Push Notification Function
  Future<void> createAndSendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📢 Trying to insert notification into Supabase...');

      await Supabase.instance.client.from('notifications').insert({
        'user_id': recipientId,
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'message_data': data ?? {},
      });

      print('✅ Notification inserted into Supabase');

      // Fetch their FCM token
      final recipientProfile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('id', recipientId)
          .maybeSingle();

      final fcmToken = recipientProfile?['fcm_token'] ?? '';

      if (fcmToken == null || fcmToken.isEmpty) {
        print("⚠️ No FCM token found for user: $recipientId");
        return;
      }

      print('📢 Now sending push notification via FCM...');

      await PushNotificationService.sendPushNotification(
        fcmToken: fcmToken,
        title: title,
        body: body,
      );

      print("✅ Push notification sent via FCM successfully!");

    } catch (error) {
      print("❌ Error in createAndSendNotification: $error");
    }
  }



  // ✅ Update XP & Level
  Future<void> updateSpiritualXP(String userId, int xpEarned) async {
    try {
      // 🔍 Fetch current XP & Level from Supabase
      final response = await supabase
          .from('profiles')
          .select('spiritual_xp, spiritual_level')
          .eq('id', userId)
          .single();

      if (response == null) return;

      int currentXP = response['spiritual_xp'] ?? 0;
      int currentLevel = response['spiritual_level'] ?? 1;
      int xpThreshold = _getXPThreshold(currentLevel);
      int newXP = currentXP + xpEarned;
      int newLevel = currentLevel;

      // 🔥 Level Up Mechanic
      if (newXP >= xpThreshold) {
        newLevel += 1;
        newXP = newXP - xpThreshold; // Keep extra XP instead of resetting to 0
      }

      // ✅ Update Supabase with new XP & Level
      await supabase.from('profiles').update({
        'spiritual_xp': newXP,
        'spiritual_level': newLevel,
      }).eq('id', userId);

      print("🎯 XP Updated: $newXP / $xpThreshold | Level: $newLevel");

      // 🏆 Unlock Achievements at Specific Levels
      if (newLevel == 1) {
        await unlockAchievement(userId, "Soul Spark", "Just getting started!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Soul%20Spark.gif");
      }
      if (newLevel == 2) {
        await unlockAchievement(
            userId, "Energy Riser", "You're gaining momentum!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Energy%20Riser.gif");
      }
      if (newLevel == 3) {
        await unlockAchievement(userId, "Vibe Lifter", "Your presence is felt!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Vibe%20Lifter.gif");
      }
      if (newLevel == 4) {
        await unlockAchievement(
            userId, "Aura Shiner", "Bringing light to the space!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Aura%20Shiner.gif");
      }
      if (newLevel == 5) {
        await unlockAchievement(
            userId, "Harmony Seeker", "Balanced and engaged!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Harmony%20Seeker.gif");
      }
      if (newLevel == 6) {
        await unlockAchievement(
            userId, "Karma Builder", "Spreading positivity!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Karma%20Builder.gif");
      }
      if (newLevel == 7) {
        await unlockAchievement(userId, "Zen Flow", "You're in the rhythm now!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Zen%20Flow.gif");
      }
      if (newLevel == 8) {
        await unlockAchievement(
            userId, "Cosmic Connector", "Making waves in the universe!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Cosmic%20Connector.gif");
      }
      if (newLevel == 9) {
        await unlockAchievement(
            userId, "Ethereal Radiance", "You glow with energy!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Ethereal%20Radiance.gif");
      }
      if (newLevel == 10) {
        await unlockAchievement(
            userId, "Galactic Trailblazer", "A legendary presence!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Galactic%20Trailblazer.gif");
      }
    } catch (error) {
      print("❌ Error updating XP: $error");
    }
  }

  Future<List<Map<String, dynamic>>> getMessagedUsers(String userId, {bool friendsOnly = false}) async {
    final response = await supabase
        .from('messages')
        .select('receiver_id, sender_id')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId');

    if (response == null || response.isEmpty) return [];

    // Extract user IDs
    final Set<String> userIds = {};

    for (var msg in response) {
      if (msg['sender_id'] != userId) {
        userIds.add(msg['sender_id']);
      }
      if (msg['receiver_id'] != userId) {
        userIds.add(msg['receiver_id']);
      }
    }

    if (userIds.isEmpty) return [];

    final profiles = await supabase
        .from('profiles')
        .select('*')
        .inFilter('id', userIds.toList());

    if (friendsOnly) {
      // Add your friend filter logic here
      profiles.removeWhere((profile) => !profile['is_friend']);
    }

    return profiles;
  }


  // ✅ Fetch Achievements for a User
  Future<List<Map<String, dynamic>>> fetchUserAchievements(String userId) async {
    try {
      print("🔎 Fetching user achievements for: $userId");

      final response = await Supabase.instance.client
          .from('user_achievements') // ✅ Correct table
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false); // ✅ Show newest first

      if (response.isEmpty) {
        print("⚠️ No achievements found for user: $userId");
        return [];
      }

      print("✅ Achievements found: $response");

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print("❌ Error fetching achievements: $error");
      return [];
    }
  }


  // ✅ Fetch all users, excluding superadmins
  Future<List<Map<String, dynamic>>> getLimitedUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .neq('role', 'superadmin') // Exclude superadmins
          .neq('role', 'admin') // Exclude admins
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error fetching limited users: $e");
      return [];
    }
  }


// ✅ Fetch limited notifications (Exclude notifications related to admins or superadmins)
  Future<List<Map<String, dynamic>>> _fetchLimitedNotifications() async {
    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .neq('user_id', 'admin') // Exclude admin notifications
          .neq('user_id', 'superadmin') // Exclude superadmin notifications
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error fetching limited notifications: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLatestUsers({int limit = 10}) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, name, avatar')
          .order('created_at', ascending: false)
          .limit(limit);

      print("✅ Latest users fetched: $response");

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching latest users: $e');
      return [];
    }
  }
  // Fetch Top Users for the Leaderboard
  Future<List<UserModel>> fetchTopUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, avatar, spiritual_xp, spiritual_level')
          .order('spiritual_xp', ascending: false) // Sort by highest XP
          .limit(10); // Only show top 10

      return response.map<UserModel>((data) => UserModel.fromJson(data))
          .toList();
    } catch (error) {
      print("Error fetching leaderboard: $error");
      return [];
    }
  }


  Future<bool> checkIfFriends(String userId, String targetUserId) async {
    try {
      final response = await supabase
          .from('friends')
          .select('status')
          .or('and(user_id.eq.$userId,friend_id.eq.$targetUserId),and(user_id.eq.$targetUserId,friend_id.eq.$userId)')
          .eq('status', 'accepted');

      return response != null && response.isNotEmpty;
    } catch (error) {
      print("❌ Error in checkIfFriends: $error");
      return false;
    }
  }
// ✅ Send a Friend Request
  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // ✅ Check if a request already exists
      final existingRequest = await supabase
          .from('friend_requests')
          .select('id')
          .or('and(sender_id.eq.$senderId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        print("⚠️ Friend request already pending.");
        return false;
      }
// ✅ Insert new request
      await supabase.from('friend_requests').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ Friend request sent!");
      // ✅ Send notification after sending friend request
      // 🔥 Fetch sender’s name
      final senderProfile = await getUserProfile(senderId);
      final senderName = senderProfile?.name ?? 'Someone';

      await createAndSendNotification(
        recipientId: receiverId,
        title: '👤 Friend Request',
        body: '$senderName sent you a friend request!',
        type: 'friend_request',
      );



      print("✅ Friend request sent!");
      return true;
    } catch (error) {
      print("❌ Error sending friend request: $error");
      return false;
    }
  }
  // ✅ Accept a Friend Request
  Future<bool> acceptFriendRequest(String userId, String friendId) async {
    try {
      // ✅ Step 1: Update request to 'accepted'
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .match({'sender_id': friendId, 'receiver_id': userId});

      // ✅ Step 2: Insert both directions into friends table
      await supabase.from('friends').insert([
        {'user_id': userId, 'friend_id': friendId, 'status': 'accepted'},
        {'user_id': friendId, 'friend_id': userId, 'status': 'accepted'},
      ]);

      // ✅ Step 3: Send notification
      // 🔥 Fetch the name of the user who accepted
      final userProfile = await getUserProfile(userId);
      final userName = userProfile?.name ?? 'Someone';

      await createAndSendNotification(
        recipientId: friendId,
        title: '🎉 Friend Request Accepted!',
        body: '$userName accepted your friend request!',
        type: 'friend_accept',
      );


      print("✅ Friend request accepted and friendship created.");
      return true;
    } catch (error) {
      print("❌ Error accepting friend request: $error");
      return false;
    }
  }

  // ✅ Remove a Friend
  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      await supabase
          .from('friends')
          .delete()
          .match({'user_id': userId, 'friend_id': friendId});
      await supabase
          .from('friends')
          .delete()
          .match({'user_id': friendId, 'friend_id': userId});
      return true;
    } catch (error) {
      print("Error removing friend: $error");
      return false;
    }
  }

  Future<bool> hasReceiverReplied(String userId, String receiverId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('id')
          .eq('sender_id', receiverId)
          .eq('receiver_id', userId)
          .limit(1)
          .maybeSingle();

      final replied = response != null;
      print('🔍 Has receiver replied? $replied');
      return replied;
    } catch (error) {
      print('❌ Error checking reply status: $error');
      return false;
    }
  }

// ✅ Fetch messages between two users
  Future<List<Map<String, dynamic>>> fetchMessages(String userId, String friendId) async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, receiver_id, message, created_at')
          .or('and(sender_id.eq.$userId,receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.$userId)')
          .order('created_at', ascending: true);

      print("✅ Messages fetched: ${response.length}");

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print("❌ Error fetching messages: $error");
      return [];
    }
  }

  Future<String> getMysticBirthReading(String dob) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      print("❌ No API key found!");
      return 'AI service unavailable. Please try again later.';
    }

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {
              "role": "user",
              "content":
              "Give me a deep, spiritual, and mystical explanation of the date of birth \"$dob\". Include spiritual birthstones, zodiac influences, and life path insights in a positive, mobile-friendly way."
            }
          ],
          "max_tokens": 300
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print("✅ Mystic Birth Chart received!");
        return content;
      } else {
        print("❌ Failed to fetch Mystic Birth Chart: ${response.statusCode}");
        return 'No reading available. Please try again later.';
      }
    } catch (e) {
      print("❌ Mystic Birth Chart error: $e");
      return 'Error generating birth chart.';
    }
  }


  // ✅ Check Friendship Status
  Future<String> checkFriendshipStatus(String userId, String friendId) async {
    try {
      final response = await supabase
          .from('friends')
          .select('status')
          .or('user_id.eq.$userId, friend_id.eq.$friendId')
          .maybeSingle();

      if (response == null) return 'not_friends';
      return response['status'];
    } catch (error) {
      print("Error checking friendship status: $error");
      return 'error';
    }
  }

  Future<int> getPendingFriendRequestsCount(String userId) async {
    final response = await Supabase.instance.client
        .from('friend_requests')
        .select('id')
        .eq('receiver_id', userId)
        .eq('status', 'pending');

    return response.length;
  }
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      // 1️⃣ Check friendship status
      bool isFriend = await checkIfFriends(senderId, receiverId);

      // 2️⃣ If NOT friends, check limits
      if (!isFriend) {
        final receiverReplied = await hasReceiverReplied(senderId, receiverId);
        final messagesToday = await nonFriendMessageCountToday(senderId, receiverId);

        if (!receiverReplied && messagesToday >= 10) {
          print('🚫 Message limit reached.');
          return false; // Block the message!
        }
      }

      // 3️⃣ Insert the message
      final response = await supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'sent',
        'seen': false,
      }).select();

      if (response == null || response.isEmpty) {
        print('❌ Message insertion failed.');
        return false;
      }

      print('✅ Message sent successfully!');
      return true;
    } catch (error) {
      print('❌ Error sending message: $error');
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      print('✅ Message deleted: $messageId');
      return true;
    } catch (error) {
      print('❌ Error deleting message: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchTodaysAffirmation() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

      final response = await Supabase.instance.client
          .from('affirmations')
          .select()
          .eq('show_date', today) // <- This field!
          .maybeSingle();

      if (response != null) {
        print("✅ Affirmation for today: ${response['text']}");
        return response;
      } else {
        print("⚠️ No affirmation found for today.");
        return null;
      }
    } catch (error) {
      print("❌ Error fetching affirmation: $error");
      return null;
    }
  }
  Future<int> nonFriendMessageCountToday(String userId, String receiverId) async {
    try {
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10); // 'YYYY-MM-DD'

      final response = await supabase
          .from('messages')
          .select('id')
          .eq('sender_id', userId)
          .eq('receiver_id', receiverId)
          .gte('created_at', '${today}T00:00:00Z') // ✅ Correct now!
          .lte('created_at', '${today}T23:59:59Z') // ✅ Correct now!
          .neq('status', 'deleted');               // ✅ Don't count deleted messages!

      final count = response.length;
      print('📅 Messages sent today to $receiverId: $count');
      return count;
    } catch (error) {
      print('❌ Error counting today messages: $error');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPastLifeEntries() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('past_life_journal')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching past life entries: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchMoonLogs() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('moon_logs')
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching moon logs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSpiritAnimals() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('spirit_animals')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching spirit animal data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventbriteEvents() async {
    final apiKey = dotenv.env['EVENTBRITE_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ No Eventbrite API Key found in .env");
      return [];
    }

    try {
      final url = Uri.parse(
        'https://www.eventbriteapi.com/v3/events/search/?q=spirituality&location.address=london&token=$apiKey',
      );

      final response = await http.get(url);

      print("📡 Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = List<Map<String, dynamic>>.from(data['events']);

        print("✅ ${events.length} events fetched.");

        return events.map((event) {
          return {
            'name': event['name']['text'] ?? 'Unnamed Event',
            'startTime': event['start']['local'] ?? '',
            'url': event['url'] ?? '',
            'location': event['online_event'] == true ? 'Online' : 'In Person',
          };
        }).toList();
      } else {
        print("❌ Failed to fetch events: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Exception: $e");
      return [];
    }
  }

  Future<String> interpretDream(String dream) async {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${dotenv.env['OPENROUTER_API_KEY']}',
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
            "You are a spiritual dream interpreter. Given dream details, return a helpful and deep interpretation in under 100 words. Be clear and insightful."
          },
          {
            "role": "user",
            "content": dream
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to interpret dream');
    }
  }

  // ✅ Fetch Friend List
  Future<List<Map<String, dynamic>>> getFriendsList(String userId) async {
    try {
      final response = await supabase
          .from('friends')
          .select('friend_id, profile:profiles!fk_friend_profile(name, avatar)')

          .eq('user_id', userId)
          .eq('status', 'accepted');

      return response ?? [];
    } catch (error) {
      print("Error fetching friends list: $error");
      return [];
    }
  }
  // ✅ Fetch Blocked Users
  Future<List<Map<String, dynamic>>> getBlockedUsers(String userId) async {
    try {
      final response = await supabase
          .from('blocked_users')
          .select('blocked_id, profiles:blocked_id (id, name, avatar)')
          .eq('blocker_id', userId);

      print('✅ Blocked users fetched: ${response.length} users.');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching blocked users: $error');
      return [];
    }
  }

  Future<bool> isViewerBlocked(String viewerId, String profileOwnerId) async {
    try {
      final result = await Supabase.instance.client
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', profileOwnerId)  // Profile owner is the blocker
          .eq('blocked_id', viewerId);       // Viewer is the blocked person

      return result.isNotEmpty; // ✅ viewer has been blocked BY profile owner
    } catch (e) {
      print('❌ Error in isViewerBlocked: $e');
      return false;
    }
  }







  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      final response = await supabase
          .from('profiles')
          .select('id, name, avatar, spiritual_path')
          .order('name', ascending: true);

      if (currentUserId != null) {
        return response.where((user) => user['id'] != currentUserId).toList();
      }

      return response ?? [];
    } catch (error) {
      print("Error fetching users: $error");
      return [];
    }
  }
}
