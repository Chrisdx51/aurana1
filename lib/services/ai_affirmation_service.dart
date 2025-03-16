import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// STEP 1️⃣: Get your keys from .env
final String openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

// STEP 2️⃣: Create a Supabase Client
final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

// STEP 3️⃣: Generate Affirmation with OpenAI (Safe and Secure)
Future<String?> generateAffirmation() async {
  if (openAiApiKey.isEmpty) {
    print("❌ Missing OpenAI API Key in .env!");
    return null;
  }

  final prompt = "Give me one unique and powerful daily affirmation for spiritual growth. Keep it uplifting and positive.";

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAiApiKey',
    },
    body: jsonEncode({
      "model": "text-davinci-003",
      "prompt": prompt,
      "max_tokens": 60,
      "temperature": 0.8,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final text = data['choices'][0]['text'].trim();
    print('✅ Affirmation generated: $text');
    return text;
  } else {
    print('❌ Failed to generate affirmation: ${response.body}');
    return null;
  }
}

// STEP 4️⃣: Save Affirmation to Supabase
Future<void> saveAffirmation(String affirmationText) async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print("❌ Missing Supabase credentials in .env!");
    return;
  }

  try {
    final today = DateTime.now().toIso8601String();

    final response = await supabase.from('affirmations').insert({
      'affirmation': affirmationText,
      'date': today,
    }).select();

    print('✅ Affirmation saved to Supabase: $response');
  } catch (e) {
    print('❌ Error saving affirmation to Supabase: $e');
  }
}

// STEP 5️⃣: Run Both Together (1-click)
Future<void> runAffirmationAI() async {
  final affirmation = await generateAffirmation();

  if (affirmation != null) {
    await saveAffirmation(affirmation);
  } else {
    print('⚠️ No affirmation generated.');
  }
}
