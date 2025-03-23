import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationService {
  // ✅ REPLACE this URL with your actual Firebase Function URL!
  static const String functionUrl = 'https://sendpushnotification-ipsp2tle2q-uc.a.run.app';

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
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
      'fcmToken': fcmToken,
      'title': title,
      'body': body,
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
        print('❌ Failed to send notification via Firebase Function: ${response.body}');
      }
    } catch (e) {
      print('❌ Error calling Firebase Function: $e');
    }
  }
}
