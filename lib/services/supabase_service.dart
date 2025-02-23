import 'dart:io';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/milestone_model.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // 🔥 Fetch User Profile from Supabase
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
      print("❌ Error fetching user profile: $error");
    }
    return null;
  }

  // 🔥 Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('name, bio, dob')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;

      return response['name'] != null &&
          response['bio'] != null &&
          response['dob'] != null;
    } catch (error) {
      print("❌ Error checking profile completeness: $error");
      return false;
    }
  }

  // ✅ Update User Profile in Supabase
  Future<bool> updateUserProfile(
      String userId, String name, String bio, String? dob, String? icon, String? spiritualPath, String? element) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({
        'name': name,
        'bio': bio,
        'dob': dob,
        'icon': icon,
        'spiritual_path': spiritualPath,
        'element': element,
      })
          .eq('id', userId)
          .select();

      if (response.isEmpty) {
        print('❌ Failed to update profile: No rows modified.');
        return false;
      }

      print('✅ Profile updated successfully!');
      return true;
    } catch (error) {
      print('❌ Error updating profile: $error');
      return false;
    }
  }

  // ✅ Upload Profile Picture to Supabase Storage (Fixed)
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = "avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.png";

      // ✅ Remove old profile picture
      final listResponse = await supabase.storage.from('profile_pictures').list(path: "avatars/");
      if (listResponse is List && listResponse.isNotEmpty) {
        for (var file in listResponse) {
          if (file.name.startsWith("$userId-")) {
            await supabase.storage.from('profile_pictures').remove(["avatars/${file.name}"]);
          }
        }
      }

      // ✅ Upload the new image
      await supabase.storage.from('profile_pictures').upload(
        fileName,
        imageFile,
        fileOptions: FileOptions(upsert: true),
      );

      // ✅ Retrieve and return the new public URL
      final String publicUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
      return publicUrl;
    } catch (error) {
      print("❌ Error uploading profile picture: $error");
      return null;
    }
  }

  // ✅ Upload Media to Supabase Storage
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
      print("❌ Error uploading media: $error");
      return null;
    }
  }

  // ✅ Fetch All Milestones from Supabase
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
      print("❌ Error fetching milestones: $error");
      return [];
    }
  }

  // ✅ Add Milestone to Supabase Database
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
        print("✅ Milestone added successfully: $response");
        return true;
      } else {
        print("❌ Supabase returned empty response");
        return false;
      }
    } catch (error) {
      print("❌ Supabase Error: $error");
      return false;
    }
  }

  // ✅ Energy Boost Function
  Future<bool> addEnergyBoost(String milestoneId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print("❌ Error: User not logged in.");
      return false;
    }

    try {
      final response = await supabase.rpc(
        'increment_energy_boost',
        params: {'milestone_id': milestoneId},
      );

      if (response == null) {
        print("❌ Error: Supabase RPC returned null. Possible causes: function missing, RLS blocking updates, or incorrect parameters.");
        return false;
      }

      // ✅ Log the boost to prevent multiple boosts per user
      await supabase.from('milestone_boosts').insert({
        'user_id': userId,
        'milestone_id': milestoneId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      print("❌ Error boosting milestone: $error");
      return false;
    }
  }


  // ✅ Delete Milestone Post
  Future<bool> deleteMilestone(String milestoneId) async {
    try {
      final response = await supabase
          .from('milestones')
          .delete()
          .eq('id', milestoneId)
          .select();

      if (response.isNotEmpty) {
        print("✅ Milestone deleted successfully from Supabase.");
        return true; // ✅ Only return success if Supabase confirms deletion
      } else {
        print("❌ Supabase returned an empty response.");
        return false;
      }
    } catch (error) {
      print("❌ Error deleting milestone: $error");
      return false;
    }
  }
}