import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationService {
  // ✅ Make sure this URL matches your deployed Firebase Function
  static const String functionUrl = 'https://sendpushnotification-ipsp2tle2q-uc.a.run.app';

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data, // Optional: Add custom data
  }) async {
    if (fcmToken.isEmpty) {
      print('❌ FCM token is missing!');
      return;
    }

    print('📦 Sending push notification...');
    print('🔑 FCM Token: $fcmToken');
    print('📝 Title: $title');
    print('📨 Body: $body');

    final payload = {
      'token': fcmToken, // ✅ This must match your Firebase Function
      'title': title,
      'body': body,
      'data': data ?? {}, // Optional extra payload
    };

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully via Firebase Function!');
      } else {
        print('❌ Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('❌ Error calling Firebase Function: $e');
    }
  }

  // 🔥 Example shortcut for Soul Match Likes
  static Future<void> sendLikeNotification({
    required String fcmToken,
    required String likerName,
  }) async {
    await sendPushNotification(
      fcmToken: fcmToken,
      title: '✨ You’ve been liked!',
      body: '$likerName thinks you’re a great match! Swipe to find your connection.',
    );
  }
}
