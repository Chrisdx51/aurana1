import 'dart:convert'; // ⬅️ Make sure this is at the top of your file
import 'package:http/http.dart' as http; // ⬅️ Add this import too
import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart'; // ✅ for PostgresChangeEvent (optional, depends on version)
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../models/milestone_model.dart';

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
        'target_type': targetType, // Now this matches your AllAdsPage call
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Report submitted: $targetType reported by $reporterId');
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
  // Upload Media to Supabase Storage
  Future<String?> uploadMedia(File mediaFile) async {
    final fileExt = mediaFile.path.split('.').last;
    final fileName = 'milestone_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      // Upload the file
      final storageResponse = await Supabase.instance.client.storage
          .from('milestone_media') // ✅ Fixed bucket name
          .upload(fileName, mediaFile);

      if (storageResponse.isEmpty) {
        print('❌ Upload failed: empty response');
        return null;
      }

      // Get the public URL
      final publicUrl = Supabase.instance.client.storage
          .from('milestone_media') // ✅ Fixed bucket name
          .getPublicUrl(fileName);

      print('✅ Uploaded! Public URL: $publicUrl');
      return publicUrl;
    } catch (error) {
      print('❌ Error uploading media: $error');
      return null;
    }
  }


// ✅ Fetch Recent Users (Last X Users Logged In)
  // ✅ Fetch Recent Users (Returns List<UserModel>)
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
      final response = await supabase
          .from('service_ads')
          .select('''
          id,
          user_id,
          name,
          business_name,
          service_type,
          tagline,
          description,
          price,
          phone_number,
          profile_image_url,
          show_profile,
          created_at
        ''')
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        print("⚠️ No business ads found.");
        return [];
      }

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
  Future<List<MilestoneModel>> fetchMilestones({
    String? userId,
    bool global = false,
  }) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        print("❌ No user logged in!");
        return [];
      }

      final queryBuilder = supabase
          .from('milestones');

      // 🌎 Cosmic Flow: Show public posts
      if (global) {
        print("🔵 Loading Cosmic Flow (Public Wall)");

        final response = await queryBuilder
            .select('''
            *,
            profiles (
              username,
              avatar
            )
          ''')
            .eq('visibility', 'open')
            .order('created_at', ascending: false);

        print('✅ Cosmic Flow Milestones fetched: ${response.length}');
        return response.map((e) => MilestoneModel.fromMap(e)).toList();

      } else {
        // 🧘 Inner Realm: Show ONLY posts by userId (private & public)
        print("🟣 Loading Inner Realm (User Wall)");

        final response = await queryBuilder
            .select('''
            *,
            profiles (
              username,
              avatar
            )
          ''')
            .eq('user_id', userId ?? user.id)
            .order('created_at', ascending: false);

        print('✅ Inner Realm Milestones fetched: ${response.length}');
        return response.map((e) => MilestoneModel.fromMap(e)).toList();
      }

    } catch (e) {
      print('❌ Error fetching milestones: $e');
      return [];
    }
  }

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
  Future<bool> isUserBlocked(String blockerId, String blockedId) async {
    try {
      final existingBlock = await supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId)
          .maybeSingle();

      return existingBlock != null;
    } catch (error) {
      print("❌ Error checking block status: $error");
      return false;
    }
  }

  // Energy Boost Function
  Future<bool> addEnergyBoost(String milestoneId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print("Error: User not logged in.");
      return false;
    }

    try {
      final response = await supabase.rpc(
        'increment_energy_boost',
        params: {'milestone_id': milestoneId},
      );

      if (response == null) {
        print("Error: Supabase RPC returned null.");
        return false;
      }

      await supabase.from('milestone_boosts').insert({
        'user_id': userId,
        'milestone_id': milestoneId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      print("Error boosting milestone: $error");
      return false;
    }
  }
  // Delete Milestone Post
  Future<bool> deleteMilestone(String milestoneId) async {
    try {
      await supabase
          .from('milestones')
          .delete()
          .eq('id', milestoneId);

      print("✅ Milestone deleted successfully!");
      return true;
    } catch (error) {
      print("❌ Error deleting milestone: $error");
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


  Future<void> toggleLike(String milestoneId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print("❌ Error: User not logged in.");
      return;
    }

    try {
      // Check if the user already liked the post
      final existingLike = await supabase
          .from('milestone_likes')
          .select('id')
          .eq('milestone_id', milestoneId)
          .eq('user_id', userId)
          .maybeSingle();

      // 👉 Fetch milestone info to get the post owner!
      final milestone = await supabase
          .from('milestones')
          .select('user_id, content')
          .eq('id', milestoneId)
          .maybeSingle();

      final postOwnerId = milestone?['user_id'];
      final milestoneContent = milestone?['content'] ?? '';

      if (existingLike != null) {
        // Unlike (Delete the like)
        await supabase
            .from('milestone_likes')
            .delete()
            .eq('milestone_id', milestoneId)
            .eq('user_id', userId);

        print("👍 Like removed successfully.");
      } else {
        // Like (Insert a new like)
        await supabase.from('milestone_likes').insert({
          'milestone_id': milestoneId,
          'user_id': userId,
        });

        print("❤️ Liked successfully.");

        // 🚀 Send Notification (Only if NOT your own post!)
        if (postOwnerId != null && postOwnerId != userId) {
          await createAndSendNotification(
            recipientId: postOwnerId,
            title: "✨ New Like!",
            body: "Someone liked your post: $milestoneContent",
            type: "like",
          );
        }
      }
    } catch (error) {
      print("❌ Error toggling like: $error");
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
  static Future<void> sendPushNotification(String fcmToken, String title, String body) async {
    final String serverKey = dotenv.env['FIREBASE_SERVER_KEY'] ?? '';

    if (serverKey.isEmpty) {
      print("❌ Firebase Server Key not found in .env!");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully!');
      } else {
        print('❌ Failed to send notification: ${response.body}');
      }
    } catch (error) {
      print('❌ Error sending notification: $error');
    }
  }

  Future<void> createAndSendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type, // e.g. 'friend_request', 'friend_accept'
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1️⃣ Save the notification in Supabase DB
      await Supabase.instance.client.from('notifications').insert({
        'user_id': recipientId,
        'notification_type': type,
        'title': title,
        'body': body,
        'has_read': false,
        'message_data': data ?? {},
      });

      // 2️⃣ Fetch their FCM token
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

      // 3️⃣ Send Push Notification
      await sendPushNotification(fcmToken, title, body);

      print("✅ Push notification sent!");
    } catch (error) {
      print("❌ Error sending notification: $error");
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
  // ✅ Get Last Milestone ID for a User
  Future<String?> getLastMilestoneId(String userId) async {
    try {
      final response = await supabase
          .from('milestones')
          .select('id, user_id, content, media_url, visibility, profiles!inner(name, avatar)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response.containsKey('id')) {
        return response['id'] as String;
      }
    } catch (error) {
      print("❌ Error fetching last milestone ID: $error");
    }
    return null;
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

// ✅ Fetch limited posts (Excluding posts made by Admins or Superadmins)
  Future<List<MilestoneModel>> fetchLimitedMilestones() async {
    try {
      final response = await supabase.from('milestones')
          .select('*')
          .neq('created_by', 'admin') // Exclude admin posts
          .neq('created_by', 'superadmin') // Exclude superadmin posts
          .order('created_at', ascending: false);
      return List<MilestoneModel>.from(response.map((x) => MilestoneModel.fromJson(x)));
    } catch (e) {
      print("❌ Error fetching limited milestones: $e");
      return [];
    }
  }

// ✅ Fetch limited reports (Excluding Superadmin-related reports)
  Future<List<Map<String, dynamic>>> _fetchLimitedReports() async {
    try {
      final response = await supabase
          .from('reports')
          .select('*')
          .neq('reporter_id', 'superadmin') // Exclude reports by superadmins
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error fetching limited reports: $e");
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
          .or('and(user_id.eq.$userId, friend_id.eq.$targetUserId), and(user_id.eq.$targetUserId, friend_id.eq.$userId)')
          .eq('status', 'accepted')
          .maybeSingle();

      return response != null;
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
      await createAndSendNotification(
        recipientId: receiverId,
        title: '👤 Friend Request',
        body: 'You have a new friend request!',
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
      // ✅ Update friend request status to accepted
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .match({'sender_id': friendId, 'receiver_id': userId});

      // ✅ Insert friendship ONLY if it doesn't exist
      final existingFriendship = await supabase
          .from('friends')
          .select('id')
          .or('and(user_id.eq.$userId, friend_id.eq.$friendId), and(user_id.eq.$friendId, friend_id.eq.$userId)')
          .maybeSingle();

      if (existingFriendship != null) {
        print("⚠️ Friendship already exists!");
        return false;
      }

      // ✅ Insert both records for each user
      await supabase.from('friends').insert([
        {'user_id': userId, 'friend_id': friendId, 'status': 'accepted'},
        {'user_id': friendId, 'friend_id': userId, 'status': 'accepted'},
      ]);

      // ✅ Delete the friend request (optional cleanup)
      await supabase
          .from('friend_requests')
          .delete()
          .match({'sender_id': friendId, 'receiver_id': userId});

      // ✅ Notify friend
      await createAndSendNotification(
        recipientId: friendId,
        title: '🎉 Friend Request Accepted!',
        body: 'You are now friends!',
        type: 'friend_accept',
      );

      print("✅ Friend request accepted, friendship established.");
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
          .select('id, sender_id, receiver_id, message, created_at') // ✅ fixed field name          .or('and(sender_id.eq.$userId,receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.$userId)')
          .order('created_at', ascending: true); // Show oldest first

      print("✅ Messages fetched: ${response.length}");

      return response;
    } catch (error) {
      print("❌ Error fetching messages: $error");
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchMessageThread(String userId, String receiverId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('id, sender_id, receiver_id, message, created_at')
          .or('and(sender_id.eq.$userId, receiver_id.eq.$receiverId), and(sender_id.eq.$receiverId, receiver_id.eq.$userId)')
          .order('created_at', ascending: true);

      print('✅ Fetched message thread. Count: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching message thread: $error');
      return [];
    }
  }



  Future<bool> addMilestone(String userId, String content, String milestoneType, String? mediaUrl, String visibility) async {
    try {
      final response = await supabase.from('milestones').insert({
        'user_id': userId,
        'content': content,
        'milestone_type': milestoneType,
        'created_at': DateTime.now().toIso8601String(),
        'energy_boosts': 0, // Default boost count
        'media_url': mediaUrl, // If media exists
        'visibility': visibility, // ✅ Store visibility (public or sacred)
      }).select();

      // ✅ Now you can check if response has something inside
      if (response != null && response.isNotEmpty) {
        print("✅ Milestone added successfully: $response");
        return true;
      } else {
        print("❌ No response returned from milestone insert.");
        return false;
      }

    } catch (error) {
      print("❌ Supabase Error adding milestone: $error");
      return false;
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



  // ✅ Fetch Friend List
  Future<List<Map<String, dynamic>>> getFriendsList(String userId) async {
    try {
      final response = await supabase
          .from('friends')
          .select('friend_id, profiles(name, avatar)')
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
          .select('blocked_id, profiles!blocked_id(name, avatar)')
          .eq('blocker_id', userId);

      // Debug output
      print('✅ Blocked users fetched: ${response.length} users.');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching blocked users: $error');
      return [];
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
