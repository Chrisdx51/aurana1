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
          .select()
          .eq('id', userId)
          .single();

      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (error) {
      print("Error fetching user profile: $error");
    }
    return null;
  }

  // Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('name, bio, dob')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false; // No profile exists

      // Ensure all required fields are filled
      return response['name'] != null &&
          response['name'].toString().isNotEmpty &&
          response['bio'] != null &&
          response['bio'].toString().isNotEmpty &&
          response['dob'] != null;
    } catch (error) {
      print("Error checking profile completeness: $error");
      return false;
    }
  }

  Future<bool> updateUserProfile(
      String userId,
      String name,
      String bio,
      String? dob,
      String? icon,
      String? spiritualPath,
      String? element,
      int spiritualXP,
      int spiritualLevel) async {
    try {
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
          'spiritual_xp': spiritualXP,
          'spiritual_level': spiritualLevel,
        }).select();
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
      final String fileName = "avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.png";

      // Remove old profile picture if it exists
      final listResponse = await supabase.storage.from('profile_pictures').list(path: "avatars/");
      if (listResponse is List && listResponse.isNotEmpty) {
        for (var file in listResponse) {
          if (file.name.startsWith("$userId-")) {
            await supabase.storage.from('profile_pictures').remove(["avatars/${file.name}"]);
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
      final String publicUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
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

      final String publicUrl = supabase.storage.from('milestone_media').getPublicUrl(filePath);
      return publicUrl;
    } catch (error) {
      print("Error uploading media: $error");
      return null;
    }
  }

  // Fetch All Milestones from Supabase
  Future<List<MilestoneModel>> fetchMilestones({String sortBy = "Newest"}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    String orderColumn = "created_at";
    bool ascending = false;

    if (sortBy == "Oldest") {
      ascending = true;
    } else if (sortBy == "Most Boosted") {
      orderColumn = "energy_boosts";
      ascending = false;
    }

    try {
      final response = await supabase
          .from('milestones')
          .select('''
            id, user_id, content, milestone_type, created_at, energy_boosts, media_url, 
            profiles(name, icon), 
            milestone_boosts(user_id)
          ''')
          .order(orderColumn, ascending: ascending);

      if (response == null || response.isEmpty) {
        return [];
      }

      return response.map<MilestoneModel>((data) => MilestoneModel.fromJson({
        ...data,
        'user_boosted': data['milestone_boosts'] != null &&
            (data['milestone_boosts'] as List).any((boost) => boost['user_id'] == userId),
      })).toList();
    } catch (error) {
      print("Error fetching milestones: $error");
      return [];
    }
  }

  // Add Milestone to Supabase Database
  Future<bool> addMilestone(String userId, String content, String milestoneType, String? mediaUrl) async {
    try {
      final response = await supabase.from('milestones').insert({
        'user_id': userId,
        'content': content,
        'milestone_type': milestoneType,
        'created_at': DateTime.now().toIso8601String(),
        'energy_boosts': 0, // Default boost count
        'media_url': mediaUrl, // If media exists
      }).select();

      if (response.isNotEmpty) {
        print("Milestone added successfully: $response");
        return true;
      } else {
        print("Supabase returned empty response");
        return false;
      }
    } catch (error) {
      print("Supabase Error: $error");
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
      final response = await supabase
          .from('milestones')
          .delete()
          .eq('id', milestoneId)
          .select();

      if (response.isNotEmpty) {
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

  // ✅ Update XP and Unlock Achievements
  Future<void> updateSpiritualXP(String userId, int xpEarned) async {
    try {
      // Fetch current XP & Level
      final response = await supabase
          .from('profiles')
          .select('spiritual_xp, spiritual_level')
          .eq('id', userId)
          .single();

      if (response == null) return;

      int currentXP = response['spiritual_xp'] ?? 0;
      int currentLevel = response['spiritual_level'] ?? 1;

      // Add XP and calculate new level
      int newXP = currentXP + xpEarned;
      int xpThreshold = currentLevel * 100;
      int newLevel = currentLevel;

      if (newXP >= xpThreshold) {
        newLevel += 1;
        newXP = 0; // Reset XP after leveling up
      }

      // ✅ Update User XP and Level in Database
      await supabase.from('profiles').update({
        'spiritual_xp': newXP,
        'spiritual_level': newLevel,
      }).eq('id', userId);

      print("🔹 XP Updated: $newXP / $xpThreshold | Level: $newLevel");

      // ✅ Check if Achievements Should Unlock
      if (newLevel == 2) {
        await unlockAchievement(userId, "Level 2 - Rising Seeker", "You have reached level 2!", "https://example.com/level2_badge.png");
      }
      if (newLevel == 5) {
        await unlockAchievement(userId, "Level 5 - Ascended", "You are now an advanced seeker!", "https://example.com/level5_badge.png");
      }
      if (newLevel == 10) {
        await unlockAchievement(userId, "Master of Light", "You have reached the pinnacle of spiritual mastery.", "https://example.com/master_badge.png");
      }

    } catch (error) {
      print("❌ Error updating XP: $error");
    }
  }

  // XP Threshold Function (XP Required Increases per Level)
  int _getXPThreshold(int level) {
    if (level == 1) return 100;
    return (100 * level) + (level * 100); // Dynamic XP scaling
  }

  // Get Last Milestone ID for a User
  Future<String?> getLastMilestoneId(String userId) async {
    try {
      final response = await supabase
          .from('milestones')
          .select('id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic> && response.containsKey('id')) {
        return response['id'] as String;
      }
    } catch (error) {
      print("Error fetching last milestone ID: $error");
    }
    return null; // Return null if no milestone found
  }

  // Fetch Achievements for a User
  Future<List<Map<String, dynamic>>> fetchUserAchievements(String userId) async {
    try {
      final response = await supabase
          .from('achievements')
          .select('*')
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return response.isNotEmpty ? List<Map<String, dynamic>>.from(response) : [];
    } catch (error) {
      print("Error fetching achievements: $error");
      return [];
    }
  }

  // Fetch Top Users for the Leaderboard
  Future<List<UserModel>> fetchTopUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, icon, spiritual_xp, spiritual_level')
          .order('spiritual_xp', ascending: false) // Sort by highest XP
          .limit(10); // Only show top 10

      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (error) {
      print("Error fetching leaderboard: $error");
      return [];
    }
  }

  // 🔥 Unlock Achievement When XP Milestone is Reached
  Future<void> unlockAchievement(String userId, String achievementTitle, String description, String iconUrl) async {
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
}