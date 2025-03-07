import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/milestone_model.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch User Profile from Supabase
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, email, bio, dob, icon, spiritual_path, element, spiritual_xp, spiritual_level, privacy') // ✅ Added privacy
          .eq('id', userId)
          .single();

      print("✅ Fetched DOB from Supabase: ${response['dob']}");


      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (error) {
      print("Error fetching user profile: $error");
    }
    return null;
  }

  // ✅ Fetch Recent Users (Last 5 Users Logged In)
  Future<List<UserModel>> getRecentUsers(int limit) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, icon, is_online') // ✅ Make sure 'is_online' is selected
          .order('last_active', ascending: false)
          .limit(limit);

      return response.map((user) => UserModel.fromJson(user)).toList();
    } catch (error) {
      print("❌ Error fetching recent users: $error");
      return [];
    }
  }

  Future<UserModel?> fetchUserProfileWithPrivacy(String viewerId, String targetUserId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, bio, dob, icon, privacy, spiritual_path, element, spiritual_xp, spiritual_level')
          .eq('id', targetUserId)
          .single();

      if (response == null) return null;

      String privacy = response['privacy'] ?? 'public';

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
  // Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      print("🔍 Checking if profile is complete for user: $userId");

      final response = await supabase
          .from('profiles')
          .select('name, bio, dob')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print("❌ Profile does not exist!");
        return false;
      }

      bool isComplete = response['name'] != null && response['name'].toString().isNotEmpty &&
          response['bio'] != null && response['bio'].toString().isNotEmpty &&
          response['dob'] != null;

      print("✅ Profile completeness result: $isComplete");

      return isComplete;
    } catch (error) {
      print("❌ Error checking profile completeness: $error");
      return false;
    }
  }

  Future<bool> updateProfilePrivacy(String userId, String newPrivacy) async {
    try {
      await supabase.from('profiles').update({'privacy': newPrivacy}).eq('id', userId);
      return true;
    } catch (error) {
      print('Error updating privacy: $error');
      return false;
    }
  }

  Future<bool> updateUserProfile(String userId,
      String name,
      String bio,
      String? dob,
      String? icon,
      String? spiritualPath,
      String? element,
      String? privacy, // ✅ Added privacy
      int spiritualXP,
      int spiritualLevel) async {
    try {
      print("🔄 Updating profile with DOB: $dob");
      print("🔄 Checking if profile exists in Supabase for user: $userId");

      // ✅ Check if the profile already exists
      final checkProfile = await supabase
          .from('profiles')
          .select('email') // Fetch email to avoid NULL constraint errors
          .eq('id', userId)
          .maybeSingle();

      if (checkProfile == null) {
        print('❌ Profile does not exist. Creating a new profile...');

        // 🔥 Fetch email from Auth table to ensure email is included
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null || user.email == null) {
          print("❌ Error: Cannot create profile without an email.");
          return false;
        }

        // ✅ Insert new profile with email
        await supabase.from('profiles').insert({
          'id': userId,
          'email': user.email, // Ensures email is not NULL
          'name': name,
          'bio': bio,
          'dob': dob,
          'icon': icon,
          'spiritual_path': spiritualPath,
          'element': element,
          'privacy': privacy, // ✅ Save privacy setting
          'spiritual_xp': spiritualXP,
          'spiritual_level': spiritualLevel,
        }) .select();
      } else {
        // ✅ Update existing profile
        final response = await supabase
            .from('profiles')
            .update({
          'name': name,
          'bio': bio,
          'dob': dob,
          'icon': icon,
          'spiritual_path': spiritualPath,
          'element': element,
          'spiritual_xp': spiritualXP,
          'spiritual_level': spiritualLevel,
        })
            .eq('id', userId)
            .select();

        if (response.isEmpty) {
          print('❌ Failed to update profile: No rows modified.');
          return false;
        }
      }

      print('✅ Profile updated successfully!');
      return true;
    } catch (error) {
      print('❌ Error updating profile: $error');
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
      final listResponse = await supabase.storage.from('profile_pictures').list(
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
  Future<String?> uploadMedia(File file) async {
    try {
      final String fileName = basename(file.path);
      final String filePath = "milestone_media/$fileName";

      await supabase.storage.from('milestone_media').upload(
        filePath,
        file,
        fileOptions: FileOptions(upsert: true),
      );

      final String publicUrl = supabase.storage.from('milestone_media')
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (error) {
      print("Error uploading media: $error");
      return null;
    }
  }
  // Add Milestone to Supabase Database
  Future<List<MilestoneModel>> fetchMilestones({String? userId, bool global = false}) async {
    try {
      var query = supabase.from('milestones').select('''
  id, user_id, content, milestone_type, media_url, created_at, 
  energy_boosts, like_count, comment_count, visibility,
  profiles(name, icon)  -- ✅ Fetch profile picture correctly
''');

      if (global) {
        query = query.eq('visibility', 'open'); // ✅ Fetch only public posts
      } else if (userId != null) {
        query = query.eq('user_id', userId); // ✅ Fetch only the user's posts
      }

      final response = await query; // ✅ Execute the query

      return response.map<MilestoneModel>((json) => MilestoneModel.fromJson(json)).toList();
    } catch (error) {
      print("❌ Error fetching milestones: $error");
      return [];
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
      final response = await supabase
          .from('milestones')
          .delete()
          .eq('id', milestoneId)
          .select();

      if (response is List && response.isNotEmpty) {
        print("Milestone deleted successfully from Supabase.");
        return true;
      } else {
        print("Supabase returned an empty response.");
        return false;
      }
    } catch (error) {
      print("Error deleting milestone: $error");
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
      }
    } catch (error) {
      print("❌ Error toggling like: $error");
    }
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
          .select('id, user_id, content, media_url, visibility, profiles!inner(name, icon)')
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

  // Fetch Top Users for the Leaderboard
  Future<List<UserModel>> fetchTopUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, icon, spiritual_xp, spiritual_level')
          .order('spiritual_xp', ascending: false) // Sort by highest XP
          .limit(10); // Only show top 10

      return response.map<UserModel>((data) => UserModel.fromJson(data))
          .toList();
    } catch (error) {
      print("Error fetching leaderboard: $error");
      return [];
    }
  }


// ✅ Send a Friend Request
  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // ✅ Check if a request already exists
      final existingRequest = await supabase
          .from('friends')
          .select('status')
          .or('and(user_id.eq.$senderId, friend_id.eq.$receiverId), and(user_id.eq.$receiverId, friend_id.eq.$senderId)')
          .maybeSingle();

      if (existingRequest != null) {
        print("⚠️ Friend request already exists.");
        return false;
      }

      // ✅ Insert a new friend request
      await supabase.from('friends').insert({
        'user_id': senderId,
        'friend_id': receiverId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // ✅ Send a notification to the receiver
      await supabase.from('notifications').insert({
        'user_id': receiverId,
        'type': 'friend_request',
        'message': 'You have a new friend request!',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      print("Error sending friend request: $error");
      return false;
    }
  }



  // ✅ Accept a Friend Request
  Future<bool> acceptFriendRequest(String userId, String friendId) async {
    try {
      await supabase
          .from('friends')
          .update({'status': 'accepted'})
          .match({'user_id': friendId, 'friend_id': userId});

      return true;
    } catch (error) {
      print("Error accepting friend request: $error");
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

      if (response.isNotEmpty) {
        print("✅ Milestone added successfully: $response");
        return true;
      } else {
        print("❌ Supabase returned empty response.");
        return false;
      }
    } catch (error) {
      print("❌ Supabase Error: $error");
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
  // ✅ Fetch Friend List
  Future<List<Map<String, dynamic>>> getFriendsList(String userId) async {
    try {
      final response = await supabase
          .from('friends')
          .select('friend_id, profiles(name, icon)')
          .eq('user_id', userId)
          .eq('status', 'accepted');

      return response ?? [];
    } catch (error) {
      print("Error fetching friends list: $error");
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      final response = await supabase
          .from('profiles')
          .select('id, name, icon, spiritual_path')
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

extension on PostgrestTransformBuilder<PostgrestList> {
  void eq(String s, String t) {}
}// Helper function to calculate XP threshold for each level