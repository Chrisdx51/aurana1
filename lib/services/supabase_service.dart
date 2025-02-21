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
          .maybeSingle(); // ✅ FIX: Use `maybeSingle()` to avoid errors when no row exists

      if (response == null) return false;

      return response['name'] != null &&
          response['bio'] != null &&
          response['dob'] != null;
    } catch (error) {
      print("❌ Error checking profile completeness: $error");
      return false;
    }
  }

  // 🔥 Update Profile Picture URL in Supabase
  Future<bool> updateUserProfilePicture(String userId, String imageUrl) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({'icon': imageUrl})
          .eq('id', userId);

      return response.error == null;
    } catch (error) {
      print("❌ Error updating profile picture: $error");
      return false;
    }
  }

  // 🔥 Upload Profile Picture to Supabase Storage
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = "avatars/$userId.png";

      await supabase.storage.from('profile_pictures').upload(
        fileName,
        imageFile,
        fileOptions: FileOptions(upsert: true),
      );

      final String publicUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
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
