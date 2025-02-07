import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MedalService {
  static Future<void> awardMedal() async {
    final prefs = await SharedPreferences.getInstance();

    // Load existing medals
    List<String> medals = prefs.getStringList('medals') ?? [];

    // 🎖️ Add a new medal (Emoji-Based)
    medals.add("🏅"); // You can replace this with different medals if needed

    // Save updated medals
    await prefs.setStringList('medals', medals);
  }

  static Future<List<String>> getMedals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('medals') ?? [];
  }
}
