import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

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
          .maybeSingle(); // ✅ Avoids errors when no row exists

      if (response == null) return false;

      return response['name'] != null &&
          response['bio'] != null &&
          response['dob'] != null;
    } catch (error) {
      print("❌ Error checking profile completeness: $error");
      return false;
    }
  }

  // ✅ Update User Profile in Supabase (Now Includes Spiritual Path & Element)
  Future<bool> updateUserProfile(
      String userId,
      String name,
      String bio,
      String? dob,
      String? icon,
      String? spiritualPath,
      String? element,
      ) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({
        'name': name,
        'bio': bio,
        'dob': dob,
        'icon': icon,
        'spiritual_path': spiritualPath, // ✅ Saving Spiritual Path
        'element': element, // ✅ Saving Elemental Connection
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

  // 🔥 Upload Profile Picture to Supabase Storage
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = "avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.png";

      // ✅ First, remove any old profile pictures for this user
      final listResponse = await supabase.storage.from('profile_pictures').list(path: "avatars/");

      for (var file in listResponse) {
        if (file.name.startsWith("$userId-")) {
          await supabase.storage.from('profile_pictures').remove(["avatars/${file.name}"]);
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
      print("✅ Image uploaded: $publicUrl");

      return publicUrl;
    } catch (error) {
      print("❌ Error uploading profile picture: $error");
      return null;
    }
  }

  // 🔥 Upload Feed Photo to Supabase Storage
  Future<String?> uploadFeedPhoto(String userId, File imageFile) async {
    try {
      final String fileName = "feed/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage.from('feed_photos').upload(
        fileName,
        imageFile,
        fileOptions: FileOptions(upsert: true),
      );

      final String publicUrl = supabase.storage.from('feed_photos').getPublicUrl(fileName);
      return publicUrl;
    } catch (error) {
      print("❌ Error uploading feed photo: $error");
      return null;
    }
  }
}