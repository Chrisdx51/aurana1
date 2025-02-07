import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiUrl = "https://api.openai.com/v1/chat/completions"; // Example API
  static const String apiKey = "YOUR_OPENAI_API_KEY"; // ⚠️ Replace this with a real API key

  // 📌 Fetch AI Response
  static Future<String> getAIResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a spiritual guide providing insights."},
            {"role": "user", "content": userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"] ?? "No response received.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error connecting to AI service.";
    }
  }
}
