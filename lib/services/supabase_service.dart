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

      // 🎯 XP needed to level up
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
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Soul_Spark.gif");
      }
      if (newLevel == 2) {
        await unlockAchievement(userId, "Energy Riser", "You're gaining momentum!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Energy_Riser.gif");
      }
      if (newLevel == 3) {
        await unlockAchievement(userId, "Vibe Lifter", "Your presence is felt!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Vibe_Lifter.gif");
      }
      if (newLevel == 4) {
        await unlockAchievement(userId, "Aura Shiner", "Bringing light to the space!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Aura_Shiner.gif");
      }
      if (newLevel == 5) {
        await unlockAchievement(userId, "Harmony Seeker", "Balanced and engaged!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Harmony_Seeker.gif");
      }
      if (newLevel == 6) {
        await unlockAchievement(userId, "Karma Builder", "Spreading positivity!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Karma_Builder.gif");
      }
      if (newLevel == 7) {
        await unlockAchievement(userId, "Zen Flow", "You're in the rhythm now!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Zen_Flow.gif");
      }
      if (newLevel == 8) {
        await unlockAchievement(userId, "Cosmic Connector", "Making waves in the universe!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Cosmic_Connector.gif");
      }
      if (newLevel == 9) {
        await unlockAchievement(userId, "Ethereal Radiance", "You glow with energy!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Ethereal_Radiance.gif");
      }
      if (newLevel == 10) {
        await unlockAchievement(userId, "Galactic Trailblazer", "A legendary presence!",
            "https://rhapqmquxypczswwmzun.supabase.co/storage/v1/object/public/achievements/Galactic_Trailblazer.gif");
      }

    } catch (error) {
      print("❌ Error updating XP: $error");
    }
  }

  // ✅ XP Scaling: Increases at a steady rate per level
  int _getXPThreshold(int level) {
    return 100 * level; // Keeps XP progression balanced
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
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      print("🔥 Achievements fetched: $response"); // ✅ Debugging Line

      return response.isNotEmpty ? List<Map<String, dynamic>>.from(response) : [];
    } catch (error) {
      print("❌ Error fetching achievements: $error");
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

  // ✅ Unlock Achievements and store in user_achievements
  Future<void> unlockAchievement(String userId, String achievementTitle, String description, String iconUrl) async {
    try {
      // ✅ Check if this achievement already exists in the main achievements table
      final existingAchievement = await supabase
          .from('achievements')
          .select('id')
          .eq('title', achievementTitle)
          .maybeSingle();

      int achievementId;
      if (existingAchievement == null) {
        // ✅ Insert the achievement into the achievements table if it doesn't exist
        final insertAchievement = await supabase.from('achievements').insert({
          'title': achievementTitle,
          'description': description,
          'icon_url': iconUrl,
        }).select().single();

        achievementId = insertAchievement['id'];
      } else {
        achievementId = existingAchievement['id'];
      }

      // ✅ Now check if the user has already unlocked this achievement
      final checkUserAchievement = await supabase
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      if (checkUserAchievement != null) {
        print("⚠️ User has already unlocked '$achievementTitle'.");
        return;
      }

      // ✅ Insert the unlocked achievement for this user
      await supabase.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,  // Linking to the correct achievement
        'earned_at': DateTime.now().toIso8601String(),
      });

      print("🏆 Achievement Unlocked: $achievementTitle");
    } catch (error) {
      print("❌ Error unlocking achievement: $error");
    }
  }
}