import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PushNotificationService {
  static final String? _firebaseKey = dotenv.env['FCM_SERVER_KEY'];

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    if (_firebaseKey == null || _firebaseKey!.isEmpty) {
      print('❌ FCM Server Key is missing!');
      return;
    }

    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$_firebaseKey',
    };

    final payload = {
      'to': fcmToken, // This is the user's device token
      'notification': {
        'title': title,
        'body': body,
      },
      'priority': 'high',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent!');
      } else {
        print('❌ Failed to send push notification: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }
}
